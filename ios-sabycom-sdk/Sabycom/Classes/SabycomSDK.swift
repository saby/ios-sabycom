//
//  SabycomSDK.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 10.08.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import UIKit

/// СБИС онлайн консультант.
public class SabycomSDK {
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
    
    /// Показывает виджет. Перед вызовом функции нужно обязяательно вызвать initialize(apikey:) и registerUser(_:) или registerAnonymousUser()
    /// - Parameter viewController: UIViewController, в котором будет показан виджет
    public class func show(on viewController: UIViewController, pushInfo: [AnyHashable: Any]? = nil) {
        instance.show(on: viewController, pushInfo: pushInfo)
    }
    
    /// Закрывает виджет
    public class func hide() {
        instance.hide()
    }
    
    /// Добавить информацию о пользователе. Метод должен быть вызван до show(on:).
    /// - Parameter user: Информация о пользователе
    public class func registerUser(_ user: SabycomUser) {
        instance.registerUser(user)
    }
    
    /// Зарегистрировать анонимного пользователя. Используется, если в приложении нет авторизации
    public class func registerAnonymousUser() {
        instance.registerAnonymousUser()
    }
    
    /// Подписаться на получение push-сообщений
    /// - Parameter deviceToken: Apns токен
    public class func registerForPushNotifications(with deviceToken: Data, tokenType: SabycomAPNSTokenType = .prod) {
        instance.registerForPushNotifications(with: deviceToken, tokenType: tokenType)
    }
    
    /// Удалить информацию о пользователе и отписаться от получения push-сообщений
    public class func logout() {
        instance.logout()
    }
    
    /// Определить, пришел пуш от сервиса Sabycom или нет
    /// - Parameter info: Payload пуша
    public class func isSabycomPushNotification(info: [AnyHashable: Any]) -> Bool {
        return instance.isSabycomPushNotification(info: info)
    }
    
    /// Показывает всплывающую панель с сообщением
    /// - Parameter info: Payload пуша
    public class func handlePushNotification(info: [AnyHashable: Any], parentView: UIView) {
        instance.handlePushNotification(info: info, parentView: parentView)
    }
}

private class SabycomImpl {
    private var viewModel = SabycomViewModel()
    
    private var hostType: SabycomHost.HostType = .prod
    
    private lazy var api = Api(hostType: hostType)
    
    private lazy var userStorage: UserStorage = UserStorageImpl()
    private lazy var userService: UserService = UserServiceImpl(api: api, userStorage: userStorage, reachabilityService: reachabilityService)
    private lazy var unreadMessagesService: UnreadMessagesService = UnreadMessagesServiceImpl(api: api, reachabilityService: reachabilityService)
    private lazy var imagesService: ImagesService = ImagesServiceImpl(cacheService: ImagesCacheServiceImpl())
    private lazy var webArchivesStorage: WebArchivesStorage = WebArchivesStorageImpl()
    private lazy var reachabilityService: ReachabilityService = ReachabilityServiceImpl()
    
    private weak var controller: UIViewController?
    
    private var appWillEnterForegroundObserver: Any?
    
    init() {
        subscribeApplicationStateChanges()
        unreadMessagesService.registerObserver(self)
    }
    
    deinit {
        if let appWillEnterForegroundObserver = appWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(appWillEnterForegroundObserver)
        }
        
