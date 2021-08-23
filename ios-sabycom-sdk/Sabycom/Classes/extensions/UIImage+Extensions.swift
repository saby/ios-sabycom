//
//  UIImage+Extensions.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import Foundation

extension UIImage {
    class func named(_ name: String) -> UIImage {
        return UIImage.init(named: name, in: Bundle.mainSdk, compatibleWith: nil)!
    }
}
