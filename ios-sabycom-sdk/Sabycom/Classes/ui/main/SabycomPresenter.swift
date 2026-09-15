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
    var viewWillDisappear: (() -> Void)? { get set }
    
    var didFinishLoading: ((_ url: URL) -> Void)? { get set }
    var didFinishLoadingWindow: ((_ url: URL) -> Void)? { get set }
    var didFailLoading: ((_ error: Error?) -> Void)? { get set }
    
    var didUpdateUnreadMessagesCount: ((_ count: Int) -> Void)? { get set }
    
    func load(_ url: URL, fromCache: Bool)
    func update(with state: WebViewState)
    
    func createWebArchive(completion: @escaping (_ data: Data?) -> Void)
    func evaluateJavaScript(_ script: String)
}

enum WebViewState: Equatable {
    case preparing
    case loading(url: URL)
    case loadingFromArchive(url: URL)
    case loaded(url: URL)
    case error
}

class SabycomPresenter {
    var isInternetAvailable: Bool {
        return reachabilityService.isAvailable
    }
    
    private let interactor: SabycomInteractor
    private let webArchivesStorage: WebArchivesStorage
    private let reachabilityService: ReachabilityService
    private let unreadMessagesService: UnreadMessagesService
    private let userService: UserService
    
    private weak var view: SabycomView?
    
    private var appWillEnterForegroundObserver: Any?
    
    private var loadedFromCache: Bool = false
    
    private var state: WebViewState = .preparing {
        didSet {
            view?.update(with: state)
        }
    }
    
    private var shouldLoadFromCloud: Bool = false
    
    init(interactor: SabycomInteractor,
         view: SabycomView,
         webArchivesStorage: WebArchivesStorage,
         reachabilityService: ReachabilityService,
         unreadMessagesService: UnreadMessagesService,
         userService: UserService) {
        self.interactor = interactor
        self.webArchivesStorage = webArchivesStorage
        self.view = view
        self.reachabilityService = reachabilityService
        self.unreadMessagesService = unreadMessagesService
        self.userService = userService
        
        setViewHandlers()
        subscribeApplicationStateChanges()
        removeNotifications()
        
        reachabilityService.registerObserver(self)
        userService.registerObserver(self)
    }
    
    deinit {
        if let appWillEnterForegroundObserver = appWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(appWillEnterForegroundObserver)
        }
        
        reachabilityService.unregisterObserver(self)
        userService.unregisterObserver(self)
    }
    
    private func setViewHandlers() {
        view?.didLoadView = { [weak self] in
            self?.load()
        }
        
        view?.didFinishLoading = { [weak self] url in
            if self?.isInternetAvailable != true {
                self?.view?.evaluateJavaScript("window.location.hash = '#isOffline=true';")
            }
        }
        
        view?.didFinishLoadingWindow = { [weak self] url in
            DispatchQueue.main.async { [weak self] in
                self?.state = .loaded(url: url)
            }
        }
        
        view?.didFailLoading = { [weak self] _ in
            guard let self = self else {
                return
            }
            self.state = .error
        }
        
        view?.didUpdateUnreadMessagesCount = { [weak unreadMessagesService] count in
            unreadMessagesService?.updateUnreadMessagesCount(count)
        }
    }
    
    private func load() {
        state = .preparing
        
        if let url = self.interactor.getUrl() {
            let isOffline = !reachabilityService.isAvailable
            
            if isOffline || userService.userInfoSent {
                loadedFromCache = isOffline
                state = .loading(url: url)
                view?.load(url, fromCache: isOffline)
            } else {
                shouldLoadFromCloud = true
            }
        } else {
            state = .error
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
    }
    
    private func removeNotifications() {
        UNUserNotificationCenter.current().getDeliveredNotifications { notifications in
            let result: [UNNotification] = notifications.compactMap { notification in
                let userInfo = notification.request.content.userInfo
                
                guard SabycomSDK.isSabycomPushNotification(info: userInfo) else {
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
            
            var lastStateIsError: Bool = false
            if case .error = self.state {
                lastStateIsError = true
            }
            
            if available && (self.loadedFromCache || lastStateIsError) {
                self.load()
            }
            
            self.notifyUINetworkChanged(available)
        }
    }
}

extension SabycomPresenter: UserServiceObservable {
    func userInfoSent() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            if self.shouldLoadFromCloud {
                self.load()
            }
        }
    }
}
