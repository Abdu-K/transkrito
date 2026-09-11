import SwiftUI

/// Pillar simulation shared by the Canvas below. Same math as the Windows PillarsControl (shared/SPEC.md "Pillars").
final class PillarModel {
    static let n = Tokens.Pillar.count
    private static let half = n / 2
    private var envelope = [Double](repeating: 0, count: n)
    private var jitter = [Double](repeating: 0, count: n)
    private var jitterTarget = [Double](repeating: 0, count: n)
    private(set) var heights = [CGFloat](repeating: 0, count: n)
    private(set) var speaking: Double = 0
    private var last: TimeInterval = 0
    private var clock: TimeInterval = 0 // for the idle breathing cycle
    private var rng = SystemRandomNumberGenerator()

    init() {
        for i in 0..<Self.n {
            let d = Double(abs(i - Self.half))
            let c = cos(.pi * d / Double(Self.n - 1))
            envelope[i] = max(Tokens.Pillar.envelopeFloor, c * c)
            heights[i] = Tokens.Pillar.minHeight + (Tokens.Pillar.maxHeight - Tokens.Pillar.minHeight) * Tokens.Pillar.idleLevel * envelope[i]
        }
    }

    /// Advance to `now` with the current level. Returns true when nothing is moving.
    @discardableResult
    func step(now: TimeInterval, level: Double) -> Bool {
        let dt = last == 0 ? 1 / 60.0 : min(0.1, now - last)
        last = now
        clock += dt
        let k = 1 - exp(-dt / (Tokens.Motion.pillarSpringLerp))
        let kSpeak = 1 - exp(-dt / Tokens.Motion.base)
        let speakingTarget: Double = level >= Tokens.Pillar.speakingThreshold ? 1 : 0
        speaking += (speakingTarget - speaking) * kSpeak

        var moving = false
        for i in 0...Self.half {
            if abs(jitter[i] - jitterTarget[i]) < 0.005 {
                jitterTarget[i] = Double.random(in: -Tokens.Pillar.jitter...Tokens.Pillar.jitter, using: &rng)
            }
            jitter[i] += (jitterTarget[i] - jitter[i]) * k * 0.5
            // Resting shape (idleLevel) that breathes slowly (motion.breathing.idle); voice adds on top of it.
            let breath = sin(clock * 2 * .pi / Tokens.Motion.breathing) * Tokens.Motion.breathingAmplitude
            let drive = Tokens.Pillar.idleLevel * (1 + breath) + (1 - Tokens.Pillar.idleLevel) * level
            let target = Tokens.Pillar.minHeight + (Tokens.Pillar.maxHeight - Tokens.Pillar.minHeight)
                * drive * envelope[i] * (1 + jitter[i] * min(1, level * 4))
            heights[i] += (target - heights[i]) * k
            heights[Self.n - 1 - i] = heights[i]
            if abs(target - heights[i]) > 0.05 { moving = true }
        }
        return !moving && abs(speakingTarget - speaking) < 0.01
    }
}

/// The central audio visualization: symmetrical rounded pillars, tallest in the middle.
/// Only speaking pillars get the glass treatment (fill gradient, inner highlight, edge, soft glow).
struct PillarsView: View {
    let level: Double
    @State private var model = PillarModel()

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { ctx, size in
                model.step(now: timeline.date.timeIntervalSinceReferenceDate, level: level)
                draw(ctx: ctx, size: size)
            }
        }
        .frame(width: totalWidth, height: Tokens.Comp.pillarsAreaHeight)
        .allowsHitTesting(false)
    }

    private var totalWidth: CGFloat {
        CGFloat(PillarModel.n) * Tokens.Pillar.width + CGFloat(PillarModel.n - 1) * Tokens.Pillar.gap
    }

    private func draw(ctx: GraphicsContext, size: CGSize) {
        let w = Tokens.Pillar.width, gap = Tokens.Pillar.gap
        let x0 = (size.width - totalWidth) / 2
        let cy = size.height / 2
        let speaking = model.speaking

        // Glow: token shadow.glow, alpha scaled by level and the glass blend.
        let glowAlpha = Tokens.Shadow.glow.alpha * speaking * min(1, level * 1.5)
        if glowAlpha > 0.005 {
            var glow = ctx
            glow.addFilter(.blur(radius: Tokens.Shadow.glow.blur / 2))
            for i in 0..<PillarModel.n {
                let h = model.heights[i]
                let rect = CGRect(x: x0 + CGFloat(i) * (w + gap), y: cy - h / 2, width: w, height: h)
                glow.fill(Capsule().path(in: rect.insetBy(dx: -Tokens.Space.s1 / 2, dy: -Tokens.Space.s1 / 2)), with: .color(Tokens.Colors.accentIce.opacity(glowAlpha)))
            }
        }

        for i in 0..<PillarModel.n {
            let h = model.heights[i]
            let rect = CGRect(x: x0 + CGFloat(i) * (w + gap), y: cy - h / 2, width: w, height: h)
            let shape = Capsule().path(in: rect)
            ctx.fill(shape, with: .color(Tokens.Colors.pillarIdle))
            if speaking > 0.01 {
                var g = ctx
                g.opacity = speaking
                g.fill(shape, with: .linearGradient(
                    Gradient(colors: [Tokens.Colors.pillarGlassFillTop, Tokens.Colors.pillarGlassFillBottom]),
                    startPoint: CGPoint(x: rect.midX, y: rect.minY), endPoint: CGPoint(x: rect.midX, y: rect.maxY)))
                g.stroke(shape, with: .color(Tokens.Colors.pillarGlassEdge), lineWidth: Tokens.Pillar.edgeWidth)
                // Inner highlight: short vertical stroke inside the left edge, top portion only.
                var hl = Path()
                let hx = rect.minX + w * 0.32
                hl.move(to: CGPoint(x: hx, y: rect.minY + w * 0.45))
                hl.addLine(to: CGPoint(x: hx, y: rect.minY + max(w * 0.6, h * Tokens.Pillar.highlightCoverage)))
                g.stroke(hl, with: .color(Tokens.Colors.pillarGlassHighlight),
                         style: StrokeStyle(lineWidth: Tokens.Pillar.highlightWidth, lineCap: .round))
            }
        }
    }
}