        unreadMessagesService.unregisterObserver(self)
    }
    
    func initialize(appId: String, host: SabycomHost.HostType) {
        guard let _ = UUID(uuidString: appId) else {
            assertionFailure(Localization.shared.text(forKey: .invalidChannelId))
            return
        }
        
        api.hostType = host
        viewModel.appId = appId
        unreadMessagesService.appId = appId
        userService.appId = appId
        hostType = host
    }
    
    func show(on viewController: UIViewController, pushInfo: [AnyHashable: Any]? = nil) {
        guard tryGetAppIdAndUser() != nil else {
            return
        }
        
        guard controller == nil else {
            return
        }
        
        guard let controller = createController() else {
            return
        }
        
        var model: SabycomNotificationModel?
        
        if let pushInfo {
            model = SabycomNotificationModel(userInfo: pushInfo)
        } else {
            model = nil
        }
        
        userService.notification = model
        
        viewController.present(controller, animated: true, completion: nil)
    }
    
    func hide() {
        controller?.dismiss(animated: true, completion: nil)
        controller = nil
    }
    
    func registerUser(_ user: SabycomUser) {
        if userStorage.currentUserId != user.uuid {
            webArchivesStorage.clear()
        }
        userService.registerUser(user)
        
        configure(with: user)
     }
    
    func registerAnonymousUser() {
        if !userService.registeredAsAnonymous {
            webArchivesStorage.clear()
        }
        let user = userService.registerAnonymousUser()
        
        configure(with: user)
    }
    
    func getUnreadConversationCount() -> Int {
        return unreadMessagesService.unreadMessagesCount
    }
    
    func registerForPushNotifications(with deviceToken: Data, tokenType: SabycomAPNSTokenType) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        let token = SabycomPushToken(tokenString: tokenString, tokenType: tokenType)
        viewModel.pushToken = token
        userService.pushToken = token
    }
    
    func logout() {
        userService.logout(completion: nil)
        
        viewModel.user = nil
        unreadMessagesService.user = nil
        unreadMessagesService.updateUnreadMessagesCount(0)
    }
    
    func isSabycomPushNotification(info: [AnyHashable: Any]) -> Bool {
        guard let model = SabycomNotificationModel(userInfo: info), model.addresseeId.lowercased() == userService.currentUserId?.lowercased() else {
            return false
        }
        
        return true
    }

    func handlePushNotification(info: [AnyHashable: Any], parentView: UIView) {
        if controller?.presentingViewController == nil {
            guard let model = SabycomNotificationModel(userInfo: info) else {
                return
            }
            unreadMessagesService.updateUnreadMessagesCount(model.unreadCount)
            
            SabycomNotificationView.show(imagesService: imagesService, model: model, parentView: parentView)
        }
    }
    
    private func configure(with user: SabycomUser) {
        viewModel.user = user
        unreadMessagesService.user = user
    }
    
    private func createController() -> SabycomViewController? {
        guard let appId = viewModel.appId, !appId.isEmpty, let user = viewModel.user else {
            return nil
        }
        
        let host = SabycomHost(hostType: hostType, appId: appId)
        let interactor = SabycomInteractor(host: host, appId: appId, user: user)
        let controller = SabycomViewController()
        controller.presenter = SabycomPresenter(interactor: interactor,
                                                view: controller,
                                                webArchivesStorage: webArchivesStorage,
                                                reachabilityService: reachabilityService,
                                                unreadMessagesService: unreadMessagesService,
                                                userService: userService)
        
        self.controller = controller
        
        return controller
    }
    
    private func tryGetAppIdAndUser() -> (appId: String, user: SabycomUser)? {
        guard let appId = viewModel.appId, !appId.isEmpty else {
            assertionFailure("SabycomSDK not initialized. Call SabycomSDK.initialize(apiKey:)")
            return nil
        }
        
        guard let user = viewModel.user else {
            assertionFailure("User not registered. Call SabycomSDK.registerUser(_:)")
            return nil
        }
        
        return (appId, user)
    }
    
    private func subscribeApplicationStateChanges() {
        appWillEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main) { [weak unreadMessagesService] _ in
                let _ = unreadMessagesService?.loadUnreadMessagesCount(force: true)
            }
    }
}

extension SabycomImpl: UnreadMessagesCountObservable {
    func unreadMessagesCountChanged(_ count: Int) {
        DispatchQueue.main.async {
            if count == 0 {
                SabycomNotificationView.hide()
            }
            NotificationCenter.default.post(name: .SabycomUnreadConversationCountDidChange, object: nil)
        }
    }
}
