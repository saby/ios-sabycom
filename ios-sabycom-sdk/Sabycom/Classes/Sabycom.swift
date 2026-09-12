//
//  Sabycom.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 10.08.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import UIKit

public class Sabycom {
    private var appId: String = ""
    private var apiKey: String = ""
    
    private static let instance = Sabycom()
    
    private let api = Api()
    
    private lazy var controller = SabycomViewController()
    
    public class func initialize(appId: String, apiKey: String, lazy: Bool = false) {
        instance.appId = appId
        instance.apiKey = apiKey
        
        let host = SabycomHost(hostType: .test, appId: appId, apiKey: apiKey)
        let interactor = SabycomInteractor(host: host)
        let presenter = SabycomPresenter(interactor: interactor, view: instance.controller)
        instance.controller.presenter = presenter
        if !lazy {
            presenter.forceInitialize()
        }
    }
    
    public class func show(on viewController: UIViewController) {
        checkWasInitialized()
        
        viewController.present(instance.controller, animated: true, completion: nil)
    }
    
    public class func hide() {
        checkWasInitialized()
        
        instance.controller.dismiss(animated: true, completion: nil)
    }
    
    public class func getUnreadConversationCount(completion: @escaping (_ unreadConversationCount: Int) -> Void) {
        instance.api.getUnreadConversationCount(completion: completion)
    }
    
    public class func registerUser(_ user: SabycomUser, completion: @escaping (_ userId: String?) -> Void) {
        instance.api.registerUser(user, completion: completion)
    }
    
    public class func isSabycomPushNotification(info: [String: String]) -> Bool {
        return false
    }
    
    public class func handlePushNotification(info: [String: String]) {
        
    }
    
    private class func checkWasInitialized() {
        if instance.appId.isEmpty || instance.apiKey.isEmpty {
            assertionFailure("Sabycom not initialized. Call Sabycom.initialize")
        }
    }
}
