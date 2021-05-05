//
//  NavigationController.swift
//  MetallicImageDemo_iOS
//
//  Created by Xerol Wong on 5/13/20.
//  Copyright © 2020 Xerol Wong. All rights reserved.
//

import UIKit

class NavigationController: UINavigationController {
    var autoRotate: Bool = true

    override var shouldAutorotate: Bool {
        return autoRotate
    }
}
