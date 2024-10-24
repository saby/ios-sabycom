//
//  ConfigService.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 12.11.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Sabycom

protocol ConfigurationService {
    func saveAppId(_ appId: String)
    func getCurrentAppId() -> String?
    func saveHost(_ hostType: SabycomHost.HostType)
    func getCurrentHostType() -> SabycomHost.HostType?
}

class ConfigurationServiceImpl: ConfigurationService {
    func saveAppId(_ appId: String) {
        UserDefaults.standard.set(appId, forKey: Constants.Keys.currentAppId)
        configurationDidChange()
    }
    
    func getCurrentAppId() -> String? {
        UserDefaults.standard.string(forKey: Constants.Keys.currentAppId)
    }
    
    func saveHost(_ hostType: SabycomHost.HostType) {
        UserDefaults.standard.set(hostType.rawValue, forKey: Constants.Keys.currentHost)
        configurationDidChange()
    }
    
    func getCurrentHostType() -> SabycomHost.HostType? {
        guard let hostTypeString = UserDefaults.standard.string(forKey: Constants.Keys.currentHost) else {
            return nil
        }
        
        return SabycomHost.HostType(rawValue: hostTypeString)
    }
    
    private func configurationDidChange() {
        NotificationCenter.default.post(name: .ConfigurationServiceConfigurationDidChange, object: nil)
    }
    
    private enum Constants {
        enum Keys {
            static let currentAppId = "SabycomConfigurationInteractor.CurrentAppId"
            static let currentHost = "SabycomConfigurationInteractor.CurrentHost"
        }
    }
}

extension NSNotification.Name {
    static let ConfigurationServiceConfigurationDidChange = NSNotification.Name(rawValue: "ConfigurationService.configurationDidChange")
}

