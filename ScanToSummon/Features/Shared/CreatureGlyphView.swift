import SwiftUI

/// A flat portrait of a creature, drawn from the same `BodyPlan` the 3D body
/// uses.
///
/// Sharing the plan is what stops the Codex from feeling like a different game
/// than the AR view: a spiky metallic thing in the room is a spiky metallic
/// thing in the grid, in the same colour, with no art required.
struct CreatureGlyphView: View {
    let archetype: Archetype
    let rgb: ColorRGB
    /// Only used for the accessibility label.
    var name: String = ""

    init(archetype: Archetype, rgb: ColorRGB, name: String = "") {
        self.archetype = archetype
        self.rgb = rgb
        self.name = name
    }

    init(creature: Creature) {
        self.init(archetype: creature.archetype, rgb: creature.tint, name: creature.name)
    }

    init(unit: BattleUnit) {
        self.init(archetype: unit.archetype, rgb: unit.tint, name: unit.name)
    }

    private var plan: BodyPlan { archetype.bodyPlan }
    private var tint: Color { Theme.color(rgb) }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let unit = size / 100

            ZStack {
                spikes(unit: unit)
                torso(unit: unit)
                crest(unit: unit)
                head(unit: unit)
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .shadow(color: plan.glow > 0.3 ? tint.opacity(0.7) : .clear, radius: 10 * unit)
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityLabel(Text(name))
    }

    // Body proportions are read from the same metres the 3D plan uses, then
    // normalised, so a wide squat archetype stays wide and squat here.
    private var torsoAspect: CGFloat {
        CGFloat(plan.torsoSize.x / max(plan.torsoSize.y, 0.001))
    }

    /// Type-erased so a `switch` can pick the outline and callers can still
    /// use `.fill`, which a `Group` of shapes would not allow.
    private func shape(for form: BodyPlan.Shape, cornerRadius: CGFloat) -> AnyShape {
        switch form {
        case .box:
            return AnyShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        case .sphere, .capsule:
            return AnyShape(Ellipse())
        }
    }

    private func torso(unit: CGFloat) -> some View {
        let height = 44 * unit
        let width = min(70 * unit, height * torsoAspect)

        return shape(for: plan.torso, cornerRadius: 8 * unit)
        .fill(
            LinearGradient(
                colors: [tint.opacity(0.95), tint.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .frame(width: width, height: height)
        .offset(y: 16 * unit)
    }

    private func head(unit: CGFloat) -> some View {
        let diameter = CGFloat(plan.headRadius / 0.055) * 30 * unit
        let eye = diameter * 0.26

        return ZStack {
            shape(for: plan.head, cornerRadius: 6 * unit)
                .fill(tint)
                .frame(width: diameter, height: diameter)

            HStack(spacing: diameter * 0.20) {
                ForEach(0..<2, id: \.self) { _ in
                    ZStack {
                        Circle().fill(.white)
                        Circle()
                            .fill(Color(white: 0.08))
                            .frame(width: eye * 0.5, height: eye * 0.5)
                    }
                    .frame(width: eye, height: eye)
                }
            }
            .offset(y: diameter * 0.06)
        }
        .offset(y: -20 * unit)
    }

    private func spikes(unit: CGFloat) -> some View {
        ForEach(0..<max(plan.spikeCount, 0), id: \.self) { index in
            let angle = Double(index) / Double(max(plan.spikeCount, 1)) * 360.0
            RoundedRectangle(cornerRadius: 1.5 * unit, style: .continuous)
                .fill(tint.opacity(0.9))
                .frame(width: 16 * unit, height: 5 * unit)
                .offset(x: 30 * unit)
                .rotationEffect(.degrees(angle))
                .offset(y: 16 * unit)
        }
    }

    @ViewBuilder
    private func crest(unit: CGFloat) -> some View {
        if plan.hasCrest {
            Capsule()
                .fill(tint.opacity(0.85))
                .frame(width: 8 * unit, height: 26 * unit)
                .rotationEffect(.degrees(18))
                .offset(x: 6 * unit, y: -42 * unit)
        }
    }
}

/// Small coloured chip naming a creature's combat type.
struct ElementBadge: View {
    let element: Element

    var body: some View {
        Text(LocalizedStringKey(element.localizationKey))
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(color.opacity(0.22), in: Capsule())
            .foregroundStyle(color)
    }

    private var color: Color {
        switch element {
        case .ember: return Color(red: 1.0, green: 0.48, blue: 0.32)
        case .verdant: return Color(red: 0.50, green: 0.85, blue: 0.45)
        case .aqua: return Color(red: 0.40, green: 0.72, blue: 1.0)
        case .ferro: return Color(red: 0.78, green: 0.80, blue: 0.86)
        case .air: return Color(red: 0.85, green: 0.80, blue: 1.0)
        case .void: return Color(red: 0.78, green: 0.55, blue: 1.0)
        }
    }
}
