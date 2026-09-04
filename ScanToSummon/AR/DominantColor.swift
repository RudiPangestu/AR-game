import CoreImage
import CoreVideo
import Foundation

/// Reads the average colour of the middle of the frame.
///
/// This is what gives a creature the colour of the object it came from, and it
/// is half of the scan's identity: the same object at the same colour always
/// produces the same creature.
struct DominantColorExtractor {

    /// No colour management — we want the same numbers on every device so that
    /// a signature computed on one iPhone matches another.
    private let context = CIContext(options: [.workingColorSpace: NSNull()])

    func averageColor(
        pixelBuffer: CVPixelBuffer,
        region: CGRect = VisionClassifier.regionOfInterest
    ) -> ColorRGB {
        let image = CIImage(cvPixelBuffer: pixelBuffer)
        let extent = image.extent
        guard extent.width > 0, extent.height > 0 else { return .neutral }

        let sampleRect = CGRect(
            x: extent.origin.x + extent.width * region.origin.x,
            y: extent.origin.y + extent.height * region.origin.y,
            width: extent.width * region.width,
            height: extent.height * region.height
        )

        guard let filter = CIFilter(
            name: "CIAreaAverage",
            parameters: [
                kCIInputImageKey: image,
                kCIInputExtentKey: CIVector(cgRect: sampleRect)
            ]
        ), let output = filter.outputImage else {
            return .neutral
        }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            output,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: CGColorSpaceCreateDeviceRGB()
        )

        return ColorRGB(
            red: Double(bitmap[0]) / 255.0,
            green: Double(bitmap[1]) / 255.0,
            blue: Double(bitmap[2]) / 255.0
        )
    }
}
