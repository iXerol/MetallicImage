import MetallicImage
import UIKit

class ViewController: UITableViewController {
    let titles = ["Basic Features", "MPS Filters", "Extension Filters", "Combined Filters"]
    let effects: [[(name: String, properties: [(propertyName: String, min: Float, max: Float)])]] = [
        [("Photo", []), ("Camera", [])],
        [("Gaussian Blur", [("sigma", 0, 256)]), ("Box Blur", [("blurDiameter", 0, .infinity)]), ("Tent Blur", [("blurDiameter", 0, .infinity)]), ("Median Blur", [("blurDiameter", 3, 30)]), ("Area Max", [("kernelRadius", 0, 256)]), ("Area Min", [("kernelRadius", 0, 256)]), ("Lanczos Scale", [("scaleX", 0.1, 1), ("scaleY", 0.1, 1), ("translateX", -1000, 1000), ("translateY", -1000, 1000)]), ("Bilinear Scale", [("scaleX", 0, 1), ("scaleY", 0, 1), ("translateX", -1000, 1000), ("translateY", -1000, 1000)]), ("Sobel Edge Detection", []), ("Laplacian Edge Detection", [("bias", 0, 1)]), ("Threshold Binary", [("thresholdValue", 0, 1), ("maximumValue", 0, 1)])],
        [("Brightness", [("brightness", -1, 1)]), ("Saturation", [("saturation", 0, 2)]), ("Contrast", [("contrast", -1, 1)]), ("White Balance", [("temperature", 0, 10000), ("tint", -256, 256)]), ("Hue", [("hue", -256, 256)]), ("Sharpen", [("sharpness", -10, 10)])],
        [("Contrast => Gaussian Blur", []), ("Area Max => Sharpen", []), ("Hue => Brightness => Box Blur", [])]
    ]

    init() {
        super.init(style: .grouped)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = NSLocalizedString("Image Effects", comment: "Title of Image Effects")
        navigationController?.navigationBar.prefersLargeTitles = true
    }
}

// MARK: UITableViewDataSource

extension ViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return titles.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return effects[section].count
    }
}

// MARK: UITableViewDelegate

extension ViewController {
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return NSLocalizedString(titles[section], comment: "Section Titles")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .default, reuseIdentifier: "FilterOptionCell")
        cell.textLabel?.text = NSLocalizedString(effects[indexPath.section][indexPath.row].name, comment: "Image Effect Names")
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let filter: BasicFilter?
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                filter = nil
            case 1:
                filter = nil
                let vc = CameraViewController()
                navigationController?.pushViewController(vc, animated: true)
                return
            default:
                fatalError("Undefined row")
            }
        case 1:
            switch indexPath.row {
            case 0:
                filter = GaussianBlur()
            case 1:
                filter = BoxBlur()
            case 2:
                filter = TentBlur()
            case 3:
                filter = MedianBlur()
            case 4:
                filter = AreaMax()
            case 5:
                filter = AreaMin()
            case 6:
                filter = LanczosScale()
            case 7:
                filter = BilinearScale()
            case 8:
                filter = SobelEdgeDetection()
            case 9:
                filter = LaplacianEdgeDetection()
            case 10:
                filter = ThresholdBinary()
            default:
                fatalError("Undefined row")
            }
        case 2:
            switch indexPath.row {
            case 0:
                filter = BrightnessAdjustment()
            case 1:
                filter = SaturationAdjustment()
            case 2:
                filter = ContrastAdjustment()
            case 3:
                filter = WhiteBalance()
            case 4:
                filter = HueAdjustment()
            case 5:
                filter = Sharpen()
            default:
                fatalError("Undefined row")
            }
        case 3:
            let secondFilter: BasicFilter
            switch indexPath.row {
            case 0:
                filter = ContrastAdjustment()
                secondFilter = GaussianBlur()
                filter?.setValue(-0.5, forKey: "contrast")
                secondFilter.setValue(50, forKey: "sigma")
            case 1:
                filter = AreaMax()
                secondFilter = Sharpen()
                filter?.setValue(35, forKey: "kernelRadius")
                secondFilter.setValue(10, forKey: "sharpness")
            case 2:
                filter = HueAdjustment()
                secondFilter = BrightnessAdjustment()
                filter?.setValue(100, forKey: "hue")
                secondFilter.setValue(0.5, forKey: "brightness")
                let thirdFilter = BoxBlur()
                thirdFilter.blurDiameter = 50
                let imageVC = MultiFilterImageViewController(filters: [filter!, secondFilter, thirdFilter])
                navigationController?.pushViewController(imageVC, animated: true)
                return
            default:
                fatalError("Undefined row")
            }
            let imageVC = MultiFilterImageViewController(filters: [filter!, secondFilter])
            navigationController?.pushViewController(imageVC, animated: true)
            return
        default:
            fatalError("Undefined section")
        }
        let imageVC = ImageViewController(filter: filter, properties: effects[indexPath.section][indexPath.row].properties)
        navigationController?.pushViewController(imageVC, animated: true)
    }
}
