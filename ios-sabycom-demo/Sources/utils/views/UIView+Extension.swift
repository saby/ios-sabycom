//
//  UIView+Extension.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 21.10.2022.
//  Copyright © 2022 Tensor. All rights reserved.
//

import UIKit

extension UIView {
    func makeAccessible(with identifier: String) {
        accessibilityIdentifier = identifier
        isAccessibilityElement = true
    }
}
