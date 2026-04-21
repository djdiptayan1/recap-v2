import SwiftUI
import SpriteKit
import Combine

struct DailyMoodSheet: View {
    let patientId: String
    @ObservedObject var viewModel: DailyMoodViewModel

    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var selectedMood: DailyMoodKey
    @State private var sliderValue: Double
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var showAlert = false

    init(patientId: String, viewModel: DailyMoodViewModel) {
        self.patientId = patientId
        self.viewModel = viewModel

        let initialMood = viewModel.todayEntry?.moodKey ?? .neutral
        _selectedMood = State(initialValue: initialMood)
        _sliderValue = State(initialValue: initialMood.score)
    }

    var body: some View {
        let palette = selectedMood.palette

        ZStack {
            LinearGradient(
                colors: [palette.backgroundTop, palette.backgroundBottom],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            .animation(.easeInOut(duration: 0.3), value: selectedMood)

            VStack(spacing: 28) {

                VStack(spacing: 18) {
                    Text("Choose how you're\nfeeling today")
                        .font(AppConfig.Fonts.titleMedium)
                        .foregroundStyle(.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(2)

                    MoodBloomView(progress: sliderValue)
                        .frame(width: 320, height: 320)
                        .padding(.top, 8)

                    Text(selectedMood.displayName)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.92))
                        .animation(.easeInOut, value: selectedMood)
                }

                sliderSection

                Spacer(minLength: 10)

                logButton

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 28)
            .padding(.top, 12)
            .padding(.bottom, 24)
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Close", systemImage: "chevron.backward") {
                    dismiss()
                }
            }
        }
        .alert("Unable to Save Mood", isPresented: $showAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Please try again.")
        }
    }

    private var sliderSection: some View {
        VStack(spacing: 12) {
            VStack(spacing: 14) {
                Slider(value: $sliderValue, in: 0...4, step: 0.05)
                    .tint(.white)
                    .onChange(of: sliderValue) { _, newValue in
                        let nextMood = DailyMoodKey(score: newValue)
                        guard nextMood != selectedMood else { return }
                        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.2)) {
                            selectedMood = nextMood
                        }
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                    }

                HStack {
                    Text("VERY UNPLEASANT")
                    Spacer()
                    Text("VERY PLEASANT")
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.56))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .glassEffect(.clear, in: .rect(cornerRadius: 24))
        }
    }

    private var logButton: some View {
        Button {
            Task { await saveMood() }
        } label: {
            ZStack {
                if isSaving {
                    ProgressView().tint(.white)
                } else {
                    Text("Log Mood")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(selectedMood.palette.primary)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(color: selectedMood.palette.primary.opacity(0.35), radius: 12, x: 0, y: 8)
            .animation(.easeInOut, value: selectedMood)
        }
        .disabled(isSaving)
    }

    private func saveMood() async {
        guard !isSaving else { return }
        guard !patientId.isEmpty else {
            errorMessage = "Patient ID is missing. Please reopen the screen and try again."
            showAlert = true
            return
        }

        isSaving = true
        defer { isSaving = false }

        let saved = await viewModel.saveMood(patientId: patientId, mood: selectedMood)
        if let saved {
            viewModel.todayEntry = saved
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
            dismiss()
        } else {
            errorMessage = viewModel.errorMessage ?? "Mood was not saved. Please try again."
            showAlert = true
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - SpriteKit Views & Logic

private struct MoodBloomView: View {
    let progress: Double
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var store = MoodBloomSceneStore()

    private var parameters: MoodBloomParameters {
        MoodBloomParameters.resolve(progress: progress)
    }

    var body: some View {
        SpriteView(
            scene: store.scene,
            preferredFramesPerSecond: 60,
            options: [.allowsTransparency]
        )
        .onAppear {
            store.scene.apply(parameters: parameters, animated: false, reduceMotion: reduceMotion)
        }
        .onChange(of: progress) { _, _ in
            store.scene.apply(parameters: parameters, animated: true, reduceMotion: reduceMotion)
        }
    }
}

private final class MoodBloomSceneStore: ObservableObject {
    let scene = MoodBloomScene(size: CGSize(width: 320, height: 320))
}

private final class MoodBloomScene: SKScene {
    private let auraNode = SKShapeNode(circleOfRadius: 140)
    private var layerNodes: [LayerNodes] = []
    private var hasConfigured = false

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = .clear
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMove(to view: SKView) {
        super.didMove(to: view)
        configureIfNeeded()
    }

    func apply(parameters: MoodBloomParameters, animated: Bool, reduceMotion: Bool) {
        configureIfNeeded()

        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        auraNode.fillColor = SKColor(parameters.palette.glow).withAlphaComponent(0.12)
        auraNode.position = center

        if animated && !reduceMotion && auraNode.action(forKey: "auraPulse") == nil {
            auraNode.run(
                .repeatForever(.sequence([
                    .scale(to: 1.05, duration: 2.0),
                    .scale(to: 0.95, duration: 2.0),
                ])),
                withKey: "auraPulse"
            )
        }

        for (index, layer) in parameters.layers.enumerated() where index < layerNodes.count {
            let nodes = layerNodes[index]
            
            // Generate the specialized math path
            let path = moodPath(
                radius: layer.size * 0.45, // Scaled to fit 320x320 well
                lobes: layer.lobes,
                amplitude: layer.amplitude,
                phase: layer.phase
            )

            nodes.glow.path = path
            nodes.fill.path = path
            nodes.sheen.path = path

            let tint = SKColor(layer.tint)

            // Outer Glow (Add blend mode)
            nodes.glow.fillColor = tint.withAlphaComponent(0.3)
            nodes.glow.position = center
            nodes.glow.setScale(1.08)

            // Base Fill Shape
            nodes.fill.fillColor = tint.withAlphaComponent(0.5 - 0.1 * CGFloat(index))
            nodes.fill.position = center

            // 3D Rim / Sheen Highlight
            nodes.sheen.strokeColor = .white.withAlphaComponent(0.5 - 0.1 * CGFloat(index))
            nodes.sheen.position = center

            let targetRotation = CGFloat(layer.rotation * .pi / 180)
            if animated && !reduceMotion {
                let action = SKAction.rotate(toAngle: targetRotation, duration: 0.3, shortestUnitArc: true)
                action.timingMode = .easeOut
                nodes.fill.run(action)
                nodes.glow.run(action)
                nodes.sheen.run(action)
            } else {
                nodes.fill.zRotation = targetRotation
                nodes.glow.zRotation = targetRotation
                nodes.sheen.zRotation = targetRotation
            }
        }
    }

    // Mathematically constructs the blob/petal shape
    private func moodPath(radius: Double, lobes: Double, amplitude: Double, phase: Double) -> CGPath {
        let samples = 180
        let path = CGMutablePath()

        for index in 0...samples {
            let angle = (Double(index) / Double(samples)) * .pi * 2
            
            // Using cosine for symmetrical petals/spikes
            let baseWave = cos(angle * lobes + phase)
            
            // Shape modifier: makes the outer peaks rounded and inner valleys sharper
            let shapeModifier = amplitude > 0 ? (baseWave > 0 ? pow(baseWave, 0.8) : -pow(-baseWave, 1.2)) : 0
            
            // Add a very subtle secondary wave for the "fluid" imperfect look
            let microWave = amplitude > 0 ? sin(angle * lobes * 2) * 0.1 : 0
            
            let currentRadius = radius * (1 + amplitude * shapeModifier + amplitude * microWave)
            
            let point = CGPoint(
                x: cos(angle) * currentRadius,
                y: sin(angle) * currentRadius
            )

            if index == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }

        path.closeSubpath()
        return path
    }

    private func configureIfNeeded() {
        guard !hasConfigured else { return }
        hasConfigured = true
        isUserInteractionEnabled = false

        auraNode.lineWidth = 0
        addChild(auraNode)

        for _ in 0..<3 { // 3 Layers (Outer, Middle, Inner)
            let glow = SKShapeNode()
            glow.lineWidth = 0
            glow.blendMode = .add

            let fill = SKShapeNode()
            fill.lineWidth = 0
            fill.lineJoin = .round

            let sheen = SKShapeNode()
            sheen.fillColor = .clear
            sheen.lineWidth = 1.5
            sheen.blendMode = .screen
            sheen.lineJoin = .round

            addChild(glow)
            addChild(fill)
            addChild(sheen)

            layerNodes.append(.init(glow: glow, fill: fill, sheen: sheen))
        }
        
        // Center Dot mimicking the reference images
        let centerDot = SKShapeNode(circleOfRadius: 4)
        centerDot.fillColor = .white.withAlphaComponent(0.4)
        centerDot.strokeColor = .clear
        centerDot.position = CGPoint(x: size.width / 2, y: size.height / 2)
        addChild(centerDot)
    }

    private struct LayerNodes {
        let glow: SKShapeNode
        let fill: SKShapeNode
        let sheen: SKShapeNode
    }
}

// MARK: - Parameters & Interpolation Logic

private struct MoodBloomParameters {
    let palette: MoodPalette
    let layers: [MoodBloomLayerParameters]

    static func resolve(progress: Double) -> MoodBloomParameters {
        let maxIndex = DailyMoodKey.allCases.count - 1
        let lowerIndex = max(0, min(Int(floor(progress)), maxIndex))
        let upperIndex = max(0, min(Int(ceil(progress)), maxIndex))
        let fraction = progress - Double(lowerIndex)

        let lower = preset(for: DailyMoodKey.allCases[lowerIndex])
        let upper = preset(for: DailyMoodKey.allCases[upperIndex])

        let palette = MoodPalette(
            primary: lower.palette.primary.mix(with: upper.palette.primary, amount: fraction),
            secondary: lower.palette.secondary.mix(with: upper.palette.secondary, amount: fraction),
            glow: lower.palette.glow.mix(with: upper.palette.glow, amount: fraction),
            backgroundTop: lower.palette.backgroundTop.mix(with: upper.palette.backgroundTop, amount: fraction),
            backgroundBottom: lower.palette.backgroundBottom.mix(with: upper.palette.backgroundBottom, amount: fraction)
        )

        let layers = zip(lower.layers, upper.layers).map { lowerLayer, upperLayer in
            MoodBloomLayerParameters(
                size: lowerLayer.size + (upperLayer.size - lowerLayer.size) * fraction,
                lobes: lowerLayer.lobes + (upperLayer.lobes - lowerLayer.lobes) * fraction,
                amplitude: lowerLayer.amplitude + (upperLayer.amplitude - lowerLayer.amplitude) * fraction,
                phase: lowerLayer.phase + (upperLayer.phase - lowerLayer.phase) * fraction,
                rotation: lowerLayer.rotation + (upperLayer.rotation - lowerLayer.rotation) * fraction,
                tint: lowerLayer.tint.mix(with: upperLayer.tint, amount: fraction)
            )
        }

        return MoodBloomParameters(palette: palette, layers: layers)
    }

    // Carefully tuned mathematics to match the reference images
    static func preset(for mood: DailyMoodKey) -> MoodBloomParameters {
        switch mood {
        case .veryUnpleasant: // Spiky, chaotic
            return MoodBloomParameters(palette: mood.palette, layers: [
                .init(size: 240, lobes: 8, amplitude: 0.35, phase: 0.2, rotation: 15, tint: mood.palette.secondary),
                .init(size: 180, lobes: 8, amplitude: 0.30, phase: 0.8, rotation: -10, tint: mood.palette.primary),
                .init(size: 120, lobes: 8, amplitude: 0.25, phase: 0.4, rotation: 5, tint: mood.palette.glow)
            ])
        case .unpleasant: // Wavy, less chaotic
            return MoodBloomParameters(palette: mood.palette, layers: [
                .init(size: 250, lobes: 8, amplitude: 0.20, phase: 0.0, rotation: 10, tint: mood.palette.secondary),
                .init(size: 190, lobes: 8, amplitude: 0.15, phase: 0.5, rotation: -5, tint: mood.palette.primary),
                .init(size: 130, lobes: 8, amplitude: 0.10, phase: 0.2, rotation: 2, tint: mood.palette.glow)
            ])
        case .neutral: // Perfect smooth circles
            return MoodBloomParameters(palette: mood.palette, layers: [
                .init(size: 260, lobes: 0, amplitude: 0.0, phase: 0.0, rotation: 0, tint: mood.palette.secondary),
                .init(size: 200, lobes: 0, amplitude: 0.0, phase: 0.0, rotation: 0, tint: mood.palette.primary),
                .init(size: 140, lobes: 0, amplitude: 0.0, phase: 0.0, rotation: 0, tint: mood.palette.glow)
            ])
//        case .slightlyPleasant: // Soft pentagon (5 lobes, low amp)
//            return MoodBloomParameters(palette: mood.palette, layers: [
//                .init(size: 250, lobes: 5, amplitude: 0.10, phase: 0.1, rotation: -10, tint: mood.palette.secondary),
//                .init(size: 190, lobes: 5, amplitude: 0.08, phase: 0.3, rotation: 5, tint: mood.palette.primary),
//                .init(size: 130, lobes: 5, amplitude: 0.05, phase: 0.6, rotation: -2, tint: mood.palette.glow)
//            ])
        case .pleasant: // Deeper flower (5 lobes, medium amp)
            return MoodBloomParameters(palette: mood.palette, layers: [
                .init(size: 250, lobes: 5, amplitude: 0.25, phase: 0.0, rotation: -15, tint: mood.palette.secondary),
                .init(size: 180, lobes: 5, amplitude: 0.20, phase: 0.2, rotation: 10, tint: mood.palette.primary),
                .init(size: 120, lobes: 5, amplitude: 0.15, phase: 0.4, rotation: -5, tint: mood.palette.glow)
            ])
        case .veryPleasant: // Deepest flower/star (5 lobes, high amp)
            return MoodBloomParameters(palette: mood.palette, layers: [
                .init(size: 260, lobes: 5, amplitude: 0.35, phase: 0.2, rotation: -20, tint: mood.palette.secondary),
                .init(size: 190, lobes: 5, amplitude: 0.30, phase: 0.5, rotation: 15, tint: mood.palette.primary),
                .init(size: 130, lobes: 5, amplitude: 0.25, phase: 0.8, rotation: -10, tint: mood.palette.glow)
            ])
        }
    }
}

private struct MoodBloomLayerParameters {
    let size: Double
    let lobes: Double
    let amplitude: Double
    let phase: Double
    let rotation: Double
    let tint: Color
}

// MARK: - Utilities

private extension DailyMoodKey {
    init(score: Double) {
        let index = max(0, min(Int(score.rounded()), DailyMoodKey.allCases.count - 1))
        self = DailyMoodKey.allCases[index]
    }
}

private extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
    
    func mix(with other: Color, amount: Double) -> Color {
        let lhs = UIColor(self)
        let rhs = UIColor(other)

        var lr: CGFloat = 0, lg: CGFloat = 0, lb: CGFloat = 0, la: CGFloat = 0
        var rr: CGFloat = 0, rg: CGFloat = 0, rb: CGFloat = 0, ra: CGFloat = 0

        lhs.getRed(&lr, green: &lg, blue: &lb, alpha: &la)
        rhs.getRed(&rr, green: &rg, blue: &rb, alpha: &ra)

        let clamped = max(0, min(amount, 1))
        return Color(
            .sRGB,
            red: Double(lr + (rr - lr) * clamped),
            green: Double(lg + (rg - lg) * clamped),
            blue: Double(lb + (rb - lb) * clamped),
            opacity: Double(la + (ra - la) * clamped)
        )
    }
}

#Preview {
    DailyMoodSheet(patientId: "preview", viewModel: DailyMoodViewModel())
}
