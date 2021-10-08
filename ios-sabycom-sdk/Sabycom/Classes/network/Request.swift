//
//  Request.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 23.08.2021.
//

import Foundation

struct Request<T: Codable> {
    let url: String
    let method: HTTPMethod
    let params: [String: Any?]
    let headers: [String: String]
    
    init(url: String,
         method: HTTPMethod = .get,
         params: [String: Any?] = [:],
         headers: [String: String] = [:]) {
        self.url = url
        self.method = method
        self.params = params
        self.headers = headers
    }
    
    func execute(dispatcher: NetworkDispatcher = Network.instance,
                 keyDecodingStrategy: JSONDecoder.KeyDecodingStrategy = .useDefaultKeys,
                 onSuccess: @escaping (T) -> Void,
                 onError: @escaping (Error) -> Void) {
        dispatcher.dispatch(
            urlString: url,
            method: method,
            params: params,
            headers: headers,
            onSuccess: { (responseData: Data) in
                do {
                    let jsonDecoder = JSONDecoder()
                    jsonDecoder.keyDecodingStrategy = keyDecodingStrategy
                    let result = try jsonDecoder.decode(T.self, from: responseData)
                    DispatchQueue.main.async {
                        onSuccess(result)
                    }
                } catch let error {
                    DispatchQueue.main.async {
                        if error is DecodingError {
                            onError(NetworkError.parseError)
                        } else {
                            onError(error)
                        }
                    }
                }
            },
            onError: { (error: Error) in
                DispatchQueue.main.async {
                    onError(error)
                }
            }
        )
    }
}

extension Request {
    
    static func get(urlCreator: URLCreator, params: [String: Any?] = [:], headers: [String: String] = [:]) -> Request {
        let request = Request(url: urlCreator.url(), method: .get, params: params, headers: headers)
        return request
    }
    
    static func post(urlCreator: URLCreator, params: [String: Any?] = [:], headers: [String: String] = [:]) -> Request {
        let request = Request(url: urlCreator.url(), method: .post, params: params, headers: headers)
        return request
    }
    
    static func put(urlCreator: URLCreator, params: [String: Any?] = [:], headers: [String: String] = [:]) -> Request {
        let request = Request(url: urlCreator.url(), method: .put, params: params, headers: headers)
        return request
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}
