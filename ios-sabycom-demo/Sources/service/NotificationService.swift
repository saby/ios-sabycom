//
//  NotificationService.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 02.11.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Foundation
import UserNotifications
import Sabycom

class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    private (set) var token: String = ""
    
    func registerDelegate(){
        UNUserNotificationCenter.current().delegate = self
    }
    
    //MARK: - Push notifications -
    
    func registerForRemoteNotifications(){
        let authOptions: UNAuthorizationOptions = [.alert, .sound, .badge]
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (granted, error) in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("Granted notifications")
            } else if error != nil {
                print("Not granted permissions. Error: \(error!.localizedDescription)");
            }
        }
    }
    
    class func unregisterForRemoteNotifications(completion: ((_ succeeded: Bool, _ error: Error?) -> ())?) {
        UIApplication.shared.unregisterForRemoteNotifications()
        
        // TODO: Добавить метод отписки от пушей
    }
    
    //MARK: - Remote Notification Callbacks -
    
    func didRegisterForRemoteNotifications(with deviceToken: Data){
        token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        Sabycom.registerForPushNotifications(with: token)
    }
    
    func didFailToRegisterForRemoteNotifications(with error: Error) {
        print("did fail to register for remote notifications. error: \(error.localizedDescription)")
    }
    
    //MARK: - UNUserNotificationCenterDelegate -
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound, .badge])
    }
    
    public func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
    }
}
