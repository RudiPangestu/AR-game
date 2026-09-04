import Foundation
import simd

/// What kind of thing the scanned object was.
///
/// Archetype drives *flavour and looks*; `Element` drives *combat*. Keeping them
/// separate is what lets us have twelve visually distinct creature families
/// while the type chart stays at six entries.
public enum Archetype: String, Codable, CaseIterable, Sendable {
    case aqua      // mugs, bottles, taps, anything that holds liquid
    case verdant   // plants, fruit, wood
    case ember     // stoves, candles, lamps, anything hot or bright
    case ferro     // tools, keys, cutlery, hardware
    case textil    // clothing, cushions, towels, rugs
    case glass     // windows, jars, screens, mirrors
    case paper     // books, boxes, notes, packaging
    case fauna     // pets, people, plush toys
    case snack     // food, sweets, drinks
    case tech      // phones, laptops, cables, remotes
    case ceramic   // plates, tiles, pots, sinks
    case void      // "I have no idea what that is"

    public var localizationKey: String { "archetype.\(rawValue)" }

    /// Combat type. Several archetypes deliberately share an element — a book
    /// and a t-shirt both fight as `air` — because six types is the point.
    public var element: Element {
        switch self {
        case .aqua, .ceramic: return .aqua
        case .verdant, .snack: return .verdant
        case .ember, .glass: return .ember
        case .ferro, .tech: return .ferro
        case .textil, .paper: return .air
        case .fauna, .void: return .void
        }
    }

    /// Stat identity before any per-scan variance is applied.
    ///
    /// Budgets are kept close to each other on purpose so no archetype is a
    /// trap pick; the differences are in the *shape* of the spread.
    public var baseStats: Stats {
        switch self {
        case .aqua:    return Stats(hp: 110, attack: 22, defense: 20, speed: 18)
        case .verdant: return Stats(hp: 125, attack: 20, defense: 22, speed: 14)
        case .ember:   return Stats(hp: 90,  attack: 30, defense: 14, speed: 21)
        case .ferro:   return Stats(hp: 105, attack: 24, defense: 30, speed: 11)
        case .textil:  return Stats(hp: 120, attack: 17, defense: 24, speed: 16)
        case .glass:   return Stats(hp: 80,  attack: 32, defense: 10, speed: 25)
        case .paper:   return Stats(hp: 95,  attack: 21, defense: 15, speed: 24)
        case .fauna:   return Stats(hp: 115, attack: 25, defense: 18, speed: 20)
        case .snack:   return Stats(hp: 130, attack: 19, defense: 19, speed: 15)
        case .tech:    return Stats(hp: 92,  attack: 27, defense: 17, speed: 23)
        case .ceramic: return Stats(hp: 118, attack: 20, defense: 27, speed: 12)
        case .void:    return Stats(hp: 100, attack: 26, defense: 19, speed: 19)
        }
    }

