//
//  UnreadMessagesService.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 28.09.2021.
//

import Foundation

protocol UnreadMessagesCountObservable: AnyObject {
    func unreadMessagesCountChanged(_ count: Int)
}

protocol UnreadMessagesService: AnyObject {
    var user: SabycomUser? { get set }
    var appId: String? { get set }
    var unreadMessagesCount: Int { get }
    
    func updateUnreadMessagesCount(_ count: Int)
    
    func registerObserver(_ observer: UnreadMessagesCountObservable)
    func unregisterObserver(_ observer: UnreadMessagesCountObservable)
}

class UnreadMessagesServiceImpl: UnreadMessagesService {
    private enum Constants {
        static let minUpdateTimeInterval: TimeInterval = 60
        
        static let checkUpdatePossibilitySeconds: Int = 10
    }
    
    var user: SabycomUser? {
        didSet {
            loadUnreadMessagesCount(force: false)
        }
    }
    
    var appId: String? {
        didSet {
            loadUnreadMessagesCount(force: false)
        }
    }
    var unreadMessagesCount: Int = 0
    
    private let api: Api
    
    private let queue = DispatchQueue(label: "UnreadMessagesCountObservable", qos: .userInitiated)

    private var observers: [Weak<UnreadMessagesCountObservable>] = []
    private var strongObservers: [UnreadMessagesCountObservable] {
        return observers.compactMap { $0.value }
    }
    
    private var lastUpdateTimeInterval: TimeInterval?
    
    private var loadingMessagesCount: Bool = false
    
    private var updateUnreadMessagesWorker: DispatchWorkItem?
    
    init(api: Api) {
        self.api = api
        
        scheduleUpdateUnreadMessagesWorker()
    }

    deinit {
        updateUnreadMessagesWorker?.cancel()
        updateUnreadMessagesWorker = nil
    }
    
    func updateUnreadMessagesCount(_ count: Int) {
        notifyObservers(with: count)
    }
    
    func registerObserver(_ observer: UnreadMessagesCountObservable) {
        queue.async { [self] in
            if self.observers.contains(where: { $0.value === observer }) {
                return
            }
            self.observers.append(Weak(value: observer))
        }
    }

    func unregisterObserver(_ observer: UnreadMessagesCountObservable) {
        queue.sync {
            observers = observers.filter { $0.value !== observer }
        }
    }

    @discardableResult
    private func loadUnreadMessagesCount(force: Bool) -> Bool {
        guard let uuid = user?.uuid, let appId = appId else {
            return false
        }
        
        let timePassedInterval = ProcessInfo.processInfo.systemUptime - (lastUpdateTimeInterval ?? 0)
        guard !loadingMessagesCount && (force || lastUpdateTimeInterval == nil || timePassedInterval >= Constants.minUpdateTimeInterval) else {
            return false
        }
        
        loadingMessagesCount = true
        
        api.getUnreadConversationCount(for: uuid, channedUUID: appId) { [weak self] count in
            self?.loadingMessagesCount = false
            self?.notifyObservers(with: count)
        }
        
        return true
    }
    
    private func scheduleUpdateUnreadMessagesWorker() {
        let worker = DispatchWorkItem { [weak self] in
            guard let self = self else {
                return
            }
            
            if !self.loadUnreadMessagesCount(force: false) {
                self.scheduleUpdateUnreadMessagesWorker()
            }
        }
        
        self.updateUnreadMessagesWorker?.cancel()
        self.updateUnreadMessagesWorker = worker
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(Constants.checkUpdatePossibilitySeconds), execute: worker)
    }
    
    private func notifyObservers(with count: Int) -> Void {
        lastUpdateTimeInterval = ProcessInfo.processInfo.systemUptime
        
        scheduleUpdateUnreadMessagesWorker()
        
        guard unreadMessagesCount != count else {
            return
        }
        
        queue.sync {
            unreadMessagesCount = count
            
            removeNilObservers()

            for observer in strongObservers {
                observer.unreadMessagesCountChanged(count)
            }
        }
    }


    private func removeNilObservers() {
        observers = observers.filter { nil != $0.value }
    }
}
