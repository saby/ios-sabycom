//
//  CreateUserModel.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 08.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Foundation

struct CreateUserModel {
    var name: String = ""
    var surname: String = ""
    var email: String = ""
    var phone: String = ""
    
    var markNameRequired: Bool = false
    var markSurnameRequired: Bool = false
    var markEmailRequired: Bool = false
    var markPhoneRequired: Bool = false
    
    var isValid: Bool {
        !markNameRequired && !markSurnameRequired && !markEmailRequired && !markPhoneRequired
    }
}
