# MetallicImage

![Swift](https://img.shields.io/badge/Swift-5.3%2B-orange) ![Platform](https://img.shields.io/badge/platforms-iOS%209.0%2B%20%7C%20macOS%2010.11%2B%20%7C%20tvOS%209.0%2B-green)

MetallicImage is an Image Processing Framework on Apple Platforms using Metal and written in Swift.

## Usage

Import MetallicImage Library.

``` Swift
import MetallicImage
```

Declare input, output and filter(s).

``` Swift
let picture = PictureInput(image: image) // image is an instance of UIImage or NSImage
let imageView = ImageView(frame: .zero)
let filter = GaussianBlur()
```

Use `=>` operator chaining to connect input, output and filters.

``` Swift
picture => filter => imageView
```

## Installation

### Using [Swift Package Manager](https://swift.org/package-manager/):

**Swift 5.3 (Xcode 12.0) is REQUIRED to build MetallicImage.**
To integrate Metallic Image into your Xcode project using Swift Package Manager, add it to the dependencies value of your `Package.swift`:

``` Swift
dependencies: [
    .package(url: "https://github.com/iXerol/MetallicImage.git", .upToNextMajor(from: "0.1.0"))
]
```

### Manually

Without using dependency managers, you can integrate MetallicImage into your project manually.

Add files in `framework/MetallicImage` directory to your project.

## License

MetallicImage is released under the MIT license. See `LICENSE` for details.
