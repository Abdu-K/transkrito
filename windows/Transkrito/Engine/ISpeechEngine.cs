namespace Transkrito.Engine;

/// <summary>
/// One loaded ASR model with an utterance session on top. Streaming engines decode while audio arrives and expose
/// partial text; offline engines buffer and decode at the end. Audio is 16 kHz mono float32.
/// </summary>
public interface ISpeechEngine : IDisposable
{
    ModelInfo? LoadedModel { get; }
    bool IsLoaded { get; }
    /// <summary>Whether dictionary terms can be handed to the model as context.</summary>
    bool BiasSupported { get; }
    string BiasStatus { get; }

    Task LoadAsync(ModelInfo model);
    void SetBiasTerms(IReadOnlyList<string> terms);

    /// <summary>Start an utterance. <paramref name="language"/> is "en"/"de"/"ar" to pin, or null for automatic detection.</summary>
    void BeginUtterance(string? language);
    /// <summary>Audio thread: hand over the next chunk.</summary>
    void Feed(float[] samples16k);
    /// <summary>Latest partial text (streaming engines only; null otherwise). Raised on a worker thread.</summary>
    event Action<string>? PartialText;
    /// <summary>Finish the utterance and return the raw transcript.</summary>
    Task<string> EndUtteranceAsync();
}
