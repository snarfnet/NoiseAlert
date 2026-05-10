import SwiftUI

struct ContentView: View {
    @StateObject private var monitor = NoiseMonitor()

    private let limit = 85.0

    var body: some View {
        ZStack {
            heroBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    header
                    meterPanel
                    warningPanel
                    levelGuide
                    controlButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 18)
                .padding(.bottom, 30)
            }
        }
        .preferredColorScheme(.dark)
        .animation(.spring(response: 0.36, dampingFraction: 0.82), value: monitor.isOverLimit)
        .animation(.easeOut(duration: 0.16), value: monitor.decibelLevel)
    }

    private var heroBackground: some View {
        ZStack {
            Image("NoiseHero")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            LinearGradient(
                colors: [
                    Color.black.opacity(0.08),
                    Color(red: 0.01, green: 0.04, blue: 0.07).opacity(0.62),
                    Color.black.opacity(0.94)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            if monitor.isOverLimit {
                Color(red: 0.95, green: 0.18, blue: 0.08)
                    .opacity(0.16)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                Image(systemName: monitor.isRunning ? "waveform.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(statusColor)
            }
            .frame(width: 54, height: 54)

            VStack(alignment: .leading, spacing: 5) {
                Text("NoiseAlert")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(statusMessage)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.72))
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.top, 10)
    }

    private var meterPanel: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                statusColor.opacity(0.24),
                                Color.white.opacity(0.05),
                                Color.black.opacity(0.12)
                            ],
                            center: .center,
                            startRadius: 18,
                            endRadius: 152
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(.white.opacity(0.12), lineWidth: 1)
                    )

                Circle()
                    .stroke(.white.opacity(0.10), lineWidth: 18)
                    .padding(18)

                Circle()
                    .trim(from: 0, to: meterProgress)
                    .stroke(
                        AngularGradient(
                            colors: [.cyan, .mint, .yellow, .orange, .red],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 18, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .padding(18)
                    .shadow(color: statusColor.opacity(0.55), radius: 18, x: 0, y: 0)

                VStack(spacing: 8) {
                    Text(String(format: "%.0f", monitor.decibelLevel))
                        .font(.system(size: 84, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .monospacedDigit()
                        .minimumScaleFactor(0.7)

                    Text("dB")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(statusColor)

                    Text(levelName)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.82))
                }
            }
            .frame(maxWidth: 330)
            .aspectRatio(1, contentMode: .fit)

            HStack(spacing: 10) {
                Label("基準 \(Int(limit)) dB", systemImage: "flag.checkered")
                Spacer(minLength: 8)
                if monitor.isRunning {
                    Button {
                        monitor.resetPeak()
                    } label: {
                        Label("Peak \(Int(monitor.peakLevel)) dB", systemImage: "arrow.up.to.line")
                    }
                } else {
                    Label(limitCaption, systemImage: "ear")
                }
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white.opacity(0.74))
        }
        .padding(20)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(monitor.isOverLimit ? 0.28 : 0.12), lineWidth: 1)
        )
    }

    @ViewBuilder
    private var warningPanel: some View {
        if monitor.isOverLimit {
            HStack(spacing: 14) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(.white)

                VStack(alignment: .leading, spacing: 5) {
                    Text("騒音レベルが高すぎます")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text("少し離れる、音量を下げるなど、耳を守る行動をおすすめします。")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.84))
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.18, blue: 0.08),
                        Color(red: 0.95, green: 0.46, blue: 0.10)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                in: RoundedRectangle(cornerRadius: 20, style: .continuous)
            )
            .shadow(color: .red.opacity(0.32), radius: 24, x: 0, y: 12)
            .transition(.scale(scale: 0.96).combined(with: .opacity))
        } else {
            HStack(spacing: 14) {
                Image(systemName: monitor.isRunning ? "checkmark.shield.fill" : "hand.tap.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(statusColor)

                VStack(alignment: .leading, spacing: 5) {
                    Text(monitor.isRunning ? "安全な範囲です" : "測定を開始できます")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                    Text(monitor.isRunning ? "周囲の音をリアルタイムで監視しています。" : "マイクを使って、今いる場所の騒音を測ります。")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.72))
                }

                Spacer(minLength: 0)
            }
            .padding(18)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(.white.opacity(0.10), lineWidth: 1)
            )
        }
    }

    private var levelGuide: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("音の目安")
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            HStack(spacing: 10) {
                guideItem(title: "静か", range: "0-60", color: .mint)
                guideItem(title: "注意", range: "60-85", color: .orange)
                guideItem(title: "警告", range: "85+", color: .red)
            }
        }
        .padding(18)
        .background(Color.black.opacity(0.24), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.09), lineWidth: 1)
        )
    }

    private func guideItem(title: String, range: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            Text(title)
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
            Text("\(range) dB")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
                .monospacedDigit()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var controlButton: some View {
        Button {
            let gen = UIImpactFeedbackGenerator(style: .medium)
            gen.impactOccurred()
            monitor.isRunning ? monitor.stop() : monitor.start()
        } label: {
            HStack(spacing: 12) {
                Image(systemName: monitor.isRunning ? "stop.fill" : "mic.fill")
                    .font(.headline.weight(.bold))
                Text(monitor.isRunning ? "測定を停止" : "測定を開始")
                    .font(.headline.weight(.bold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: monitor.isRunning
                    ? [Color.white.opacity(0.20), Color.white.opacity(0.10)]
                    : [Color.cyan, Color.blue],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
        }
        .buttonStyle(.plain)
    }

    private var meterProgress: CGFloat {
        CGFloat(min(max(monitor.decibelLevel / 120.0, 0), 1))
    }

    private var statusColor: Color {
        switch monitor.decibelLevel {
        case ..<60: return .mint
        case 60..<75: return .yellow
        case 75..<limit: return .orange
        default: return .red
        }
    }

    private var levelName: String {
        switch monitor.decibelLevel {
        case ..<45: return monitor.isRunning ? "とても静か" : "待機中"
        case ..<60: return "静か"
        case ..<75: return "やや大きい"
        case ..<limit: return "注意"
        default: return "警告"
        }
    }

    private var statusMessage: String {
        if monitor.isOverLimit { return "耳を守るため、今すぐ周囲の音を確認してください" }
        if monitor.isRunning { return "周囲の騒音をリアルタイムで測定中" }
        return "ワンタップで騒音レベルをチェック"
    }

    private var limitCaption: String {
        monitor.isOverLimit ? "基準超過" : "基準内"
    }
}

#Preview {
    ContentView()
}
