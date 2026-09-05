//
//  ConfigurationInteractor.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 07.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Foundation
import Sabycom

class ConfigurationInteractor {
    private let userStorage: UserStorage
    
    init(userStorage: UserStorage = DIContainer.shared.resolve(type: UserStorage.self)!) {
        self.userStorage = userStorage
    }
    
    func saveAppId(_ appId: String) {
        UserDefaults.standard.set(appId, forKey: Constants.Keys.currentAppId)
    }
    
    func getCurrentAppId() -> String? {
        UserDefaults.standard.string(forKey: Constants.Keys.currentAppId)
    }
    
    func saveHost(_ hostType: SabycomHost.HostType) {
        UserDefaults.standard.set(hostType.rawValue, forKey: Constants.Keys.currentHost)
    }
    
    func getCurrentHostType() -> SabycomHost.HostType? {
        guard let hostTypeString = UserDefaults.standard.string(forKey: Constants.Keys.currentHost) else {
            return nil
        }
        
        return SabycomHost.HostType(rawValue: hostTypeString)
    }
    
    func getCurrentUser() -> SabycomUser? {
        return userStorage.currentUser
    }
    
    func getCurrentUserOrCreateEmpty() -> SabycomUser {
        guard let user = userStorage.currentUser else {
            let userId = UUID().uuidString
            
            let user = SabycomUser(uuid: userId)
            userStorage.saveUser(user)
            
            return user
        }
        return user
    }
    
    func deleteCurrentUser() {
        userStorage.deleteCurrentUser()
    }
    
    private enum Constants {
        enum Keys {
            static let currentAppId = "SabycomConfigurationInteractor.CurrentAppId"
            static let currentHost = "SabycomConfigurationInteractor.CurrentHost"
        }
    }
}
