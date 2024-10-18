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
    private static var _instance: SabycomImpl?
    private static var instance: SabycomImpl {
        get {
            if _instance == nil {
                _instance = SabycomImpl()
            }
            
            return _instance!
        }
    }
    
    /// Количество непрочитанных сообщений
    public class var unreadConversationCount: Int {
        instance.getUnreadConversationCount()
    }
    
    /// Инициализация компонента. Нужно вызвать до вызова метода show(on:)
    /// - Parameter appId: API Ключ приложения
    /// - Parameter host: Хост, к которому подключаться
    public class func initialize(appId: String, host: SabycomHost.HostType = .prod) {
        instance.initialize(appId: appId, host: host)
    }
    
    /// Уничтожает компонент. После вызова этой функции для работы компонента нужно заново вызвать initialize(apikey:) и registerUser(_:)
    public class func destroy() {
        _instance = nil
    }
    
    /// Показывает виджет. Перед вызовом функции нужно обязяательно вызвать initialize(apikey:) и registerUser(_:)
    /// - Parameter viewController: UIViewController, в котором будет показан виджет
    public class func show(on viewController: UIViewController) {
        instance.show(on: viewController)
    }
    
    /// Закрывает виджет
    public class func hide() {
        instance.hide()
    }
    
    /// Добавить информацию о пользователе. Метод должен быть вызван до show(on:).
    /// Метод необходимо вызывать даже если нет информации о пользователе, в таком случае необходимо передать только идентификатор пользователя SabycomUser
    /// - Parameter user: Информация о пользователе
    public class func registerUser(_ user: SabycomUser) {
        instance.registerUser(user)
    }
    
    /// Подписаться на получение push-сообщений
    /// - Parameter token: Токен, полученный от Firebase
    public class func registerForPushNotifications(with token: String) {
        instance.registerForPushNotifications(with: token)
    }
    
    /// Отписаться от получения push-сообщений
    public class func unregisterFromPushNotifications() {
        instance.unregisterFromPushNotifications()
    }
    
    /// Определить, пришел пуш от сервиса Sabycom или нет
    /// - Parameter info: Payload пуша
    public class func isSabycomPushNotification(info: [String: String]) -> Bool {
        return instance.isSabycomPushNotification(info: info)
    }
    
    /// Показывает всплывающую панель с сообщением
    /// - Parameter info: Payload пуша
    public class func handlePushNotification(info: [String: String]) {
        return instance.handlePushNotification(info: info)
    }
}

private class SabycomImpl {
    private var viewModel = SabycomViewModel()
    
    private var hostType: SabycomHost.HostType = .prod
    
    private lazy var api = Api(hostType: hostType)
    
    private lazy var userService: UserService = UserServiceImpl(api: api)
    private lazy var unreadMessagesService: UnreadMessagesService = UnreadMessagesServiceImpl(api: api)
    
    private lazy var controller = SabycomViewController(unreadMessagesService: unreadMessagesService)
    
    init() {
        unreadMessagesService.registerObserver(self)
    }
    
    deinit {
        unreadMessagesService.unregisterObserver(self)
    }
    
    func initialize(appId: String, host: SabycomHost.HostType) {
        api.hostType = host
        viewModel.appId = appId
        unreadMessagesService.appId = appId
        userService.appId = appId
        hostType = host
        
        configureController()
    }
    
    func show(on viewController: UIViewController) {
        guard tryGetAppIdAndUser() != nil else {
            return
        }
        
        viewController.present(controller, animated: true, completion: nil)
    }
    
    func hide() {
        controller.dismiss(animated: true, completion: nil)
    }
    
    func registerUser(_ user: SabycomUser) {
        viewModel.user = user
        unreadMessagesService.user = user
        userService.user = user
        
        configureController()
     }
    
    func getUnreadConversationCount() -> Int {
        return unreadMessagesService.unreadMessagesCount
    }
    
    func registerForPushNotifications(with token: String) {
        viewModel.pushToken = token
        userService.pushToken = token
    }
    
    func unregisterFromPushNotifications() {
        
    }
    
    func isSabycomPushNotification(info: [String: String]) -> Bool {
        return false
    }

    func handlePushNotification(info: [String: String]) {
        
    }
    
    private func configureController() {
        if let appId = viewModel.appId, !appId.isEmpty, let user = viewModel.user {
            let host = SabycomHost(hostType: hostType, appId: appId)
            let interactor = SabycomInteractor(host: host, appId: appId, user: user)
            let presenter = SabycomPresenter(interactor: interactor, view: controller)
            controller.presenter = presenter
            
            presenter.forceInitialize()
        }
    }
    
    private func tryGetAppIdAndUser() -> (appId: String, user: SabycomUser)? {
        guard let appId = viewModel.appId, !appId.isEmpty else {
            assertionFailure("Sabycom not initialized. Call Sabycom.initialize(apiKey:)")
            return nil
        }
        
        guard let user = viewModel.user else {
            assertionFailure("User not registered. Call Sabycom.registerUser(_:)")
            return nil
        }
        
        return (appId, user)
    }
}

extension SabycomImpl: UnreadMessagesCountObservable {
    func unreadMessagesCountChanged(_ count: Int) {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .SabycomUnreadConversationCountDidChange, object: nil)
        }
    }
}
