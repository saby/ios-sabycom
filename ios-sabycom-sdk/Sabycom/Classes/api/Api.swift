//
//  Api.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 23.08.2021.
//

import Foundation

class Api {
    var hostType: SabycomHost.HostType
    
    init(hostType: SabycomHost.HostType) {
        self.hostType = hostType
    }
    
    func getUnreadConversationCount(for userId: String, channedUUID: String, completion: ((_ unreadConversationCount: Int) -> Void)?) {
        let path = "externalUser/\(userId)/\(channedUUID)/unread/\(channedUUID)"
        let request = Request<BaseResponse<UnreadConversationCountResponse>>.get(urlCreator: urlCreator(for: path))
        request.execute { response in
            if let count = response.result?.count {
                completion?(count)
                print("unread conversations count: \(count)")
            } else {
                completion?(0)
            }
            
        } onError: { error in
            completion?(0)
            print("unread conversations count error: \(error.localizedDescription)")
        }
    }
    
    func registerUser(_ user: SabycomUser, channedUUID: String, pushToken: SabycomPushToken?, unsubscribe: Bool = false, completion:((_ userId: String?) -> Void)?) {
        let params = ["id": user.uuid,
                      "service_id": channedUUID,
                      "name": user.name ?? "",
                      "surname": user.surname ?? "",
                      "email": user.email ?? "",
                      "phone": user.phone ?? "",
                      "push_token": pushToken?.tokenString ?? "",
                      "push_debug": pushToken?.tokenType == .sandbox ? true : false,
                      "push_os": "ios",
                      "push_unsubscribe": unsubscribe] as [String : Any]
        
        let path = "externalUser/\(user.uuid)/\(channedUUID)"
        let request = Request<BaseResponse<Bool>>.put(urlCreator: urlCreator(for: path), params: params)
        request.execute { response in
            if response.result == true {
                print("registered user id: \(user.uuid)")
                completion?(user.uuid)
            } else if let error = response.error {
                print("user registration error: \(error.message)")
                completion?(nil)
            }
        } onError: { error in
            completion?(nil)
            print("user registration error: \(error.localizedDescription)")
        }
    }

    private func urlCreator(for path: String) -> URLCreator {
        return URLCreator(host: hostType, path: path)
    }
}
