//
//  NotificationService.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 02.11.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import UIKit
import UserNotifications

protocol NotificationService {
    var deviceToken: Data? { get }
    
    func registerForRemoteNotifications()
    func unregisterFromRemoteNotifications()
    func didRegisterForRemoteNotifications(with deviceToken: Data)
    func didFailToRegisterForRemoteNotifications(with error: Error)
}

class NotificationServiceImpl: NSObject, NotificationService, UNUserNotificationCenterDelegate {
    private lazy var sabycomService: SabycomService = DIContainer.shared.resolve(type: SabycomService.self)!
    
    private(set) var deviceToken: Data? {
        didSet {
            NotificationCenter.default.post(name: .NotificationServiceDidChange, object: nil)
        }
    }
    
    //MARK: - Push notifications -
    
    func registerForRemoteNotifications(){
        registerDelegate()
        
        let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (granted, error) in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("Пользователь дал разрешение на уведомления")
            } else if error != nil {
                print("Пользователь не дал разрешения на уведомления. Ошибка: \(error!.localizedDescription)");
            }
        }
    }
    
    func unregisterFromRemoteNotifications() {
        UIApplication.shared.unregisterForRemoteNotifications()
        
        // TODO: Добавить метод отписки от пушей
    }
    
    //MARK: - Remote Notification Callbacks -
    
    func didRegisterForRemoteNotifications(with deviceToken: Data){
        self.deviceToken = deviceToken
    }
    
    func didFailToRegisterForRemoteNotifications(with error: Error) {
        print("Не зарегистрировались для получения уведомдений. Ошибка: \(error.localizedDescription)")
    }
    
    private func registerDelegate(){
        UNUserNotificationCenter.current().delegate = self
    }
    
    //MARK: - UNUserNotificationCenterDelegate -
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        if sabycomService.isSabycomPushNotification(info: userInfo), let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window, let controller = window.rootViewController {
            sabycomService.handlePushNotification(info: userInfo, parentView: controller.view)
        }
        
        completionHandler([])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if sabycomService.isSabycomPushNotification(info: userInfo), let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window, let controller = window.rootViewController {
            sabycomService.show(on: controller, pushInfo: userInfo)
        }
        
        completionHandler()
    }
}

extension NSNotification.Name {
    static let NotificationServiceDidChange = NSNotification.Name(rawValue: "NotificationService.didChange")
}
