//
//  Sabycom.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 10.08.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import UIKit

/// СБИС онлайн консультант.
public class Sabycom {
    private var appId: String = ""
    
    private var user: SabycomUser?
    
    private static let instance = Sabycom()
    
    private let api = Api()
    
    private lazy var controller = SabycomViewController()
    
    /// Инициализация компонента. Нужно вызвать до вызова метода show(on:)
    /// - Parameter appId: API Ключ приложения
    public class func initialize(appId: String) {
        instance.appId = appId
    }
    
    /// Показывает виджет. Перед вызовом функции нужно обязяательно вызвать initialize(apikey:) и registerUser(_:)
    /// - Parameter viewController: UIViewController, в котором будет показан виджет
    public class func show(on viewController: UIViewController) {
        checkWasInitialized()
        
        let host = SabycomHost(hostType: .test, appId: instance.appId)
        let interactor = SabycomInteractor(host: host, appId: instance.appId, user: instance.user!)
        let presenter = SabycomPresenter(interactor: interactor, view: instance.controller)
        instance.controller.presenter = presenter
        
        viewController.present(instance.controller, animated: true, completion: nil)
    }
    
    /// Закрывает виджет
    public class func hide() {
        checkWasInitialized()
        
        instance.controller.dismiss(animated: true, completion: nil)
    }
    
    /// Добавить информацию о пользователе. Метод должен быть вызван до show(on:).
    /// Метод необходимо вызывать даже если нет информации о пользователе, в таком случае необходимо передать только идентификатор пользователя SabycomUser
    /// - Parameter user: Информация о пользователе
    public class func registerUser(_ user: SabycomUser) {
        instance.user = user
        
        instance.api.registerUser(user, channedUUID: instance.appId, pushToken: nil) { userId in
            
        }
    }
    
    /// Получить количество непрочитанных сообщений
    /// - Parameter completion: Каллбек, в который придет количество непрочитанных сообщений
    public class func getUnreadConversationCount(completion: @escaping (_ unreadConversationCount: Int) -> Void) {
        checkWasInitialized()
        
        instance.api.getUnreadConversationCount(for: instance.user!.uuid, channedUUID: instance.appId, completion: completion)
    }
    
    /// Определить, пришел пуш от сервиса Sabycom или нет
    /// - Parameter info: Payload пуша
    public class func isSabycomPushNotification(info: [String: String]) -> Bool {
        return false
    }
    
    /// Показывает всплывающую панель с сообщением
    /// - Parameter info: Payload пуша
    public class func handlePushNotification(info: [String: String]) {
        
    }
    
    private class func checkWasInitialized() {
        if instance.appId.isEmpty {
            assertionFailure("Sabycom not initialized. Call Sabycom.initialize(apiKey:)")
        } else if instance.user == nil {
            assertionFailure("User not registered. Call Sabycom.registerUser(_:)")
        }
    }
}
