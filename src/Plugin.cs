using System;
using System.IO;
using System.Reflection;
using System.Security.Cryptography;
using System.Text;
using BepInEx;
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
        public const string PluginVersion = "0.3.2";

        internal static ManualLogSource Log;
        internal static string TranslationDirectory;
        internal static Font ChineseFont;

        private Harmony _harmony;
        private static bool _saveBackupCreated;

        private void Awake()
        {
            Log = Logger;
            TranslationDirectory = Path.Combine(Path.GetDirectoryName(Info.Location), "Translation");
            TryCreateSaveSnapshot("plugin startup");
            _harmony = new Harmony(PluginGuid);

            Patch("BeautifulGlitch.CoreProgressManager", "Load", typeof(ProgressLoadBackupPatch));
            Patch("BeautifulGlitch.Languages", "Initialize", typeof(LanguagesInitializePatch));
            Patch("BeautifulGlitch.CoreTextManager", "LoadMetatextsFile", typeof(MetatextPatch));
            Patch("BeautifulGlitch.CoreParser", "ReadLocalizedTextFile", typeof(EventTextPatch));
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
                string userDataDirectory = Path.Combine(Paths.GameRootPath, "UserData");
                if (!Directory.Exists(userDataDirectory))
                {
                    Log.LogWarning("Save backup skipped because UserData was not found: " + userDataDirectory);
                    return;
                }

                string[] sourceFiles = Directory.GetFiles(userDataDirectory, "*", SearchOption.TopDirectoryOnly);
                int eligibleFileCount = 0;
                foreach (string sourceFile in sourceFiles)
                {
                    string extension = Path.GetExtension(sourceFile);
                    string name = Path.GetFileName(sourceFile);
                    if (string.Equals(extension, ".xml", StringComparison.OrdinalIgnoreCase) ||
                        string.Equals(name, "steam_autocloud.vdf", StringComparison.OrdinalIgnoreCase))
                    {
                        eligibleFileCount++;
                    }
                }
                if (eligibleFileCount == 0)
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
                manifest.AppendLine("Source: " + userDataDirectory);
                manifest.AppendLine();

                int copiedFileCount = 0;
                foreach (string sourceFile in sourceFiles)
                {
                    string extension = Path.GetExtension(sourceFile);
                    string name = Path.GetFileName(sourceFile);
                    if (!string.Equals(extension, ".xml", StringComparison.OrdinalIgnoreCase) &&
                        !string.Equals(name, "steam_autocloud.vdf", StringComparison.OrdinalIgnoreCase))
                    {
                        continue;
                    }

                    string destinationFile = Path.Combine(snapshotDirectory, name);
                    File.Copy(sourceFile, destinationFile, false);
                    File.SetCreationTimeUtc(destinationFile, File.GetCreationTimeUtc(sourceFile));
                    File.SetLastWriteTimeUtc(destinationFile, File.GetLastWriteTimeUtc(sourceFile));
                    manifest.AppendLine(GetSha256(destinationFile) + "  " + name);
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

                __result = true;
                return false;
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
