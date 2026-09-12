using System.Globalization;

namespace Transkrito.Engine;

/// <summary>Spoken-language ids used everywhere: "en", "de", "ar", "auto" (setting only), "unknown" (history only).</summary>
public static class Lang
{
    public const string Auto = "auto", En = "en", De = "de", Ar = "ar", Unknown = "unknown";
    public static readonly string[] Supported = { En, De, Ar };

    /// <summary>Display name in the language's own script; the UI stays in English.</summary>
    public static string Display(string id) => id switch
    {
        En => "English",
        De => "Deutsch",
        Ar => "العربية",
        Auto => "Auto",
        _ => "",
    };

    public static bool IsSupported(string? id) => id is En or De or Ar;
}

public sealed record LanguageGuess(string Language, double Confidence)
{
    public bool IsConfident => Language != Lang.Unknown && Confidence >= LanguageDetector.ConfidentAt;
}

/// <summary>
/// Text-based classifier for the three exposed languages. Script decides Arabic; a function-word lexicon plus
/// umlaut/ß evidence separates German from English. Used to stamp history and to show "Listening · Deutsch"
/// while a streaming engine produces partial text. Shared vectors: shared/correction-tests.json "language".
/// Mirrors macos/.../Engine/LanguageDetector.swift.
/// </summary>
public static class LanguageDetector
{
    public const double ConfidentAt = 0.6;

    private static readonly HashSet<string> German = new(StringComparer.Ordinal)
    {
        "der","die","das","und","ich","nicht","ist","zu","ein","eine","mit","auf","für","von","den","dem","des","sich","auch",
        "es","an","er","wir","sie","im","nach","bei","aus","morgen","heute","muss","kann","wird","sind","haben","hat","war",
        "noch","wie","schon","nur","mehr","sehr","zur","zum","dann","wenn","aber","oder","was","mir","mich","dir","uns",
        "bitte","öffne","neu","neue","projekt","gehe","fahre","fahren","schule","arbeit","jetzt","hier","dort","über","unter",
        "diese","dieser","dieses","kein","keine","meine","mein","dein","seine","ihre","wichtig","getroffen","besprochen",
    };

    private static readonly HashSet<string> English = new(StringComparer.Ordinal)
    {
        "the","and","to","of","a","in","is","it","you","that","he","was","for","on","are","with","as","i","his","they","be",
        "at","one","have","this","from","or","had","by","not","but","what","some","we","can","out","other","were","all",
        "there","when","up","use","uses","your","how","said","an","each","she","which","do","their","if","will","way",
        "about","many","then","them","would","like","so","these","her","make","thing","see","him","two","has","look",
        "more","day","could","go","come","did","no","most","my","over","know","than","call","first","who","may","down",
        "been","now","find","please","open","close","new","update","project","need","want","going","just","fine","works",
        "app","me","our","also","into","should","after","before","because","very","much","get","got",
    };

    public static LanguageGuess Detect(string? text)
    {
        if (string.IsNullOrWhiteSpace(text)) return new LanguageGuess(Lang.Unknown, 0);

        int arabic = 0, latin = 0;
        foreach (var ch in text)
        {
            if (IsArabicLetter(ch)) arabic++;
            else if (char.IsLetter(ch)) latin++;
        }
        var letters = arabic + latin;
        if (letters == 0) return new LanguageGuess(Lang.Unknown, 0);

        var arabicShare = (double)arabic / letters;
        if (arabicShare >= 0.5) return new LanguageGuess(Lang.Ar, Math.Min(1, 0.6 + arabicShare * 0.4));
        if (arabicShare >= 0.3) return new LanguageGuess(Lang.Ar, 0.5);

        // Latin script: German vs English on function words and orthography.
        int de = 0, en = 0;
        foreach (var raw in text.Split((char[]?)null, StringSplitOptions.RemoveEmptyEntries))
        {
            var w = raw.Trim('.', ',', ';', ':', '!', '?', '"', '\'', '(', ')', '“', '”', '‘', '’').ToLowerInvariant();
            if (w.Length == 0) continue;
            if (German.Contains(w)) de++;
            if (English.Contains(w)) en++;
        }
        foreach (var ch in text)
            if (ch is 'ä' or 'ö' or 'ü' or 'ß' or 'Ä' or 'Ö' or 'Ü') { de++; break; }

        if (de == 0 && en == 0) return new LanguageGuess(Lang.Unknown, 0);
        var winner = de > en ? Lang.De : en > de ? Lang.En : Lang.Unknown;
        if (winner == Lang.Unknown) return new LanguageGuess(Lang.Unknown, 0.3);
        var hi = Math.Max(de, en);
        var lo = Math.Min(de, en);
        var confidence = hi >= 2 && hi >= 2 * lo ? Math.Min(1, 0.6 + 0.1 * (hi - lo)) : hi == 1 && lo == 0 ? 0.5 : 0.4;
        return new LanguageGuess(winner, confidence);
    }

    /// <summary>Language to store for a finished transcription: the confident guess, else "unknown".</summary>
    public static string ForHistory(string? text) => Detect(text) is { IsConfident: true } g ? g.Language : Lang.Unknown;

    public static bool IsArabicLetter(char ch)
    {
        var c = (int)ch;
        var inBlock = (c >= 0x0600 && c <= 0x06FF) || (c >= 0x0750 && c <= 0x077F) || (c >= 0x08A0 && c <= 0x08FF)
                      || (c >= 0xFB50 && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFF);
        return inBlock && CharUnicodeInfo.GetUnicodeCategory(ch) is UnicodeCategory.OtherLetter or UnicodeCategory.NonSpacingMark;
    }

    /// <summary>True when the text's dominant script is right-to-left. Rendering only: the string is never touched.</summary>
    public static bool IsRightToLeft(string? text)
    {
        if (string.IsNullOrEmpty(text)) return false;
        int rtl = 0, ltr = 0;
        foreach (var ch in text)
        {
            if (IsArabicLetter(ch) || (ch >= 0x0590 && ch <= 0x05FF)) rtl++;
            else if (char.IsLetter(ch)) ltr++;
        }
        return rtl > 0 && rtl * 2 >= ltr;
    }
}
