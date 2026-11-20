//
//  SabycomInteractor.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import Foundation

class SabycomInteractor {
    let host: SabycomHost
    
    let appId: String
    
    private (set) var user: SabycomUser
    
    private var lastUsedUrl: URL? {
        get {
            UserDefaults.standard.url(forKey: "SabycomWidget.LastUsedURL")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "SabycomWidget.LastUsedURL")
        }
    }
    
    init(host: SabycomHost, appId: String, user: SabycomUser) {
        self.host = host
        self.appId = appId
        self.user = user
    }
    
    func getUrl() -> URL? {
        let url = host.createURL()
        let defaultUrl = URL(string: url)
        guard var urlComponents = URLComponents(string: url) else {
            return defaultUrl
        }
        
        let userInfo: [String: String] = [
            "id" : user.uuid,
            "service_id" : appId
        ]
        
        let params: [String: Any] = ["ep": userInfo]
        
        guard let paramsData = try? JSONSerialization.data(withJSONObject: params, options: [.sortedKeys]) else {
            return defaultUrl
        }
        
        guard let jsonString = String(data: paramsData, encoding: .utf8)?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return defaultUrl
        }
        
        guard let p = jsonString.data(using: .utf8)?.base64EncodedString() else {
            return defaultUrl
        }

        urlComponents.queryItems = [URLQueryItem(name: "p", value: p)]
        let resultUrl = urlComponents.url
        
        if let lastUsedUrl = lastUsedUrl, lastUsedUrl != resultUrl {
            deleteCookies(for: lastUsedUrl)
        }
        
        lastUsedUrl = resultUrl
        return resultUrl
    }
    
    func updateUser(_ user: SabycomUser) {
        self.user = user
    }
    
    private func deleteCookies(for url: URL) {
        if let cookies = HTTPCookieStorage.shared.cookies(for: url.absoluteURL) {
            cookies.forEach {
                HTTPCookieStorage.shared.deleteCookie($0)
            }
        }
    }
}
