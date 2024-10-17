//
//  UserStorage.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 22.11.2021.
//

import Foundation

protocol UserStorage: AnyObject {
    var anonymousUser: SabycomUser? { get }
    
    var currentUserId: String? { get set }
    
    func saveAnonymousUser(_ user: SabycomUser)
    
    func deleteAnonymousUser()
}

class UserStorageImpl: UserStorage {
    private enum Constants {
        enum Keys {
            static let anonymousUser = "Sabycom.AnonymousUser"
            static let currentUser = "Sabycom.CurrentUserId"
        }
    }
    
    var currentUserId: String? {
        get {
            UserDefaults.standard.string(forKey: Constants.Keys.currentUser)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Constants.Keys.currentUser)
        }
    }
    
    var anonymousUser: SabycomUser? {
        guard let data = UserDefaults.standard.data(forKey: Constants.Keys.anonymousUser) else {
            return nil
        }
        
        let user = try? JSONDecoder().decode(SabycomUser.self, from: data)
        return user
    }
    
    func saveAnonymousUser(_ user: SabycomUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Constants.Keys.anonymousUser)
        }
    }
    
    func deleteAnonymousUser() {
        UserDefaults.standard.removeObject(forKey: Constants.Keys.anonymousUser)
    }
}
