//
//  Localization.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 21.12.2021.
//

import Foundation

class Localization {
    static let shared = Localization()
    
    private let bundle: Bundle
    
    init() {
        guard let path = Bundle.mainSdk.path(forResource: "Localization", ofType: "bundle") else {
            bundle = Bundle.mainSdk
            return
        }
        
        bundle = Bundle(path: path)!
    }
    
    func text(forKey key: String) -> String {
        let text = bundle.localizedString(forKey: key, value: nil, table: nil)
        return text
    }
}
