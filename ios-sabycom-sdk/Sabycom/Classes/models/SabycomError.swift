//
//  SabycomError.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 10.08.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Foundation

/// Модель ошибки
public enum SabycomError: Error {
    /// Неизвестный тип push-сообщения
    case unknownPushNotificationType
}
