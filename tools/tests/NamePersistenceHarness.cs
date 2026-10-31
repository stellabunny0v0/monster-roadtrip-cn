using System;
using System.IO;
using System.Text;
using System.Xml;
using MonsterRoadtripChinese;

public static class NamePersistenceHarness
{
    private static void Check(bool value, string message)
    {
        if (!value) throw new Exception(message);
    }

    private static byte[] Write(string name, bool patched)
    {
        using (MemoryStream stream = new MemoryStream())
        {
            using (XmlTextWriter writer = new XmlTextWriter(stream, new ASCIIEncoding()))
            {
                writer.WriteStartElement("CorePlayerData");
                writer.WriteElementString("Player", "PlayerA");
                if (patched) NameTextPersistence.WriteElementString(writer, "Name", name);
                else writer.WriteElementString("Name", name);
                NameTextPersistence.WriteElementString(writer, "PcProfile", "pumpkin");
                writer.WriteStartElement("Stats");
                writer.WriteElementString("Hype", "18");
                writer.WriteElementString("Stamina", "13");
                writer.WriteEndElement();
                writer.WriteEndElement();
                writer.Flush();
                return stream.ToArray();
            }
        }
    }

    public static string Run()
    {
        string[] names = { "杰斐琳", "杰奎琳", "Amira", "猫 & <友> \"x\"", "玩家🎃", "中文??", "Zoë" };
        XmlDocument old = new XmlDocument();
        old.LoadXml(Encoding.ASCII.GetString(Write(names[0], false)));
        Check(old.SelectSingleNode("//Name").InnerText == "???", "Original ASCII failure not reproduced");
        foreach (string name in names)
        {
            byte[] bytes = Write(name, true);
            foreach (byte value in bytes) Check(value < 128, "Save requires non-ASCII bytes");
            XmlDocument restored = new XmlDocument();
            using (StreamReader reader = new StreamReader(new MemoryStream(bytes), Encoding.ASCII)) restored.Load(reader);
            Check(restored.SelectSingleNode("//Name").InnerText == name, "Name failed ASCII/XML round-trip");
            Check(restored.SelectSingleNode("//Player").InnerText == "PlayerA", "Player ID changed");
            Check(restored.SelectSingleNode("//PcProfile").InnerText == "pumpkin", "Character ID changed");
            Check(restored.SelectSingleNode("//Hype").InnerText == "18" && restored.SelectSingleNode("//Stamina").InnerText == "13", "Stats changed");
            // CryptoUtils encrypts/decrypts InnerXml as UTF-8. Numeric entities
            // may decode during that stage and must still survive XML parsing.
            string decrypted = Encoding.UTF8.GetString(Encoding.UTF8.GetBytes(restored.DocumentElement.InnerXml));
            XmlDocument encryptedRoundTrip = new XmlDocument();
            encryptedRoundTrip.LoadXml("<CorePlayerData>" + decrypted + "</CorePlayerData>");
            Check(encryptedRoundTrip.SelectSingleNode("//Name").InnerText == name, "Encrypted XML payload round-trip failed");
        }
        Check(Encoding.ASCII.GetString(Write("Amira", true)) == Encoding.ASCII.GetString(Write("Amira", false)), "Legacy ASCII format changed");
        string rules = "PlayerA|pumpkin|???|杰斐琳";
        Check(NameTextPersistence.Recover(rules, "PlayerA", "pumpkin", "???") == "杰斐琳", "Explicit recovery failed");
        foreach (string valid in new[] { "杰奎琳", "我的主角", "Jacqueline", "A?B" })
            Check(NameTextPersistence.Recover(rules, "PlayerA", "pumpkin", valid) == valid, "Custom name replaced");
        Check(NameTextPersistence.Recover("", "PlayerA", "pumpkin", "???") == "???", "Unconfigured name guessed");
        Check(NameTextPersistence.Recover(rules, "PlayerB", "pumpkin", "???") == "???", "Other player changed");
        Check(NameTextPersistence.Recover(rules, "PlayerA", "red", "???") == "???", "Other character changed");
        Check(NameTextPersistence.Recover(rules, "PlayerA", "pumpkin", "????") == "????", "Other lost name guessed");
        Check(NameTextPersistence.Recover(rules + ";PlayerA|pumpkin|???|别的名字", "PlayerA", "pumpkin", "???") == "???", "Ambiguous recovery guessed");
        return "PASS: original ASCII regression, 7 Unicode/ASCII names, XML and UTF-8 payload round-trips, unchanged IDs/stats, opt-in exact recovery and custom-name guards";
    }
}
