import SwiftUI

extension LightColor {
    var swiftUIColor: Color {
        switch self {
        case .red: return Color(red: 1.0, green: 0.18, blue: 0.15)
        case .yellow: return Color(red: 1.0, green: 0.78, blue: 0.1)
        case .green: return Color(red: 0.2, green: 0.9, blue: 0.35)
        }
    }
}

struct LampView: View {
    @EnvironmentObject var ampel: AmpelController
    let color: LightColor

    var body: some View {
        let lit = ampel.isLit(color)
        Circle()
            .fill(color.swiftUIColor.opacity(lit ? 1 : 0.18))
            .overlay(Circle().stroke(Color.black.opacity(0.5), lineWidth: 2))
            .shadow(color: lit ? color.swiftUIColor.opacity(0.9) : .clear, radius: 14)
            .frame(width: 72, height: 72)
            .contentShape(Circle())
            .onTapGesture { ampel.toggle(color) }
            .help("Click to toggle \(color.name.lowercased())")
            .animation(.easeOut(duration: 0.12), value: lit)
    }
}

struct ContentView: View {
    @EnvironmentObject var ampel: AmpelController

    private var blinkSelection: Binding<LightColor?> {
        Binding(get: { ampel.blinking }, set: { ampel.setBlink($0) })
    }

    var body: some View {
        VStack(spacing: 18) {
            VStack(spacing: 14) {
                ForEach(LightColor.allCases) { LampView(color: $0) }
            }
            .padding(.vertical, 18)
            .padding(.horizontal, 22)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(white: 0.13))
            )
            .opacity(ampel.connected ? 1 : 0.55)

            HStack {
                Button("All off") { ampel.allOff() }
                Button("All on") { ampel.allOn() }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Blink").font(.caption).foregroundStyle(.secondary)
                Picker("Blink", selection: blinkSelection) {
                    Text("None").tag(LightColor?.none)
                    ForEach(LightColor.allCases) { Text($0.name).tag(LightColor?.some($0)) }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            HStack(spacing: 6) {
                Circle()
                    .fill(ampel.connected ? Color.green : Color.secondary)
                    .frame(width: 8, height: 8)
                Text(ampel.connected ? "Connected" : "Not connected – plug in the USB-Ampel")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let error = ampel.lastError {
                Text(error).font(.caption).foregroundStyle(.red)
            }
        }
        .padding(22)
        .frame(width: 280)
    }
}
