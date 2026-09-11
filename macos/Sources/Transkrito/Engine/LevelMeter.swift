import Foundation

/// RMS → 0..1 level with asymmetric EMA smoothing (attack/release from tokens). Shared math with the Windows port:
/// level = clamp((20·log10(rms) + 50) / 50, 0, 1); a = 1 − exp(−dt/τ).
struct LevelMeter {
    private let attack: Double
    private let release: Double
    private(set) var level: Double = 0

    init(attack: Double = Tokens.Motion.levelAttack, release: Double = Tokens.Motion.levelRelease) {
        self.attack = attack
        self.release = release
    }

    static func instant(_ samples: UnsafeBufferPointer<Float>) -> Double {
        if samples.isEmpty { return 0 }
        var sum: Double = 0
        for s in samples { sum += Double(s * s) }
        let rms = (sum / Double(samples.count)).squareRoot()
        if rms <= 1e-6 { return 0 }
        let db = 20 * log10(rms)
        return min(1, max(0, (db + 50) / 50))
    }

    /// Feed one buffer; dt is the buffer duration in seconds.
    mutating func push(_ samples: UnsafeBufferPointer<Float>, dt: Double) -> Double {
        let target = Self.instant(samples)
        let tau = target > level ? attack : release
        let a = 1 - exp(-dt / tau)
        level += (target - level) * a
        return level
    }

    mutating func reset() { level = 0 }
}
