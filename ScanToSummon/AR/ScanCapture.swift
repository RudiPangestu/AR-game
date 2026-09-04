import Foundation

/// Everything a summon needs from one camera frame.
///
/// Declared outside the ARKit-only sources so that the Simulator build, which
/// has no camera, can still produce one of these and exercise the rest of the
/// app.
struct ScanCapture {
    let observations: [ScanObservation]
    let averageColor: ColorRGB
}

/// What to tell the player about the AR session right now.
///
/// Declared here rather than inside `ARScanController` so the Scan screen can
/// switch over it without conditional compilation.
enum ScanHint: Equatable {
    case starting
    case moveAround
    case tooDark
    case ready
}
