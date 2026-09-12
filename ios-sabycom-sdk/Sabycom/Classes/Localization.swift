//
//  Localization.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 21.12.2021.
//

import Foundation

class Localization {
    enum Key: String {
        case errorTitle = "ErrorTitle"
        case okButtonTitle = "OkButtonTitle"
        case networkNotAvailable = "NetworkNotAvailableMessage"
        case networkError = "NetworkErrorMessage"
    }
    static let shared = Localization()
    
    private let bundle: Bundle
    
    init() {
        guard let path = Bundle.mainSdk.path(forResource: "Localization", ofType: "bundle") else {
            bundle = Bundle.mainSdk
            return
        }
        
        bundle = Bundle(path: path)!
    }
    
    func text(forKey key: Key) -> String {
        let text = bundle.localizedString(forKey: key.rawValue, value: nil, table: nil)
        return text
    }
}
