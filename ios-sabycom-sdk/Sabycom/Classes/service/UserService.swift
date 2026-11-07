//
//  SabycomService.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 27.09.2021.
//

import Foundation

protocol UserServiceObservable: AnyObject {
    func userInfoSent()
}

protocol UserService {
    var appId: String? { get set }
    var pushToken: SabycomPushToken? { get set }
    
    var notification: SabycomNotificationModel? { get set }
    
    var registeredAsAnonymous: Bool { get }
    var userInfoSent: Bool { get }
    
    var currentUserId: String? { get }
    
    func registerUser(_ user: SabycomUser)
    func registerAnonymousUser() -> SabycomUser
    func logout(completion: (() -> Void)?)
    
    func registerObserver(_ observer: UserServiceObservable)
    func unregisterObserver(_ observer: UserServiceObservable)
    
    func getNotificationAndClear() -> SabycomNotificationModel?
}

class UserServiceImpl: UserService {
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
    
    var notification: SabycomNotificationModel?
    
    var registeredAsAnonymous: Bool {
        return userStorage.anonymousUser != nil
    }
    
    var userInfoSent: Bool {
        get {
            UserDefaults.standard.bool(forKey: "SabycomUser.InfoSent")
        }
        set {
            if newValue {
                notifyObserversUserInfoSent()
            }
            UserDefaults.standard.set(newValue, forKey: "SabycomUser.InfoSent")
        }
    }
    
    private let queue = DispatchQueue(label: "UserServiceQueue", qos: .userInitiated)

    private var observers: [Weak<UserServiceObservable>] = []
    private var strongObservers: [UserServiceObservable] {
        return observers.compactMap { $0.value }
    }
    
    private (set) var user: SabycomUser? {
        set {
            if _user != newValue {
                if _user != nil {
                    logout(clearUser: false, completion: nil)
                }
                _user = newValue
            }
        }
        get {
            return _user
        }
    }
    
    private var _user: SabycomUser? {
        didSet {
            userInfoSent = false
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
    private let reachabilityService: ReachabilityService
    
    init(api: Api, userStorage: UserStorage, reachabilityService: ReachabilityService) {
        self.api = api
        self.userStorage = userStorage
        self.reachabilityService = reachabilityService
        
        reachabilityService.registerObserver(self)
    }
    
    deinit {
        reachabilityService.unregisterObserver(self)
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
        logout(clearUser: true, completion: completion)
    }
    
    func getNotificationAndClear() -> SabycomNotificationModel? {
        defer {
            self.notification = nil
        }
        
        return notification
    }
    func registerObserver(_ observer: UserServiceObservable) {
        queue.async { [self] in
            if self.observers.contains(where: { $0.value === observer }) {
                return
            }
            self.observers.append(Weak(value: observer))
        }
    }

    func unregisterObserver(_ observer: UserServiceObservable) {
        queue.sync {
            observers = observers.filter { $0.value !== observer }
        }
    }
    
    private func logout(clearUser: Bool, completion: (() -> Void)?) {
        sendUserData(unsubscribe: true) { [weak userStorage] in
            if clearUser {
                userStorage?.currentUserId = nil
            }
            
            completion?()
        }
    }
    
    private func notifyObserversUserInfoSent() -> Void {
        queue.sync {
            removeNilObservers()

            for observer in strongObservers {
                observer.userInfoSent()
            }
        }
    }

    private func removeNilObservers() {
        observers = observers.filter { nil != $0.value }
    }
    
    private func sendUserData(unsubscribe: Bool = false, completion: (() -> Void)? = nil) {
        if let user = user, let appId = appId, reachabilityService.isAvailable {
            api.registerUser(user, channedUUID: appId, pushToken: pushToken, unsubscribe: unsubscribe) { [weak self] userId in
                self?.userInfoSent = true
                completion?()
            }
        } else {
            completion?()
        }
    }
}

extension UserServiceImpl: ReachabilityObservable {
    func reachabilityChanged(_ available: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            if !self.userInfoSent {
                self.sendUserData()
            }
        }
    }
}
