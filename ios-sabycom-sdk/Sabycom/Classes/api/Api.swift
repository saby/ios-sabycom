//
//  Api.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 23.08.2021.
//

import Foundation

class Api {
    func getUnreadConversationCount(for userId: String, channedUUID: String, completion: @escaping (_ unreadConversationCount: Int) -> Void) {
        let path = "externalUser/\(userId)/\(channedUUID)/unread/\(channedUUID)"
        let request = Request<UnreadConversationCountResponse>.get(path: path)
        request.execute { response in
            completion(response.count)
            print("unread conversations count: \(response.count)")
        } onError: { error in
            completion(0)
            print("unread conversations count error: \(error.localizedDescription)")
        }
    }
    
    func registerUser(_ user: SabycomUser, channedUUID: String, pushToken: String?, completion: @escaping (_ userId: String?) -> Void) {
        let params = ["id": user.uuid,
                      "service_id": channedUUID,
                      "name": user.name ?? "",
                      "surname": user.surname ?? "",
                      "email": user.email ?? "",
                      "phone": user.phone ?? "",
                      "push_token": pushToken ?? ""]
        let request = Request<RegisterUserResponse>.post(path: "externalUser", params: params)
        request.execute { response in
            if response.result == true {
                print("registered user id: \(user.uuid)")
            } else if let error = response.error {
                print("user registration error: \(error.message)")
            }
        } onError: { error in
            completion(nil)
            print("user registration error: \(error.localizedDescription)")
        }
    }

}
