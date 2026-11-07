//
//  SabycomHost.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import Foundation

// Хост, к которому подключается виджет
public struct SabycomHost {
    private static let baseHostString = "consultant.sbis.ru/consultant/"
    private static let baseApiUrlString = "consultant.sbis.ru/service/restapi/"
    
    public enum HostType: String, CaseIterable {
        case prod
        case fix
        case test
        case pretest
        case dev
        
        var prefix: String {
            switch self {
            case .prod:
                return ""
            case .fix:
                return "fix-"
            case .test:
                return "test-"
            case .pretest:
                return "pre-test-"
            case .dev:
                return "dev-"
            }
        }
        
        // Название для отображения
        public var visibleName: String {
            return prefix + "consultant"
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
