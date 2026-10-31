using System;
using System.Collections.Generic;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using System.Xml;
using BepInEx;
using BepInEx.Configuration;
using BepInEx.Logging;
using BeautifulGlitch;
using HarmonyLib;
using UnityEngine;
using UnityEngine.AddressableAssets;

namespace MonsterRoadtripChinese
{
    [BepInPlugin(PluginGuid, PluginName, PluginVersion)]
    public sealed class Plugin : BaseUnityPlugin
    {
        public const string PluginGuid = "cn.monsterroadtrip.localization";
        public const string PluginName = "Monster Roadtrip Chinese Localization";
        public const string PluginVersion = "0.3.7";

        internal static ManualLogSource Log;
        internal static string TranslationDirectory;
        internal static Font ChineseFont;

        private Harmony _harmony;
        private static bool _saveBackupCreated;
        private static ConfigEntry<string> _nameRecoveryRules;

        private void Awake()
        {
            Log = Logger;
            TranslationDirectory = Path.Combine(Path.GetDirectoryName(Info.Location), "Translation");
            TryCreateSaveSnapshot("plugin startup");
            _nameRecoveryRules = Config.Bind("NameRecovery", "Rules", "",
                "Optional local recovery for explicitly known lost names: PlayerA|pumpkin|???|original name. Separate rules with semicolons. Empty by default; valid custom names are never replaced.");
            _harmony = new Harmony(PluginGuid);

            Patch("BeautifulGlitch.CoreProgressManager", "Load", typeof(ProgressLoadBackupPatch));
            Patch("BeautifulGlitch.CoreCheckpointXmlSerializer", "SerializeCorePlayerData", typeof(PlayerNameWritePatch));
            Patch("BeautifulGlitch.CoreCheckpointXmlSerializer", "UnserializeCorePlayerData", typeof(PlayerNameReadPatch));
            Patch("BeautifulGlitch.Languages", "Initialize", typeof(LanguagesInitializePatch));
            Patch("BeautifulGlitch.CoreTextManager", "LoadMetatextsFile", typeof(MetatextPatch));
            Patch("BeautifulGlitch.CoreParser", "ReadLocalizedTextFile", typeof(EventTextPatch));
            Patch("Game.MainGameEventManager", "ConvertTextTags", typeof(StatFeedbackDisplayPatch));
            _harmony.CreateClassProcessor(typeof(StatWidgetNamesPatch)).Patch();
            Patch("BeautifulGlitch.LocalizedNGUIFont", "Refresh", typeof(LocalizedNGUIFontPatch));
            Patch("BeautifulGlitch.LocalizedTextFont", "Refresh", typeof(LocalizedTextFontPatch));

            Log.LogInfo("Non-invasive Chinese localization patches loaded from: " + TranslationDirectory);
        }