    public var bodyPlan: BodyPlan {
        switch self {
        case .aqua:
            return BodyPlan(torso: .sphere, torsoSize: SIMD3(0.13, 0.13, 0.13), head: .sphere,
                            headRadius: 0.055, limbCount: 0, spikeCount: 0, hasCrest: false,
                            metallic: 0.0, roughness: 0.12, glow: 0.10)
        case .verdant:
            return BodyPlan(torso: .capsule, torsoSize: SIMD3(0.11, 0.16, 0.11), head: .sphere,
                            headRadius: 0.058, limbCount: 2, spikeCount: 0, hasCrest: true,
                            metallic: 0.0, roughness: 0.75, glow: 0.0)
        case .ember:
            return BodyPlan(torso: .sphere, torsoSize: SIMD3(0.11, 0.13, 0.11), head: .sphere,
                            headRadius: 0.05, limbCount: 2, spikeCount: 6, hasCrest: false,
                            metallic: 0.0, roughness: 0.45, glow: 0.55)
        case .ferro:
            return BodyPlan(torso: .box, torsoSize: SIMD3(0.14, 0.13, 0.11), head: .box,
                            headRadius: 0.05, limbCount: 4, spikeCount: 4, hasCrest: false,
                            metallic: 0.95, roughness: 0.30, glow: 0.0)
        case .textil:
            return BodyPlan(torso: .capsule, torsoSize: SIMD3(0.14, 0.14, 0.14), head: .sphere,
                            headRadius: 0.06, limbCount: 2, spikeCount: 0, hasCrest: true,
                            metallic: 0.0, roughness: 0.95, glow: 0.0)
        case .glass:
            return BodyPlan(torso: .box, torsoSize: SIMD3(0.10, 0.16, 0.10), head: .sphere,
                            headRadius: 0.045, limbCount: 0, spikeCount: 5, hasCrest: false,
                            metallic: 0.10, roughness: 0.05, glow: 0.30)
        case .paper:
            return BodyPlan(torso: .box, torsoSize: SIMD3(0.15, 0.12, 0.04), head: .box,
                            headRadius: 0.045, limbCount: 2, spikeCount: 0, hasCrest: true,
                            metallic: 0.0, roughness: 0.85, glow: 0.0)
        case .fauna:
            return BodyPlan(torso: .capsule, torsoSize: SIMD3(0.13, 0.12, 0.13), head: .sphere,
                            headRadius: 0.065, limbCount: 4, spikeCount: 0, hasCrest: false,
                            metallic: 0.0, roughness: 0.88, glow: 0.0)
        case .snack:
            return BodyPlan(torso: .sphere, torsoSize: SIMD3(0.15, 0.12, 0.15), head: .sphere,
                            headRadius: 0.05, limbCount: 2, spikeCount: 0, hasCrest: false,
                            metallic: 0.0, roughness: 0.55, glow: 0.05)
        case .tech:
            return BodyPlan(torso: .box, torsoSize: SIMD3(0.12, 0.15, 0.06), head: .box,
                            headRadius: 0.05, limbCount: 2, spikeCount: 0, hasCrest: false,
                            metallic: 0.55, roughness: 0.25, glow: 0.45)
        case .ceramic:
            return BodyPlan(torso: .sphere, torsoSize: SIMD3(0.15, 0.11, 0.15), head: .sphere,
                            headRadius: 0.055, limbCount: 4, spikeCount: 0, hasCrest: false,
                            metallic: 0.0, roughness: 0.18, glow: 0.0)
        case .void:
            return BodyPlan(torso: .sphere, torsoSize: SIMD3(0.12, 0.14, 0.12), head: .sphere,
                            headRadius: 0.05, limbCount: 0, spikeCount: 8, hasCrest: false,
                            metallic: 0.20, roughness: 0.40, glow: 0.70)
        }
    }

    /// Word stems used to invent creature names. Deliberately language-neutral
    /// nonsense so that a name never needs translating.
    public var namePrefixes: [String] {
        switch self {
        case .aqua:    return ["Aqua", "Nerel", "Tidu", "Mizu", "Vela"]
        case .verdant: return ["Vira", "Folis", "Rimba", "Gerta", "Sylva"]
        case .ember:   return ["Pyra", "Bara", "Cindra", "Solen", "Ignis"]
        case .ferro:   return ["Ferro", "Kral", "Besi", "Magnos", "Vulk"]
        case .textil:  return ["Lume", "Kapa", "Woola", "Serat", "Plush"]
        case .glass:   return ["Kacha", "Vitri", "Prisma", "Lensa", "Kryo"]
        case .paper:   return ["Folio", "Kerta", "Sigil", "Rimma", "Codek"]
        case .fauna:   return ["Bulu", "Kero", "Nuzza", "Fenne", "Muri"]
        case .snack:   return ["Manis", "Gula", "Krum", "Bito", "Nomu"]
        case .tech:    return ["Volta", "Sirk", "Bytra", "Neon", "Pixa"]
        case .ceramic: return ["Tera", "Klei", "Porsa", "Ubin", "Grava"]
        case .void:    return ["Null", "Kabut", "Umbra", "Glitch", "Anon"]
        }
    }

    public static let nameSuffixes: [String] = [
        "lin", "mor", "zik", "ta", "phon", "dra", "kus", "vel", "nox", "ra",
        "buk", "sha", "tor", "wyn", "pik"
    ]
}
