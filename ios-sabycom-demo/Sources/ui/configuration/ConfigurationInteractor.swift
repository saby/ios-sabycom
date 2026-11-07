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
    
    private let sabycomService: SabycomService
    
    init(userStorage: UserStorage = DIContainer.shared.resolve(type: UserStorage.self)!,
         configurationService: ConfigurationService = DIContainer.shared.resolve(type: ConfigurationService.self)!,
         sabycomService: SabycomService = DIContainer.shared.resolve(type: SabycomService.self)!) {
        self.userStorage = userStorage
        self.configurationService = configurationService
        self.sabycomService = sabycomService
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
    
    func deleteCurrentUser() {
        userStorage.deleteCurrentUser()
        sabycomService.logout()
    }
    
    func registerAnonymousUser() {
        sabycomService.registerAnonymousUser()
    }
    
    func clearAnonymousUser() {
        sabycomService.clearAnonymousUser()
    }
}