        private static void TryCreateSaveSnapshot(string reason)
        {
            if (_saveBackupCreated)
            {
                return;
            }

            try
            {
                bool macPlayer = Application.platform == RuntimePlatform.OSXPlayer;
                string[] candidates = SaveDataPaths.Candidates(Paths.GameRootPath, Application.dataPath, macPlayer);
                List<string> sourceFiles = new List<string>();
                List<string> sourceDirectories = new List<string>();
                foreach (string directory in candidates)
                {
                    if (!Directory.Exists(directory)) continue;
                    foreach (string sourceFile in Directory.GetFiles(directory, "*", SearchOption.TopDirectoryOnly))
                    {
                        string extension = Path.GetExtension(sourceFile);
                        string name = Path.GetFileName(sourceFile);
                        if (string.Equals(extension, ".xml", StringComparison.OrdinalIgnoreCase) ||
                            string.Equals(name, "steam_autocloud.vdf", StringComparison.OrdinalIgnoreCase))
                        {
                            if (!sourceDirectories.Contains(directory)) sourceDirectories.Add(directory);
                            sourceFiles.Add(sourceFile);
                        }
                    }
                }
                if (sourceFiles.Count == 0)
                {
                    Log.LogWarning("Save backup skipped because UserData contains no XML or Steam cloud marker files");
                    return;
                }

                string backupRoot = Path.Combine(Paths.BepInExRootPath, "save-backups", PluginGuid);
                string snapshotName = DateTime.UtcNow.ToString("yyyyMMdd-HHmmss-fff") + "Z";
                string snapshotDirectory = Path.Combine(backupRoot, snapshotName);
                if (Directory.Exists(snapshotDirectory))
                {
                    snapshotDirectory += "-" + Guid.NewGuid().ToString("N");
                }
                Directory.CreateDirectory(snapshotDirectory);

                StringBuilder manifest = new StringBuilder();
                manifest.AppendLine("Monster Roadtrip Chinese Localization save snapshot");
                manifest.AppendLine("Reason: " + reason);
                manifest.AppendLine("Created UTC: " + DateTime.UtcNow.ToString("o"));
                foreach (string directory in sourceDirectories) manifest.AppendLine("Source: " + directory);
                manifest.AppendLine();

                int copiedFileCount = 0;
                foreach (string sourceFile in sourceFiles)
                {
                    string name = Path.GetFileName(sourceFile);
                    string sourceDirectory = Path.GetDirectoryName(sourceFile);
                    string relativeName = sourceDirectories.Count == 1 ? name :
                        Path.Combine("source-" + sourceDirectories.IndexOf(sourceDirectory), name);
                    string destinationFile = Path.Combine(snapshotDirectory, relativeName);
                    Directory.CreateDirectory(Path.GetDirectoryName(destinationFile));
                    File.Copy(sourceFile, destinationFile, false);
                    // Unix Mono may not support setting file creation times.
                    // Snapshot data matters; leave Mac metadata to File.Copy.
                    if (!macPlayer)
                    {
                        File.SetCreationTimeUtc(destinationFile, File.GetCreationTimeUtc(sourceFile));
                        File.SetLastWriteTimeUtc(destinationFile, File.GetLastWriteTimeUtc(sourceFile));
                    }
                    manifest.AppendLine(GetSha256(destinationFile) + "  " + relativeName);
                    copiedFileCount++;
                }

                File.WriteAllText(
                    Path.Combine(snapshotDirectory, "SHA256SUMS.txt"),
                    manifest.ToString(),
                    new UTF8Encoding(false));
                _saveBackupCreated = true;
                Log.LogInfo(
                    "Save snapshot created before progress load: " + snapshotDirectory +
                    " (" + copiedFileCount + " file(s))");
            }
            catch (Exception exception)
            {
                Log.LogError("Could not create a pre-load save snapshot: " + exception);
            }
        }

        private static string GetSha256(string path)
        {
            using (SHA256 sha256 = SHA256.Create())
            using (FileStream stream = File.OpenRead(path))
            {
                return BitConverter.ToString(sha256.ComputeHash(stream)).Replace("-", string.Empty);
            }
        }

        private void Patch(string typeName, string methodName, Type patchType)
        {
            Type targetType = AccessTools.TypeByName(typeName);
            MethodInfo targetMethod = targetType == null ? null : AccessTools.Method(targetType, methodName);
            if (targetMethod == null)
            {
                Log.LogError("Could not find patch target: " + typeName + "." + methodName);
                return;
            }

            _harmony.CreateClassProcessor(patchType).Patch();
            Log.LogDebug("Patched " + typeName + "." + methodName);
        }

        private static bool TryReadTranslation(string fileName, out string contents)
        {
            string path = Path.Combine(TranslationDirectory, fileName);
            if (!File.Exists(path))
            {
                contents = null;
                return false;
            }

            contents = File.ReadAllText(path, System.Text.Encoding.UTF8);
            return true;
        }

        [HarmonyPatch]
        private static class ProgressLoadBackupPatch
        {
            private static MethodBase TargetMethod()
            {
                return AccessTools.Method(AccessTools.TypeByName("BeautifulGlitch.CoreProgressManager"), "Load");
            }

            private static void Prefix()
            {
                TryCreateSaveSnapshot("CoreProgressManager.Load");
            }
        }

