//
//  SabycomHost.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import Foundation

struct SabycomHost {
    private static let baseHostString = "consultant.sbis.ru/consultant/"
    private static let baseApiUrlString = "consultant.sbis.ru/service/restapi/"
    
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
    let appId: String?

    
    func createURL() -> String {
        let appId = self.appId ?? ""
        let urlString = "https://\(hostType.prefix)\(SabycomHost.baseHostString)\(appId)"
        return urlString
    }
    
    func createApiUrl() -> String {
        let urlString = "https://\(hostType.prefix)\(SabycomHost.baseApiUrlString)"
        return urlString
    }
}
