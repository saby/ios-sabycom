//
//  SabycomService.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 27.09.2021.
//

import Foundation

protocol UserService {
    var appId: String? { get set }
    var pushToken: SabycomPushToken? { get set }
    
    var currentUserId: String? { get }
    
    func registerUser(_ user: SabycomUser)
    func registerAnonymousUser() -> SabycomUser
    func logout(completion: (() -> Void)?)
}

class UserServiceImpl: UserService {
    private (set) var user: SabycomUser? {
        set {
            if _user != newValue {
                _user = newValue
            }
        }
        get {
            return _user
        }
    }
    
    var appId: String? {
        set {
            if _appId != newValue {
                _appId = newValue
            }
        }
        get {
            return _appId
        }
    }
    
    var pushToken: SabycomPushToken? {
        set {
            if _pushToken != newValue {
                _pushToken = newValue
            }
        }
        get {
            return _pushToken
        }
    }
    
    private var _user: SabycomUser? {
        didSet {
            sendUserData()
        }
    }
    
    private var _appId: String? {
        didSet {
            sendUserData()
        }
    }
    
    private var _pushToken: SabycomPushToken? {
        didSet {
            sendUserData()
        }
    }
    
    var currentUserId: String? {
        userStorage.currentUserId
    }
    
    private let api: Api
    private let userStorage: UserStorage
    
    init(api: Api, userStorage: UserStorage) {
        self.api = api
        self.userStorage = userStorage
    }
    
    func registerUser(_ user: SabycomUser) {
        self.user = user
        
        userStorage.deleteAnonymousUser()
        userStorage.currentUserId = user.uuid
    }
    
    func registerAnonymousUser() -> SabycomUser {
        guard let anonymousUser = userStorage.anonymousUser else {
            let userId = UUID().uuidString
            
            let user = SabycomUser(uuid: userId)
            userStorage.saveAnonymousUser(user)
            userStorage.currentUserId = userId
            
            self.user = user
            
            return user
        }
        
        self.user = anonymousUser
        
        return anonymousUser
    }
    
    func logout(completion: (() -> Void)?) {
        sendUserData(unsubscribe: true) { [weak self] in
            self?.userStorage.currentUserId = nil
            
            completion?()
        }
    }
    
    private func sendUserData(unsubscribe: Bool = false, completion: (() -> Void)? = nil) {
        if let user = user, let appId = appId {
            api.registerUser(user, channedUUID: appId, pushToken: pushToken, unsubscribe: unsubscribe) { userId in
                completion?()
            }
        }
    }
}
