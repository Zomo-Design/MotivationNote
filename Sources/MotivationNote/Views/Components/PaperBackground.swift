import SwiftUI

struct PaperBackground: View {
    let color: PaperColor
    let texture: PaperTexture
    var cornerRadius: CGFloat = 18
    var showsShadow = true

    var body: some View {
        RoundedRectangle(
            cornerRadius: cornerRadius,
            style: .continuous
        )
        .fill(color.backgroundColor)
        .overlay {
            Canvas { context, size in
                drawTexture(
                    in: &context,
                    size: size,
                    ink: color.textColor.opacity(0.10)
                )
            }
            .clipShape(
                RoundedRectangle(
                    cornerRadius: cornerRadius,
                    style: .continuous
                )
            )
        }
        .shadow(
            color: showsShadow ? .black.opacity(0.22) : .clear,
            radius: showsShadow ? 24 : 0,
            y: showsShadow ? 14 : 0
        )
    }

    private func drawTexture(
        in context: inout GraphicsContext,
        size: CGSize,
        ink: Color
    ) {
        switch texture {
        case .lined:
            drawLines(
                in: &context,
                size: size,
                spacing: 27,
                ink: ink,
                horizontal: true,
                vertical: false
            )
        case .dotted:
            for x in stride(
                from: 7.0,
                through: size.width,
                by: 14.0
            ) {
                for y in stride(
                    from: 7.0,
                    through: size.height,
                    by: 14.0
                ) {
                    context.fill(
                        Path(
                            ellipseIn: CGRect(
                                x: x,
                                y: y,
                                width: 1.5,
                                height: 1.5
                            )
                        ),
                        with: .color(ink)
                    )
                }
            }
        case .grid:
            drawLines(
                in: &context,
                size: size,
                spacing: 18,
                ink: ink,
                horizontal: true,
                vertical: true
            )
        case .plain:
            break
        }
    }

    private func drawLines(
        in context: inout GraphicsContext,
        size: CGSize,
        spacing: CGFloat,
        ink: Color,
        horizontal: Bool,
        vertical: Bool
    ) {
        if horizontal {
            for y in stride(
                from: spacing,
                through: size.height,
                by: spacing
            ) {
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                context.stroke(
                    path,
                    with: .color(ink),
                    lineWidth: 1
                )
            }
        }

        if vertical {
            for x in stride(
                from: spacing,
                through: size.width,
                by: spacing
            ) {
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                context.stroke(
                    path,
                    with: .color(ink),
                    lineWidth: 1
                )
            }
        }
    }
}
