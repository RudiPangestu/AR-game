import CoreVideo
import Foundation
import ImageIO
import Vision

/// Wraps Vision's built-in image classifier.
///
/// `VNClassifyImageRequest` is used rather than a bundled Core ML model on
/// purpose: it ships with the OS, covers ~1300 everyday categories, costs
/// nothing in app size, and needs no download on first launch.
struct VisionClassifier {

    /// How much of the frame counts as "what the player is pointing at".
    /// The reticle on screen is drawn to match this box, so the player can see
    /// exactly what is being read.
    static let regionOfInterest = CGRect(x: 0.3, y: 0.3, width: 0.4, height: 0.4)

    func classify(
        pixelBuffer: CVPixelBuffer,
        orientation: CGImagePropertyOrientation
    ) throws -> [ScanObservation] {
        let request = VNClassifyImageRequest()
        request.regionOfInterest = Self.regionOfInterest

        let handler = VNImageRequestHandler(
            cvPixelBuffer: pixelBuffer,
            orientation: orientation,
            options: [:]
        )
        try handler.perform([request])

        guard let results = request.results else { return [] }

        return results
            .filter { $0.confidence > 0.01 }
            .sorted { $0.confidence > $1.confidence }
            .prefix(10)
            .map { ScanObservation(label: $0.identifier, confidence: Double($0.confidence)) }
    }
}
