//
//  ErrorResponse.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 24.09.2021.
//

import Foundation

struct ResponseError: Codable {
    let code: Int
    let message: String
    let details: String
    
}
