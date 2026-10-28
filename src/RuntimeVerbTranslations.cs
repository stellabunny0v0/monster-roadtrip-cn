using System;
using System.Collections.Generic;
using System.IO;

namespace MonsterRoadtripChinese
{
    // Applied only to successfully loaded Chinese event files. Exact row and
    // text matches prevent stale overrides from changing unrelated dialogue.
    internal static class RuntimeVerbTranslations
    {
        internal static string Apply(string filename, string contents, string manifest)
        {
            string prefix = "english_" + filename + ":L";
            string[] lines = contents.Split('\n');
            HashSet<int> seen = new HashSet<int>();
            foreach (string manifestLine in manifest.Split('\n'))
            {
                if (manifestLine.TrimEnd('\r').Length == 0) continue;
                string[] entry = manifestLine.TrimEnd('\r').Split('\t');
                if (entry.Length != 3) throw new InvalidDataException("Invalid Chinese verb manifest record");
                if (!entry[0].StartsWith(prefix, StringComparison.Ordinal)) continue;
                int lineNumber;
                if (!int.TryParse(entry[0].Substring(prefix.Length), out lineNumber) ||
                    lineNumber < 1 || lineNumber > lines.Length || !seen.Add(lineNumber))
                    throw new InvalidDataException("Invalid Chinese verb row: " + entry[0]);
                bool hasCr = lines[lineNumber - 1].EndsWith("\r", StringComparison.Ordinal);
                string[] fields = lines[lineNumber - 1].TrimEnd('\r').Split('\t');
                if (fields.Length < 4 || !string.Equals(fields[3], entry[1], StringComparison.Ordinal))
                    throw new InvalidDataException("Stale Chinese verb row: " + entry[0]);
                fields[3] = entry[2];
                lines[lineNumber - 1] = string.Join("\t", fields) + (hasCr ? "\r" : "");
            }
            return string.Join("\n", lines);
        }
    }
}
