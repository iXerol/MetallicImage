import CoreGraphics

extension CGSize {
    func flipped() -> CGSize {
        return CGSize(width: height, height: width)
    }
}
