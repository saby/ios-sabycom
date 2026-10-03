//
//  SabycomAPNSTokenType.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 23.11.2021.
//

import Foundation

/// Тип токена https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server/sending_notification_requests_to_apns
public enum SabycomAPNSTokenType {
    /// Production токен
    case prod
    
    /// Sandbox токен
    case sandbox
}
