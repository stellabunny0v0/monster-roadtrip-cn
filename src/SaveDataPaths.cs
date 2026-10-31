using System;
using System.Collections.Generic;
using System.IO;

namespace MonsterRoadtripChinese
{
    internal static class SaveDataPaths
    {
        internal static string[] Candidates(string gameRoot, string applicationDataPath, bool macPlayer)
        {
            List<string> roots = new List<string>();
            if (macPlayer)
            {
                // Matches the game's XmlSerializer.GetSavedFilesPath and its
                // legacy Mac fallback. These are backup sources, never targets.
                Add(roots, Path.Combine(applicationDataPath, "..", "UserData"), StringComparer.Ordinal);
                Add(roots, Path.Combine(applicationDataPath, "..", "..", "UserData"), StringComparer.Ordinal);
            }
            Add(roots, Path.Combine(gameRoot, "UserData"), macPlayer ? StringComparer.Ordinal : StringComparer.OrdinalIgnoreCase);
            return roots.ToArray();
        }

        private static void Add(List<string> roots, string path, StringComparer comparer)
        {
            string fullPath = Path.GetFullPath(path);
            foreach (string existing in roots)
                if (comparer.Equals(existing, fullPath)) return;
            roots.Add(fullPath);
        }
    }
}
