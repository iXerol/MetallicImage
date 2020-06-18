import UIKit

class NavigationController: UINavigationController {
    var autoRotate: Bool = true

    override var shouldAutorotate: Bool {
        return autoRotate
    }
}
