//
//  SabycomService.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 27.09.2021.
//

import Foundation

protocol UserService {
    var user: SabycomUser? { get set }
    var appId: String? { get set }
    var pushToken: String? { get set }
    
    func updateUser()
}

class UserServiceImpl: UserService {
    
    var user: SabycomUser? {
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
    
    var pushToken: String? {
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
            updateUser()
        }
    }
    
    private var _appId: String? {
        didSet {
            updateUser()
        }
    }
    
    private var _pushToken: String? {
        didSet {
            updateUser()
        }
    }
    
    private let api: Api
    
    init(api: Api) {
        self.api = api
    }
    
    func updateUser() {
        if let user = user, let appId = appId {
            api.registerUser(user, channedUUID: appId, pushToken: pushToken, completion: nil)
        }
    }
}