        [HarmonyPatch]
        private static class LanguagesInitializePatch
        {
            private static MethodBase TargetMethod()
            {
                return AccessTools.Method(AccessTools.TypeByName("BeautifulGlitch.Languages"), "Initialize");
            }

            private static void Postfix()
            {
                try
                {
                    LanguageProfile chineseProfile =
                        Addressables.LoadAssetAsync<LanguageProfile>("language_schinese").WaitForCompletion();
                    if (chineseProfile != null && chineseProfile.font != null)
                    {
                        ChineseFont = chineseProfile.font;
                        Log.LogInfo("Chinese font is ready: " + ChineseFont.name);
                    }
                    else
                    {
                        Log.LogError("Chinese font is unavailable; using the current game font");
                    }
                }
                catch (Exception exception)
                {
                    Log.LogError("Could not load the Chinese font profile: " + exception);
                }
            }
        }

        [HarmonyPatch]
        private static class MetatextPatch
        {
            private static MethodBase TargetMethod()
            {
                return AccessTools.Method(AccessTools.TypeByName("BeautifulGlitch.CoreTextManager"), "LoadMetatextsFile");
            }

            private static bool Prefix(ref string aFileContents, ref bool __result)
            {
                if (!TryReadTranslation("schinese_metatexts.json", out aFileContents))
                {
                    Log.LogError("Missing schinese_metatexts.json; using the original English file");
                    return true;
                }

                __result = true;
                Log.LogInfo("Loaded Chinese metatexts over the English language slot");
                return false;
            }
        }

        [HarmonyPatch]
        private static class EventTextPatch
        {
            private static MethodBase TargetMethod()
            {
                return AccessTools.Method(AccessTools.TypeByName("BeautifulGlitch.CoreParser"), "ReadLocalizedTextFile");
            }

            private static bool Prefix(
                string aFilename,
                string aLangPrefix,
                ref string aOutputData,
                ref bool __result)
            {
                if (!string.Equals(aLangPrefix, "english", StringComparison.Ordinal) &&
                    !string.Equals(aLangPrefix, "schinese", StringComparison.Ordinal))
                {
                    return true;
                }

                if (!TryReadTranslation("schinese_" + aFilename + ".txt", out aOutputData))
                {
                    Log.LogWarning("Missing event translation; using the original game asset: " + aFilename);
                    return true;
                }

                string verbManifest;
                if (TryReadTranslation("schinese_verb_overrides.tsv", out verbManifest))
                {
                    try
                    {
                        aOutputData = RuntimeVerbTranslations.Apply(aFilename, aOutputData, verbManifest);
                    }
                    catch (Exception exception)
                    {
                        Log.LogError("Chinese verb adaptation failed; keeping original translated table: " + exception);
                    }
                }
                else
                {
                    Log.LogWarning("Missing schinese_verb_overrides.tsv; English verb tags will use game defaults");
                }

                __result = true;
                return false;
            }
        }

        [HarmonyPatch]
        private static class PlayerNameWritePatch
        {
            private static MethodBase TargetMethod()
            {
                return AccessTools.Method(typeof(CoreCheckpointXmlSerializer), "SerializeCorePlayerData");
            }

            private static IEnumerable<CodeInstruction> Transpiler(IEnumerable<CodeInstruction> instructions)
            {
                MethodInfo replacement = typeof(NameTextPersistence).GetMethod("WriteElementString",
                    BindingFlags.Static | BindingFlags.NonPublic);
                if (replacement == null) throw new MissingMethodException("Name XML writer helper is missing.");
                foreach (CodeInstruction instruction in instructions)
                {
                    MethodInfo method = instruction.operand as MethodInfo;
                    if ((instruction.opcode == System.Reflection.Emit.OpCodes.Call || instruction.opcode == System.Reflection.Emit.OpCodes.Callvirt) &&
                        method != null && method.Name == "WriteElementString" &&
                        typeof(XmlWriter).IsAssignableFrom(method.DeclaringType))
                    {
                        ParameterInfo[] parameters = method.GetParameters();
                        if (parameters.Length == 2 && parameters[0].ParameterType == typeof(string) &&
                            parameters[1].ParameterType == typeof(string))
                        {
                            instruction.opcode = System.Reflection.Emit.OpCodes.Call;
                            instruction.operand = replacement;
                        }
                    }
                    yield return instruction;
                }
            }
        }

