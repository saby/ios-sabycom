//
//  SabycomService.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 12.11.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import UIKit
import Sabycom
import Foundation

protocol SabycomService {
    var unreadConversationCount: Int { get }
    
    func show(on viewController: UIViewController)
    func registerAnonymousUser()
    func clearAnonymousUser()
    func configureSabycom()
    func logout()
    
    func isSabycomPushNotification(info: [AnyHashable: Any]) -> Bool
    func handlePushNotification(info: [AnyHashable: Any], parentView: UIView)
}
class SabycomServiceImpl: SabycomService {
    var unreadConversationCount: Int {
        SabycomSDK.unreadConversationCount
    }
    
    private let configurationService: ConfigurationService
    private var userStorage: UserStorage
    private let notififationService: NotificationService
    
    private var configurationServiceObserver: Any?
    private var userStorageObserver: Any?
    private var notificationServiceObserver: Any?
    
    init(configurationService: ConfigurationService = DIContainer.shared.resolve(type: ConfigurationService.self)!,
         userStorage: UserStorage = DIContainer.shared.resolve(type: UserStorage.self)!,
         notificationService: NotificationService = DIContainer.shared.resolve(type: NotificationService.self)!) {
        self.configurationService = configurationService
        self.userStorage = userStorage
        self.notififationService = notificationService
        
        configurationServiceObserver = NotificationCenter.default.addObserver(
            forName: .ConfigurationServiceConfigurationDidChange,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.initializeSabycom()
            }
        
        userStorageObserver = NotificationCenter.default.addObserver(
            forName: .UserStorageDidChange,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.registerSabycomUser()
            }
        
        notificationServiceObserver = NotificationCenter.default.addObserver(
            forName: .NotificationServiceDidChange,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.registerSabycomNotifications()
            }
        
        configureSabycom()
    }
    
    deinit {
        if let configurationServiceObserver = configurationServiceObserver {
            NotificationCenter.default.removeObserver(configurationServiceObserver)
        }
        
        if let userStorageObserver = userStorageObserver {
            NotificationCenter.default.removeObserver(userStorageObserver)
        }
        
        if let notificationServiceObserver = notificationServiceObserver {
            NotificationCenter.default.removeObserver(notificationServiceObserver)
        }
    }
    
    func registerAnonymousUser() {
        userStorage.registeredAsAnonymous = true
        SabycomSDK.registerAnonymousUser()
    }
    
    func clearAnonymousUser() {
        userStorage.registeredAsAnonymous = false
    }
    
    func show(on viewController: UIViewController) {
        configureSabycom()
        SabycomSDK.show(on: viewController)
    }
    
    func configureSabycom() {
        initializeSabycom()
        
        if userStorage.registeredAsAnonymous {
            registerAnonymousUser()
        } else {
            registerSabycomUser()
        }
        registerSabycomNotifications()
    }
    
    func logout() {
        SabycomSDK.logout()
    }
    
    func isSabycomPushNotification(info: [AnyHashable: Any]) -> Bool {
        SabycomSDK.isSabycomPushNotification(info: info)
    }
    
    func handlePushNotification(info: [AnyHashable: Any], parentView: UIView) {
        SabycomSDK.handlePushNotification(info: info, parentView: parentView)
    }
    
    private func initializeSabycom() {
        if let appId = configurationService.getCurrentAppId(), let host = configurationService.getCurrentHostType() {
            SabycomSDK.initialize(appId: appId, host: host)
        }
    }
    
    private func registerSabycomUser() {
        if let user = userStorage.currentUser {
            SabycomSDK.registerUser(user)
        }
    }
    
    private func registerSabycomNotifications() {
        if let deviceToken = notififationService.deviceToken {
            var tokenType = SabycomAPNSTokenType.prod
            
            #if DEBUG
                tokenType = .sandbox
            #endif
            
            SabycomSDK.registerForPushNotifications(with: deviceToken, tokenType: tokenType)
        }
    }
}
