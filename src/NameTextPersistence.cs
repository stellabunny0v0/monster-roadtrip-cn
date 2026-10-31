using System;
using System.Xml;

namespace MonsterRoadtripChinese
{
    internal static class NameTextPersistence
    {
        // The original save writer uses ASCIIEncoding, which replaces Chinese
        // with '?'. Numeric XML character references remain ASCII on disk and
        // round-trip through the game's existing XML reader and encryption.
        internal static void WriteElementString(XmlWriter writer, string localName, string value)
        {
            if (localName != "Name" || string.IsNullOrEmpty(value))
            {
                writer.WriteElementString(localName, value);
                return;
            }
            writer.WriteStartElement(localName);
            foreach (char character in value)
            {
                if (char.IsSurrogate(character))
                {
                    // Surrogate pairs are written together below.
                    WriteNameWithSurrogates(writer, value);
                    writer.WriteEndElement();
                    return;
                }
            }
            foreach (char character in value)
            {
                if (character > 127) writer.WriteCharEntity(character);
                else writer.WriteString(character.ToString());
            }
            writer.WriteEndElement();
        }

        private static void WriteNameWithSurrogates(XmlWriter writer, string value)
        {
            for (int i = 0; i < value.Length; i++)
            {
                char character = value[i];
                if (char.IsHighSurrogate(character) && i + 1 < value.Length && char.IsLowSurrogate(value[i + 1]))
                {
                    writer.WriteSurrogateCharEntity(value[i + 1], character);
                    i++;
                }
                else if (character > 127) writer.WriteCharEntity(character);
                else writer.WriteString(character.ToString());
            }
        }

        internal static string Recover(string rules, string playerId, string profileId, string currentName)
        {
            if (string.IsNullOrEmpty(rules) || string.IsNullOrEmpty(currentName)) return currentName;
            foreach (char character in currentName)
                if (character != '?') return currentName;
            string replacement = null;
            foreach (string rule in rules.Split(';'))
            {
                string[] fields = rule.Split('|');
                if (fields.Length != 4 || fields[0] != playerId || fields[1] != profileId || fields[2] != currentName)
                    continue;
                string proposed = fields[3];
                if (string.IsNullOrEmpty(proposed) || proposed.IndexOfAny(new[] { '\r', '\n', '\t' }) >= 0)
                    return currentName;
                try { XmlConvert.VerifyXmlChars(proposed); }
                catch (XmlException) { return currentName; }
                if (replacement != null && replacement != proposed) return currentName;
                replacement = proposed;
            }
            return replacement ?? currentName;
        }
    }
}
