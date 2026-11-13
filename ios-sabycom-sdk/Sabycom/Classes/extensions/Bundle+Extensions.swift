//
//  Bundle+Extensions.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import Foundation

extension Bundle {
    class var mainSdk: Bundle {
        let bundle = Bundle.init(for: Sabycom.self)
        let bundleUrl = bundle.url(forResource: "Sabycom", withExtension: "bundle")
        return Bundle.init(url: bundleUrl!)!
    }
}
