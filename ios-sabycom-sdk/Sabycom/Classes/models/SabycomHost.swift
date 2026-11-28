//
//  SabycomHost.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import Foundation

struct SabycomHost {
    private static let baseHostString = "consultant.sbis.ru/consultant/"
    
    enum HostType {
        case prod
        case fix
        case test
        
        var prefix: String {
            switch self {
            case .prod:
                return ""
            case .fix:
                return "fix-"
            case .test:
                return "test-"
            }
        }
    }
    
    let hostType: HostType
    let appId: String
    let apiKey: String

    
    func createURL() -> URL? {
        let urlString = "https://\(hostType.prefix)\(SabycomHost.baseHostString)\(appId)"
        return URL(string: urlString)
    }
}
