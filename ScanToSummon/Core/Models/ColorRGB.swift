import Foundation

/// A plain colour value so that `Core` never has to import UIKit or SwiftUI.
/// Components are in 0...1.
public struct ColorRGB: Codable, Equatable, Sendable {
    public var red: Double
    public var green: Double
    public var blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = min(max(red, 0), 1)
        self.green = min(max(green, 0), 1)
        self.blue = min(max(blue, 0), 1)
    }

    public static let neutral = ColorRGB(red: 0.6, green: 0.6, blue: 0.62)

    // Colour deliberately plays no part in a creature's identity — it only
    // tints the body. An earlier version bucketed each channel and folded that
    // into the signature, which CI caught as a real defect: an object whose
    // average colour sits near a bucket edge (0.50 with eight buckets, say)
    // flips between two buckets on consecutive scans and mints two different
    // creatures from one mug. Every quantisation has edges, so no bucket count
    // fixes it. Dropping colour from identity makes "same object, same
    // creature" unconditionally true instead of usually true.

    /// A more saturated version, used so creatures never look washed out when
    /// the scanned object is a dull grey.
    public func vivid() -> ColorRGB {
        let maxC = max(red, max(green, blue))
        let minC = min(red, min(green, blue))
        let chroma = maxC - minC

        // Nearly grey: nudge it toward a slate blue so the creature still reads
        // as a creature rather than a lump of concrete.
        guard chroma > 0.08 else {
            return ColorRGB(red: 0.42, green: 0.48, blue: 0.62)
        }

        let mid = (maxC + minC) / 2
        let boost = 1.45
        return ColorRGB(
            red: mid + (red - mid) * boost,
            green: mid + (green - mid) * boost,
            blue: mid + (blue - mid) * boost
        )
    }
}
