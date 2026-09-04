import Foundation

/// A SplitMix64 generator.
///
/// Every random decision in the game flows through this so that battles and
/// creature stats can be replayed exactly from a seed.
public struct SeededGenerator: RandomNumberGenerator, Equatable {
    private var state: UInt64

    public init(seed: UInt64) {
        self.state = seed
    }

    public mutating func next() -> UInt64 {
        state = state &+ 0x9E37_79B9_7F4A_7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
        z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
        return z ^ (z >> 31)
    }

    /// A `Double` in 0..<1.
    public mutating func unitDouble() -> Double {
        Double(next() >> 11) * (1.0 / 9_007_199_254_740_992.0)
    }

    /// A `Double` in `range`.
    public mutating func double(in range: ClosedRange<Double>) -> Double {
        range.lowerBound + unitDouble() * (range.upperBound - range.lowerBound)
    }
}

public enum StableHash {
    /// FNV-1a, 64-bit.
    ///
    /// Swift's own `hashValue` is seeded per process, so it produces a
    /// different number every time the app launches. Using it here would break
    /// the core promise that scanning the same object always yields the same
    /// creature — so we hash by hand.
    public static func fnv1a(_ string: String) -> UInt64 {
        var hash: UInt64 = 0xcbf2_9ce4_8422_2325
        for byte in string.utf8 {
            hash ^= UInt64(byte)
            hash = hash &* 0x0000_0100_0000_01B3
        }
        return hash
    }
}
