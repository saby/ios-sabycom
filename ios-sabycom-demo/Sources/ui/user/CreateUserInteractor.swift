//
//  CreateUserInteractor.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 08.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Sabycom
import Foundation

class CreateUserInteractor {
    private let userStorage: UserStorage
    
    init(userStorage: UserStorage = DIContainer.shared.resolve(type: UserStorage.self)!) {
        self.userStorage = userStorage
    }
    
    func getCurrentUser() -> SabycomUser? {
        return userStorage.currentUser
    }
    
    func createOrUpdateUser(name: String, surname: String, email: String?, phone: String?) {
        let userId = getCurrentUser()?.uuid ?? UUID().uuidString
        
        let user = SabycomUser(uuid: userId,
                               name: name,
                               surname: surname,
                               email: email,
                               phone: phone)
        userStorage.saveUser(user)
    }
}
