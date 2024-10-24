//
//  Api.swift
//  Pods-ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 23.08.2021.
//

import Foundation

class Api {
    func getUnreadConversationCount(completion: @escaping (_ unreadConversationCount: Int) -> Void) {
        let request = Request<UnreadConversationCountResponse>.get(path: "unreadConversationCount")
        request.execute { response in
            completion(response.count)
            print("unread conversations count: \(response.count)")
        } onError: { error in
            completion(0)
            print("unread conversations count error: \(error.localizedDescription)")
        }
    }
    
    func registerUser(_ user: SabycomUser, completion: @escaping (_ userId: String?) -> Void) {
        let params = ["id": user.uuid,
                      "name": user.name ?? "",
                      "surname": user.surname ?? "",
                      "email": user.email ?? "",
                      "phone": user.phone ?? ""]
        let request = Request<RegisterUserResponse>.post(path: "registerUser", params: params)
        request.execute { response in
            completion(response.id)
            print("registered user id: \(response.id)")
        } onError: { error in
            completion(nil)
            print("user registration error: \(error.localizedDescription)")
        }
    }

}
