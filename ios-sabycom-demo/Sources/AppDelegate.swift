//
//  AppDelegate.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 08/10/2021.
//  Copyright (c) 2021 Tensor. All rights reserved.
//

import UIKit
import Sabycom

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private lazy var notificationService: NotificationService? = {
        DIContainer.shared.resolve(type: NotificationService.self)
    }()
    
    internal func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        registerDependencies()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = createRootController()
        window?.makeKeyAndVisible()
        
        notificationService?.registerForRemoteNotifications()
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    //MARK: - Notifications -
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        notificationService?.didRegisterForRemoteNotifications(with: deviceToken)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        notificationService?.didFailToRegisterForRemoteNotifications(with: error)
    }
    
    //MARK: - Private -

    private func registerDependencies() {
        let container = DIContainer.shared
        container.register(type: ConfigurationService.self, component: ConfigurationServiceImpl())
        container.register(type: UserStorage.self, component: UserStorageImpl())
        container.register(type: NotificationService.self, component: NotificationServiceImpl())
        container.register(type: SabycomService.self, component: SabycomServiceImpl())
    }
    
    private func createRootController() -> UIViewController {
        let interactor = ConfigurationInteractor()
        let controller = ConfigurationViewController()
        let navigationController = UINavigationController(rootViewController: controller)
        let router = SabycomConfigurationRouterImpl(navigationController: navigationController)
        
        let presenter = ConfigurationPresenter(interactor: interactor, view: controller, router: router)
        controller.presenter = presenter
        
        return navigationController
    }
}

