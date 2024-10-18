//
//  SabycomInteractor.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import Foundation

class SabycomInteractor {
    private let host: SabycomHost
    
    init(host: SabycomHost) {
        self.host = host
    }
    
    func getConfig() -> SabycomConfig {
        return SabycomConfig(title: "Sabycom", headerColor: .blue)
    }
    
    func getUrl() -> URL? {
        return host.createURL()
    }
}
