//
//  UserStorage.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 22.11.2021.
//

import Foundation

protocol UserStorage {
    var anonymousUser: SabycomUser? { get }
    
    func saveAnonymousUser(_ user: SabycomUser)
    
    func deleteAnonymousUser()
}

class UserStorageImpl: UserStorage {
    private enum Constants {
        enum Keys {
            static let currentUser = "Sabycom.AnonymousUser"
        }
    }
    
    var anonymousUser: SabycomUser? {
        guard let data = UserDefaults.standard.data(forKey: Constants.Keys.currentUser) else {
            return nil
        }
        
        let user = try? JSONDecoder().decode(SabycomUser.self, from: data)
        return user
    }
    
    func saveAnonymousUser(_ user: SabycomUser) {
        if let data = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(data, forKey: Constants.Keys.currentUser)
        }
    }
    
    func deleteAnonymousUser() {
        UserDefaults.standard.removeObject(forKey: Constants.Keys.currentUser)
    }
}
