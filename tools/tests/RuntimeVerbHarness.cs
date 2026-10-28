using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using MonsterRoadtripChinese;

public static class RuntimeVerbHarness
{
    private static void Check(bool value, string message)
    {
        if (!value) throw new Exception(message);
    }

    public static string Run(string directory)
    {
        string manifest = File.ReadAllText(Path.Combine(directory, "schinese_verb_overrides.tsv"));
        Dictionary<string, string[]> entries = new Dictionary<string, string[]>();
        foreach (string line in manifest.Split('\n'))
        {
            if (line.TrimEnd('\r').Length == 0) continue;
            string[] parts = line.TrimEnd('\r').Split('\t');
            entries.Add(parts[0], parts);
        }
        int adapted = 0, files = 0;
        foreach (string path in Directory.GetFiles(directory, "schinese_events_*.txt"))
        {
            string filename = Path.GetFileNameWithoutExtension(path).Substring("schinese_".Length);
            string before = File.ReadAllText(path);
            string after = RuntimeVerbTranslations.Apply(filename, before, manifest);
            string[] oldLines = before.Split('\n'), newLines = after.Split('\n');
            Check(oldLines.Length == newLines.Length, "Line count changed");
            for (int i = 0; i < oldLines.Length; i++)
            {
                string key = "english_" + filename + ":L" + (i + 1);
                if (!entries.ContainsKey(key))
                {
                    Check(oldLines[i] == newLines[i], "Unreviewed line changed: " + key);
                    continue;
                }
                string[] oldFields = oldLines[i].TrimEnd('\r').Split('\t');
                string[] newFields = newLines[i].TrimEnd('\r').Split('\t');
                Check(oldFields.Length == newFields.Length, "Column count changed: " + key);
                for (int j = 0; j < oldFields.Length; j++)
                    Check(j == 3 ? newFields[j] == entries[key][2] : oldFields[j] == newFields[j], "Field mismatch: " + key);
                Check(!Regex.IsMatch(newFields[3], "%VERB(?:CAPS)?_"), "Unresolved English verb: " + key);
                Check(oldLines[i].EndsWith("\r") == newLines[i].EndsWith("\r"), "Line ending changed");
                adapted++;
            }
            // The same consumer must work with LF as well as CRLF files.
            Check(RuntimeVerbTranslations.Apply(filename, before.Replace("\r\n", "\n"), manifest) == after.Replace("\r\n", "\n"), "LF/CRLF mismatch");
            files++;
        }
        Check(adapted == entries.Count, "Not all manifest rows were exercised");
        string sample = "a\tb\tc\t%HESHE%%VERB_IS_ARE%好人\tsfx\r\n";
        string good = "english_events_test:L1\t%HESHE%%VERB_IS_ARE%好人\t%HESHE%是好人\n";
        Check(RuntimeVerbTranslations.Apply("events_other", sample, good) == sample, "Wrong file changed");
        Check(RuntimeVerbTranslations.Apply("events_test", sample, "") == sample, "Empty manifest changed text");
        foreach (string bad in new string[] { good.Replace("L1", "L2"), good.Replace("好人\t", "坏人\t"), good + good, "invalid" })
        {
            bool rejected = false;
            try { RuntimeVerbTranslations.Apply("events_test", sample, bad); }
            catch (InvalidDataException) { rejected = true; }
            Check(rejected, "Invalid/stale manifest accepted");
        }
        return "PASS: " + adapted + " reviewed rows across " + files + " event files; control fields, unrelated rows, LF/CRLF, stale/invalid/duplicate guards";
    }
}
