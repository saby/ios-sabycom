//
//  UserStorage.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 08.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Sabycom

protocol UserStorage {
    var currentUser: SabycomUser? { get }
    
    func saveUser(_ user: SabycomUser)
    
    func deleteCurrentUser()
}

class UserStorageImpl: UserStorage {
    private enum Constants {
        enum Keys {
            static let currentUser = "SabycomConfigurationInteractor.CurrentUser"
        }
    }
    
    var currentUser: SabycomUser? {
        guard let data = UserDefaults.standard.data(forKey: Constants.Keys.currentUser) else {
            return nil
        }
        
        let user = try? JSONDecoder().decode(SabycomUser.self, from: data)
        return user
    }
    
    func saveUser(_ user: SabycomUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Constants.Keys.currentUser)
            userDidChange()
        }
    }
    
    func deleteCurrentUser() {
        UserDefaults.standard.removeObject(forKey: Constants.Keys.currentUser)
        userDidChange()
    }
    
    private func userDidChange() {
        NotificationCenter.default.post(name: .UserStorageDidChange, object: nil)
    }
}

extension NSNotification.Name {
    static let UserStorageDidChange = NSNotification.Name(rawValue: "UserStorage.userDidChange")
}