        [HarmonyPatch]
        private static class PlayerNameReadPatch
        {
            private static readonly FieldInfo NameField = AccessTools.Field(typeof(CorePlayerData), "name");
            private static readonly FieldInfo PlayerField = AccessTools.Field(typeof(CorePlayerData), "playerId");
            private static readonly FieldInfo ProfileField = AccessTools.Field(typeof(CorePlayerData), "pcProfile");

            private static MethodBase TargetMethod()
            {
                return AccessTools.Method(typeof(CoreCheckpointXmlSerializer), "UnserializeCorePlayerData");
            }

            private static void Postfix(CorePlayerData aResult)
            {
                if (aResult == null || _nameRecoveryRules == null) return;
                PcProfile profile = ProfileField.GetValue(aResult) as PcProfile;
                if (profile == null) return;
                string before = NameField.GetValue(aResult) as string;
                string after = NameTextPersistence.Recover(_nameRecoveryRules.Value,
                    PlayerField.GetValue(aResult).ToString(), profile.id, before);
                if (!string.Equals(before, after, StringComparison.Ordinal))
                {
                    NameField.SetValue(aResult, after);
                    Log.LogInfo("Recovered an explicitly configured player name in memory; existing save files were not rewritten.");
                }
            }
        }

        [HarmonyPatch]
        private static class StatFeedbackDisplayPatch
        {
            private static MethodBase TargetMethod()
            {
                return AccessTools.Method(AccessTools.TypeByName("Game.MainGameEventManager"), "ConvertTextTags");
            }

            private static void Postfix(ref string __result)
            {
                __result = StatDisplayTranslations.FinishedFeedback(__result);
            }
        }

        [HarmonyPatch]
        private static class StatWidgetNamesPatch
        {
            private static IEnumerable<MethodBase> TargetMethods()
            {
                yield return AccessTools.Method(typeof(Game.StatWidget), "Initialize",
                    new[] { typeof(BeautifulGlitchConfig.StatType) });
                yield return AccessTools.Method(typeof(Game.StatWidget), "Initialize",
                    new[] { typeof(BeautifulGlitchConfig.StatType), typeof(UIWidget), typeof(float), typeof(float) });
            }

            private static void Prefix(Game.StatWidget __instance)
            {
                // Set the font before the game clones the auxiliary name labels.
                if (ChineseFont != null && __instance.nameLabel != null)
                    __instance.nameLabel.SetTrueTypeFont(ChineseFont);
            }

            private static void Postfix(Game.StatWidget __instance)
            {
                if (__instance.nameLabel != null)
                    __instance.nameLabel.text = StatDisplayTranslations.Name(__instance.type.ToString());
            }
        }

        [HarmonyPatch]
        private static class LocalizedNGUIFontPatch
        {
            private static MethodBase TargetMethod()
            {
                return AccessTools.Method(AccessTools.TypeByName("BeautifulGlitch.LocalizedNGUIFont"), "Refresh");
            }

            private static void Postfix(LocalizedNGUIFont __instance)
            {
                if (ChineseFont != null && __instance.label != null)
                {
                    __instance.label.SetTrueTypeFont(ChineseFont);
                }
            }
        }

        [HarmonyPatch]
        private static class LocalizedTextFontPatch
        {
            private static MethodBase TargetMethod()
            {
                return AccessTools.Method(AccessTools.TypeByName("BeautifulGlitch.LocalizedTextFont"), "Refresh");
            }

            private static void Postfix(LocalizedTextFont __instance)
            {
                if (ChineseFont != null && __instance.label != null)
                {
                    __instance.label.font = ChineseFont;
                }
            }
        }
    }
}
