using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;
using MonsterRoadtripChinese;

public static class StatContractsHarness
{
    // Exact patterns from RegexUtils, used by the original ProcessStatPatterns.
    private static readonly Regex AnyStat = new Regex(@"(\+|\-)N?[\d]+[\s]*[A-Z\s]*[A-Z]+(\W|$)");
    private static readonly Regex Digits = new Regex(@"[\d]+");
    private static readonly Regex Words = new Regex(@"[A-Z\s]*[A-Z]+");
    private enum Stat { Hype, Magic, Mind, Money, Soul, Stamina }

    private static List<string> Cues(string text)
    {
        List<string> cues = new List<string>();
        foreach (Match match in AnyStat.Matches(text))
        {
            string value = match.Value;
            bool factor = value[1] == 'N';
            Match digit = Digits.Match(value);
            uint amount;
            Stat stat;
            string name = Words.Match(value.Substring(digit.Length + (factor ? 2 : 1))).Value.Trim();
            if (uint.TryParse(digit.Value, out amount) && Enum.TryParse<Stat>(name, true, out stat))
                cues.Add(value[0] + (factor ? "N" : "") + amount + ":" + stat);
        }
        return cues;
    }

    private static void Check(bool value, string message)
    {
        if (!value) throw new Exception(message);
    }

    public static string Run(string sourceDirectory, string builtDirectory)
    {
        int count = 0, rows = 0, missions = 0;
        foreach (string path in Directory.GetFiles(sourceDirectory, "english_events_*.txt"))
        {
            string[] original = File.ReadAllLines(path);
            string[] built = File.ReadAllLines(Path.Combine(builtDirectory, Path.GetFileName(path).Replace("english_", "schinese_")));
            Check(original.Length == built.Length, "Line count changed");
            for (int i = 0; i < original.Length; i++)
            {
                string[] a = original[i].Split('\t'), b = built[i].Split('\t');
                Check(a.Length == b.Length, "Column count changed");
                for (int j = 0; j < a.Length; j++)
                    if (j != 3) Check(a[j] == b[j], "Control column changed");
                if (a.Length <= 3) continue;
                List<string> expected = Cues(a[3]), actual = Cues(b[3]);
                Check(string.Join("|", expected.ToArray()) == string.Join("|", actual.ToArray()),
                    "Calculation cues changed: " + Path.GetFileName(path) + ":" + (i + 1));
                count += expected.Count;
                if (expected.Count > 0) rows++;
                int beforeMission = a[3].Split(new[] { "+XX PRANK DOLLARZ" }, StringSplitOptions.None).Length - 1;
                int afterMission = b[3].Split(new[] { "+XX PRANK DOLLARZ" }, StringSplitOptions.None).Length - 1;
                Check(beforeMission == afterMission, "Prank Dollarz reward changed");
                missions += beforeMission;
            }
        }
        // Reproduce the old failure and exercise the game's factor/enum parsing.
        Check(Cues("获得 +N2 热度。").Count == 0, "Old regression was not reproduced");
        Check(Cues("+N2 MIND的奖励").Count == 0, "Chinese word boundary not reproduced");
        Check(Cues("+N2 MIND 的奖励").Count == 1, "Chinese boundary separator failed");
        string[] cues = Cues("+N2 HYPE, -N2 STAMINA.").ToArray();
        Check(cues.Length == 2 && cues[0] == "+N2:Hype" && cues[1] == "-N2:Stamina", "Gain/loss or scaling flag changed");
        // Verify display-only conversion, after the original calculation returns.
        Check(StatDisplayTranslations.FinishedFeedback("获得 [abcdef]+5 HYPE[-]，损失 [ABCDEFff]-3 STAMINA[-]。") ==
            "获得 [abcdef]+5 热度[-]，损失 [ABCDEFff]-3 体力[-]。", "Finished feedback localization failed");
        Check(StatDisplayTranslations.FinishedFeedback("[abcdef]+15 PRANK DOLLARZ[-]") == "[abcdef]+15 恶作剧币[-]", "Mission display failed");
        Check(StatDisplayTranslations.FinishedFeedback("+N2 HYPE and +2 MIND") == "+N2 HYPE and +2 MIND", "Unprocessed cues were localized too early");
        Check(StatDisplayTranslations.FinishedFeedback("[abcdef]+5 CUSTOM STAT[-]") == "[abcdef]+5 CUSTOM STAT[-]", "Custom stat name changed");
        foreach (string name in Enum.GetNames(typeof(Stat)))
            Check(StatDisplayTranslations.Name(name) != name, "Missing HUD name: " + name);
        return "PASS: " + count + " stat cues in " + rows + " rows, " + missions + " mission rewards; original .NET regex/enum semantics, boundaries, control fields and Chinese display";
    }
}
