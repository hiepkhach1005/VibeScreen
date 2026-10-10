import SwiftUI

/// The fallback ColorControl mark used if the packaged menu-bar artwork cannot
/// be loaded. The normal status item uses the same packaged `.icns` artwork as
/// the Dock so the app is immediately recognizable in the menu bar.
struct ColorControlMark: View {
    enum Style: Equatable {
        case menuBar
        case appPreview
    }

    let style: Style

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let stroke = max(1, size * 0.09)
            let monitorWidth = size * 0.78
            let monitorHeight = size * 0.54

            VStack(spacing: size * 0.04) {
                ZStack {
                    RoundedRectangle(cornerRadius: size * 0.11, style: .continuous)
                        .stroke(.primary, lineWidth: stroke)
                        .frame(width: monitorWidth, height: monitorHeight)

                    VStack(spacing: size * 0.07) {
                        controlLine(color: .cyan, size: size)
                        controlLine(color: .green, size: size)
                        controlLine(color: .orange, size: size)
                    }
                    .frame(width: monitorWidth * 0.68)
                }

                Capsule(style: .continuous)
                    .fill(.primary)
                    .frame(width: size * 0.22, height: stroke)

                Capsule(style: .continuous)
                    .fill(.primary)
                    .frame(width: size * 0.42, height: stroke)
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .foregroundStyle(style == .menuBar ? AnyShapeStyle(.primary) : AnyShapeStyle(.white))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel("ColorControl")
    }

    @ViewBuilder
    private func controlLine(color: Color, size: CGFloat) -> some View {
        HStack(spacing: 0) {
            Capsule(style: .continuous)
                .fill(style == .appPreview ? color : Color.primary.opacity(0.9))
                .frame(height: max(1, size * 0.055))
            Circle()
                .fill(style == .appPreview ? color : Color.primary)
                .frame(width: max(2, size * 0.11), height: max(2, size * 0.11))
                .offset(x: -size * 0.08)
        }
    }
}
