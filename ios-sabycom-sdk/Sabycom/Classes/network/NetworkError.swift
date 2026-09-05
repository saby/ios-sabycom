//
//  NetworkError.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 23.08.2021.
//

import Foundation

enum NetworkError: Swift.Error {
    case invalidURL
    case noData
    case parseError
}
