//
//  SabycomNotificationModel.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 03.11.2021.
//

import Foundation

struct SabycomNotificationModel {
    let id: String
    let action: Int
    let addresseeId: String
    let type: Int
    let channelUUID: String
    let title: String
    let body: String
    let operatorPhoto: String
    let messageDate: Date
    let unreadCount: Int
    
    init?(userInfo: [AnyHashable: Any]) {
        guard let id = userInfo["id"] as? String,
              let action = userInfo["action"] as? Int,
              let addresseId = userInfo["addresseeId"] as? String,
              let type = userInfo["type"] as? Int,
              let timestampInMillis = userInfo["timestamp"] as? Double,
              let data = userInfo["data"] as? [AnyHashable: Any] else {
                  return nil
              }
        
        self.id = id
        self.action = action
        self.addresseeId = addresseId
        self.type = type
        
        let timestamp = timestampInMillis / 1000.0
        self.messageDate = Date(timeIntervalSince1970: timestamp)
        self.channelUUID = data["channelUUID"] as? String ?? ""
        self.operatorPhoto = data["operatorPhoto"] as? String ?? ""
        self.unreadCount = data["unreadCount"] as? Int ?? 0
        
        let aps = userInfo["aps"] as? [AnyHashable: Any] ?? [:]
        let alert = aps["alert"] as? [AnyHashable: Any] ?? [:]
        self.title = alert["title"] as? String ?? ""
        self.body = alert["body"] as? String ?? ""
    }
}
