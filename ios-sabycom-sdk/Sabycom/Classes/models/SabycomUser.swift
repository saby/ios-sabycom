//
//  SabycomUser.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 10.08.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Foundation

/// Модель пользователя
public struct SabycomUser: Codable, Equatable {
    /// Уникальный идентификатор пользователя
    public let uuid: String
    
    /// Имя пользователя
    public let name: String?
    
    /// Фамилия пользователя
    public let surname: String?
    
    /// Email пользователя
    public let email: String?
    
    /// Телефон пользователя
    public let phone: String?
    
    public init(uuid: String,
                name: String? = nil,
                surname: String? = nil,
                email: String? = nil,
                phone: String? = nil) {
        self.uuid = uuid
        self.name = name
        self.surname = surname
        self.email = email
        self.phone = phone
    }
    
    public static func == (lhs: SabycomUser, rhs: SabycomUser) -> Bool {
        return lhs.uuid == rhs.uuid &&
            lhs.name == rhs.name &&
            lhs.surname == rhs.surname &&
            lhs.email == rhs.email &&
            lhs.phone == rhs.phone
    }
}
