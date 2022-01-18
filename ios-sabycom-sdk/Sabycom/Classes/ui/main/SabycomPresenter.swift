//
//  SabycomPresenter.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import UIKit

protocol SabycomView: AnyObject {
    var didLoadView: (() -> Void)? { get set }
    var didLoadWebView: (() -> Void)? { get set }
    var viewWillAppear: (() -> Void)? { get set }
    var viewWillDisappear: (() -> Void)? { get set }
    
    func load(_ url: URL)
    func load(archive archiveUrl: URL)
    func createWebArchive(completion: @escaping (_ data: Data?) -> Void)
    func evaluateJavaScript(_ script: String)
}

class SabycomPresenter {
    private let interactor: SabycomInteractor
    private let webArchivesStorage: WebArchivesStorage
    private weak var view: SabycomView?
    private let reachabilityService: ReachabilityService
    
    private var appWillEnterForegroundObserver: Any?
    private var appWillEnterBackgroundObserver: Any?
    
    private var loadedFromArchive: Bool = false
    
    init(interactor: SabycomInteractor,
         view: SabycomView,
         webArchivesStorage: WebArchivesStorage,
         reachabilityService: ReachabilityService) {
        self.interactor = interactor
        self.webArchivesStorage = webArchivesStorage
        self.view = view
        self.reachabilityService = reachabilityService
        
        setViewHandlers()
        subscribeApplicationStateChanges()
        removeNotifications()
        
        reachabilityService.registerObserver(self)
    }
    
    deinit {
        if let appWillEnterForegroundObserver = appWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(appWillEnterForegroundObserver)
        }
        
        reachabilityService.unregisterObserver(self)
    }
    
    private func setViewHandlers() {
        view?.didLoadView = { [weak self] in
            guard let self = self else {
                return
            }
            
            self.load()
        }
        
        view?.viewWillDisappear = { [weak self] in
            guard let self = self else {
                return
            }
            
            self.createArchive()
        }
        
        view?.didLoadWebView = { [weak self] in
            guard let self = self else {
                return
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.notifyUINetworkChanged(self.reachabilityService.isAvailable)
            }
        }
    }
    
    private func load() {
        if !reachabilityService.isAvailable, let archiveUrl = webArchivesStorage.getWebArchiveURL() {
            loadFromArchive(archiveUrl)
        } else {
            loadFromCloud()
        }
    }
    
    private func loadFromArchive(_ archiveUrl: URL) {
        loadedFromArchive = true
        view?.load(archive: archiveUrl)
    }
    
    private func loadFromCloud() {
        if let url = self.interactor.getUrl() {
            loadedFromArchive = false
            view?.load(url)
        }
    }
    
    private func createArchive() {
        if !loadedFromArchive {
            view?.createWebArchive(completion: { [weak self] data in
                guard let data = data else {
                    return
                }
                self?.webArchivesStorage.saveWebArchive(data)
            })
        }
    }
    
    private func notifyUINetworkChanged(_ available: Bool) {
        var params = [String: Any]()
        params["channel"] = interactor.appId
        params["action"] = "setOfflineMode"
        params["value"] = ["isOffline": !available]
        params["windowId"] = "chat"
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: params, options: []),
            let json = String(data: jsonData, encoding: .utf8) {
            let script = "window.postMessage('\(json)');"
            
            DispatchQueue.main.async { [weak view] in
                view?.evaluateJavaScript(script)
            }
        }
    }
    
    private func subscribeApplicationStateChanges() {
        appWillEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.load()
                self?.removeNotifications()
            }
        
        appWillEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.createArchive()
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

extension SabycomPresenter: ReachabilityObservable {
    func reachabilityChanged(_ available: Bool) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            if available, self.loadedFromArchive {
                self.loadFromCloud()
            }
            
            self.notifyUINetworkChanged(available)
        }
    }
}
