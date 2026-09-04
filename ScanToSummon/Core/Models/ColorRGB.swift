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

    /// Quantises each channel into one of eight buckets.
    ///
    /// This is what makes a scan *stable*: two photos of the same blue mug will
    /// differ slightly in average colour, but almost always land in the same
    /// bucket, so they produce the same creature. Without this the "scan the
    /// same object twice, get the same creature" promise would not hold.
    public var bucketKey: String {
        let r = Int(red * 7.999)
        let g = Int(green * 7.999)
        let b = Int(blue * 7.999)
        return "\(r)\(g)\(b)"
    }

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
