using System;
using System.Text.RegularExpressions;

namespace MonsterRoadtripChinese
{
    internal static class StatDisplayTranslations
    {
        // Only finished, colored numeric feedback is localized. Raw N-factor
        // cues must reach the original game calculation unchanged.
        private static readonly Regex Feedback = new Regex(
            @"(\[(?:[0-9A-Fa-f]{6}|[0-9A-Fa-f]{8})\][+-]\d+\s+)(HYPE|MAGIC|MIND|MONEY|SOUL|STAMINA|PRANK DOLLARZ)(\[-\])(?: (?=[\u3400-\u9fff]))?");

        internal static string Name(string name)
        {
            switch (name.ToUpperInvariant())
            {
                case "HYPE": return "热度";
                case "MAGIC": return "魔力";
                case "MIND": return "头脑";
                case "MONEY": return "金钱";
                case "SOUL": return "灵魂";
                case "STAMINA": return "体力";
                case "PRANK DOLLARZ": return "恶作剧币";
                default: return name;
            }
        }

        internal static string FinishedFeedback(string text)
        {
            if (string.IsNullOrEmpty(text)) return text;
            return Feedback.Replace(text, delegate(Match match)
            {
                return match.Groups[1].Value + Name(match.Groups[2].Value) + match.Groups[3].Value;
            });
        }
    }
}
