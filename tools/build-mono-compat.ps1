param(
    [string]$InputDll = '',
    [string]$OutputDirectory = ''
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
if (-not $InputDll) { $InputDll = Join-Path $repoRoot '.tools\bepinex-x86\BepInEx\core\MonoMod.Utils.dll' }
if (-not $OutputDirectory) { $OutputDirectory = Join-Path $repoRoot 'build\mono-compat' }
$expectedHash = '9D1495F147AC93C4F81F84538C1A326E8F8A6AEFC78D6289D798F3CE1162C5E9'
if ((Get-FileHash -LiteralPath $InputDll -Algorithm SHA256).Hash -ne $expectedHash) {
    throw 'Unsupported MonoMod.Utils input. This backport only accepts the unmodified BepInEx 5.4.23.5 dependency.'
}
$helperPath = Join-Path $repoRoot 'compat\bin\Release\MonsterRoadtripMonoCompat.dll'
if (-not (Test-Path -LiteralPath $helperPath)) { throw 'Build compat/MonsterRoadtripMonoCompat.csproj first.' }
[void][Reflection.Assembly]::LoadFrom((Join-Path $repoRoot '.tools\bepinex-x86\BepInEx\core\Mono.Cecil.dll'))
$original = [Mono.Cecil.AssemblyDefinition]::ReadAssembly([IO.Path]::GetFullPath($InputDll))
$helper = [Mono.Cecil.AssemblyDefinition]::ReadAssembly($helperPath)
try {
    $type = $original.MainModule.Types | Where-Object FullName -eq 'MonoMod.Utils.Extensions'
    $method = $type.Methods | Where-Object Name -eq 'SetMonoCorlibInternal'
    if (-not $method -or $method.Parameters.Count -ne 2) { throw 'Unexpected native flag writer signature.' }
    $stores = @($method.Body.Instructions | Where-Object {
        $_.OpCode.Code -eq 'Stloc_S' -and $_.Operand.VariableType.FullName -eq 'System.Int32'
    })
    if ($stores.Count -ne 1) { throw 'Unexpected native offset calculation.' }
    $helperMethod = ($helper.MainModule.Types | Where-Object FullName -eq 'MonsterRoadtripMonoCompat.MonoCorlibLayout').Methods |
        Where-Object Name -eq 'CorrectOffset'
    if ($helperMethod.FullName -ne 'System.Int32 MonsterRoadtripMonoCompat.MonoCorlibLayout::CorrectOffset(System.Int32)') {throw 'Unexpected correction signature.'}
    # Use the original module's Int32 scope, retaining its existing corlib reference.
    $helperReference = [Mono.Cecil.AssemblyNameReference]::new($helper.Name.Name,$helper.Name.Version)
    $original.MainModule.AssemblyReferences.Add($helperReference)
    $helperType = [Mono.Cecil.TypeReference]::new('MonsterRoadtripMonoCompat','MonoCorlibLayout',$original.MainModule,$helperReference)
    $correction = [Mono.Cecil.MethodReference]::new('CorrectOffset',$original.MainModule.TypeSystem.Int32,$helperType)
    $correction.Parameters.Add([Mono.Cecil.ParameterDefinition]::new($original.MainModule.TypeSystem.Int32))
    $call = [Mono.Cecil.Cil.Instruction]::Create([Mono.Cecil.Cil.OpCodes]::Call, $correction)
    $originalCount = $method.Body.Instructions.Count
    $method.Body.GetILProcessor().InsertBefore($stores[0], $call)
    New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
    $outputPath = Join-Path $OutputDirectory 'MonoMod.Utils.dll'
    if ([IO.Path]::GetFullPath($outputPath) -eq [IO.Path]::GetFullPath($InputDll)) { throw 'Refusing to overwrite the original dependency.' }
    $original.Write($outputPath)
    Copy-Item -LiteralPath $helperPath -Destination (Join-Path $OutputDirectory 'MonsterRoadtripMonoCompat.dll') -Force
    $manifest = [ordered]@{
        purpose = 'Backport MonoMod #330 native MonoAssembly layout correction'
        originalSha256 = $expectedHash
        patchedSha256 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
        helperSha256 = (Get-FileHash -LiteralPath (Join-Path $OutputDirectory 'MonsterRoadtripMonoCompat.dll') -Algorithm SHA256).Hash
        changedMethod = $method.FullName
        addedInstructions = $method.Body.Instructions.Count - $originalCount
        upstream = 'https://github.com/MonoMod/MonoMod/pull/330'
        unityLayout = 'https://github.com/Unity-Technologies/mono/blob/unity-2021.3-mbe/mono/metadata/metadata-internals.h'
    }
    $manifest | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputDirectory 'compatibility-manifest.json') -Encoding utf8
    $manifest | ConvertTo-Json
}
finally {
    $helper.Dispose()
    $original.Dispose()
}
