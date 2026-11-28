//
//  BaseResponse.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 23.08.2021.
//

import Foundation

struct BaseResponse<T: Codable>: Codable {
    let jsonrpc: String
    let result: T?
    let error: ResponseError?
}
