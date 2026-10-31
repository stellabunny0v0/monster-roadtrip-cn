using System;
using System.Reflection;

namespace MonsterRoadtripMonoCompat
{
    /// <summary>
    /// Backport of the MonoAssembly layout correction in MonoMod/MonoMod#330.
    /// Only computes the offset; MonoMod retains its original cache and write logic.
    /// https://github.com/MonoMod/MonoMod/pull/330
    /// </summary>
    public static class MonoCorlibLayout
    {
        private static class DetectedLayout
        {
            internal static readonly int Offset = CalculateOffset();
        }

        public static int CorrectOffset(int legacyOffset)
        {
            return DetectedLayout.Offset;
        }

        private static int CalculateOffset()
        {
            if (Type.GetType("Mono.Runtime") == null)
                throw new InvalidOperationException("Mono layout correction requires Mono.");

#pragma warning disable 618
            bool hasArch = new AssemblyName("Dummy, ProcessorArchitecture=MSIL").ProcessorArchitecture
                == ProcessorArchitecture.MSIL;
#pragma warning restore 618
            bool coreBcl = typeof(object).Assembly.GetName().Name == "System.Private.CoreLib";
            bool hasNameFlags = hasArch && DetectNameFlags();
            return ComputeOffset(IntPtr.Size, coreBcl, hasArch, hasNameFlags);
        }

        // Kept separate so the x86/x64 and old/new Mono layouts can be tested
        // without loading a game or writing native memory.
        public static int ComputeOffset(int pointerSize, bool coreBcl, bool hasArch, bool hasNameFlags)
        {
            if (pointerSize != 4 && pointerSize != 8)
                throw new ArgumentOutOfRangeException("pointerSize");
            int versionFieldSize = coreBcl ? 4 : 2;
            int nameSize = 4 * pointerSize + 20 + 4 + 4 + 4 + 4 * versionFieldSize;
            if (hasArch) nameSize += versionFieldSize;
            if (hasNameFlags) nameSize += 3;
            nameSize = (nameSize + pointerSize - 1) / pointerSize * pointerSize;
            return 4 * pointerSize + nameSize + 3;
        }

        private static bool DetectNameFlags()
        {
            string assemblyName = typeof(object).Assembly.GetName().Name;
            string typeName = "MonsterRoadtripMonoCompat.MissingType" + Guid.NewGuid().ToString("N");
            try
            {
                Type.GetType(typeName + ", " + assemblyName, true);
            }
            catch (TypeLoadException exception)
            {
                if (exception.TypeName == typeName)
                {
                    FieldInfo field = typeof(TypeLoadException).GetField("AssemblyName", BindingFlags.Instance | BindingFlags.NonPublic)
                        ?? typeof(TypeLoadException).GetField("assemblyName", BindingFlags.Instance | BindingFlags.NonPublic);
                    string formatted = field == null ? null : field.GetValue(exception) as string;
                    if (formatted == assemblyName) return true;
                    if (formatted == assemblyName + ", Version=0.0.0.0, Culture=neutral, PublicKeyToken=null") return false;
                }
            }
            // Do not guess a native field position on an unrecognized runtime.
            throw new InvalidOperationException("Could not detect Mono assembly name layout.");
        }
    }
}
