//
//  SabycomPresenter.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import UIKit

protocol SabycomView: AnyObject {
    var didLoadView: (() -> Void)? { get set }
    var viewWillAppear: (() -> Void)? { get set }
    
    func load(_ url: URL)
}

class SabycomPresenter {
    private let interactor: SabycomInteractor
    private weak var view: SabycomView?
    
    private var appWillEnterForegroundObserver: Any?
    
    init(interactor: SabycomInteractor, view: SabycomView) {
        self.interactor = interactor
        self.view = view
        
        setViewHandlers()
        subscribeApplicationStateChanges()
        removeNotifications()
    }
    
    deinit {
        if let appWillEnterForegroundObserver = appWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(appWillEnterForegroundObserver)
        }
    }
    
    private func setViewHandlers() {
        view?.didLoadView = { [weak view, weak interactor] in
            if let url = interactor?.getUrl() {
                view?.load(url)
            }
        }
    }
    
    private func subscribeApplicationStateChanges() {
        appWillEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                if let url = self?.interactor.getUrl() {
                    self?.view?.load(url)
                }
                
                self?.removeNotifications()
            }
    }
    
    private func removeNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let result: [UNNotification] = notifications.compactMap { notification in
                let userInfo = notification.request.content.userInfo
                
                guard Sabycom.isSabycomPushNotification(info: userInfo) else {
                    return nil
                }
                
                return notification
            }
            
            UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: result.map { $0.request.identifier })
        }
    }
}
