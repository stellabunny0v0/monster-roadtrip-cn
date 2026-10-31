# Third-party notices

The installers use BepInEx 5.4.23.5 (MIT License) and their bundled dependencies.

The MonoMod.Utils 22.1.29.1 dependency is locally patched to backport the native
MonoAssembly layout correction from https://github.com/MonoMod/MonoMod/pull/330.
Only SetMonoCorlibInternal's calculated offset is corrected through the accompanying
MonsterRoadtripMonoCompat helper. Other method bodies and dependency versions remain
unchanged. Source and reproducible patch tooling are in compat/ and
tools/build-mono-compat.ps1. The MonoMod MIT notice is in compat/LICENSE-MonoMod.txt.

The Windows and macOS installers also include UnityDoorstop 4.5.0 (LGPL-2.1), HarmonyX 2.9.0
(MIT), and Mono.Cecil (MIT), as bundled with that BepInEx release. Their license
texts are retained in compat/LICENSE-*.txt and in the installer's licenses/ folder.
UnityDoorstop corresponding source: https://github.com/NeighTools/UnityDoorstop/tree/v4.5.0
The macOS run_bepinex.sh is minimally adjusted to select x86_64 and use an absolute
Doorstop library path. Reproducible substitutions are in tools/package_macos_installer.py.
HarmonyX source: https://github.com/BepInEx/HarmonyX/tree/v2.9.0
Mono.Cecil source: https://github.com/jbevain/cecil

- Project: https://github.com/BepInEx/BepInEx
- Release: https://github.com/BepInEx/BepInEx/releases/tag/v5.4.23.5

The project tooling uses UnityPy and ILSpy for development and does not distribute either
tool in the player-facing Mod folder.

