//
//  URLCreator.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 08.10.2021.
//

import Foundation

class URLCreator {
    private let host: SabycomHost
    private let path: String
    
    init(host: SabycomHost.HostType, path: String) {
        self.host = SabycomHost(hostType: host, appId: nil)
        self.path = path
    }
    
    func url() -> String {
        return host.createApiUrl() + path
    }
}
