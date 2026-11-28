//
//  Netwrok.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 23.08.2021.
//

import Foundation

protocol NetworkDispatcher {
    func dispatch(urlString: String,
                  method: HTTPMethod,
                  params: [String: Any?],
                  headers: [String: String],
                  onSuccess: @escaping (Data) -> Void,
                  onError: @escaping (Error) -> Void)
}


class Network: NetworkDispatcher {
    private lazy var session = URLSession(configuration: .default, delegate: nil, delegateQueue: .main)
    
    static let instance = Network()

    func dispatch(urlString: String,
                  method: HTTPMethod,
                  params: [String: Any?],
                  headers: [String: String],
                  onSuccess: @escaping (Data) -> Void,
                  onError: @escaping (Error) -> Void) {
        guard let url = URL(string: urlString) else {
            onError(NetworkError.invalidURL)
            return
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.rawValue
        
        do {
            if !params.isEmpty {
                urlRequest.httpBody = try JSONSerialization.data(withJSONObject: params, options: [])
            }
        } catch let error {
            onError(error)
            return
        }
        
        var headers = headers
        headers["Content-Type"] = "application/json"
        urlRequest.allHTTPHeaderFields = headers
        
        session.dataTask(with: urlRequest) { (data, response, error) in
            if let error = error {
                onError(error)
                return
            }
            
            guard let data = data else {
                onError(NetworkError.noData)
                return
            }
            
            onSuccess(data)
        }.resume()
    }
}
