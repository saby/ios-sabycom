//
//  SabycomPushToken.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 23.11.2021.
//

import Foundation

struct SabycomPushToken: Equatable {
    let tokenString: String
    let tokenType: SabycomAPNSTokenType
    
    public static func == (lhs: SabycomPushToken, rhs: SabycomPushToken) -> Bool {
        return lhs.tokenString == rhs.tokenString &&
            lhs.tokenType == rhs.tokenType
    }
}
