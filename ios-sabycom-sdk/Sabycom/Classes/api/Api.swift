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
                logger.log("unread conversations count: \(count)")
            } else {
                completion?(0)
            }
            
        } onError: { error in
            completion?(0)
            logger.log("unread conversations count error: \(error.localizedDescription)")
        }
    }
    
    func registerUser(_ user: SabycomUser, channedUUID: String, pushToken: SabycomPushToken?, unsubscribe: Bool = false, completion:((_ userId: String?) -> Void)?) {
        let tokenString = pushToken?.tokenString ?? ""
        let pushDebug = pushToken?.tokenType == .sandbox ? true : false
        let params = [
            "id": user.uuid,
            "service_id": channedUUID,
            "name": user.name ?? "",
            "surname": user.surname ?? "",
            "email": user.email ?? "",
            "phone": user.phone ?? "",
            "push_token": tokenString,
            "push_debug": pushDebug,
            "push_os": "ios",
            "push_unsubscribe": unsubscribe
        ] as [String : Any]
        
        let path = "externalUser/\(user.uuid)/\(channedUUID)"
        let request = Request<BaseResponse<Bool>>.put(urlCreator: urlCreator(for: path), params: params)
        request.execute { response in
            if response.result == true {
                if unsubscribe {
                    logger.log("unregistered user id: \(user.uuid)")
                } else {
                    logger.log("registered user id: \(user.uuid), token: \(tokenString), sandboxToken: \(pushDebug)")
                }
                completion?(user.uuid)
            } else if let error = response.error {
                logger.log("user registration error: \(error.message)")
                completion?(nil)
            }
        } onError: { error in
            completion?(nil)
            logger.log("user registration error: \(error.localizedDescription)")
        }
    }

    private func urlCreator(for path: String) -> URLCreator {
        return URLCreator(host: hostType, path: path)
    }
}
