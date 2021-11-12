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
    
    private let configurationService: ConfigurationService
    
    init(userStorage: UserStorage = DIContainer.shared.resolve(type: UserStorage.self)!,
         configurationService: ConfigurationService = DIContainer.shared.resolve(type: ConfigurationService.self)!) {
        self.userStorage = userStorage
        self.configurationService = configurationService
    }
    
    func saveAppId(_ appId: String) {
        configurationService.saveAppId(appId)
    }
    
    func getCurrentAppId() -> String? {
        configurationService.getCurrentAppId()
    }
    
    func saveHost(_ hostType: SabycomHost.HostType) {
        configurationService.saveHost(hostType)
    }
    
    func getCurrentHostType() -> SabycomHost.HostType? {
        configurationService.getCurrentHostType()
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
    
    
}
