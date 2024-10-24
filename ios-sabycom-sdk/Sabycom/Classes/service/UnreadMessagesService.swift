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

protocol UnreadMessagesService {
    var user: SabycomUser? { get set }
    var appId: String? { get set }
    var unreadMessagesCount: Int { get }
    
    func updateUnreadMessagesCount(_ count: Int)
    
    func registerObserver(_ observer: UnreadMessagesCountObservable)
    func unregisterObserver(_ observer: UnreadMessagesCountObservable)
}

class UnreadMessagesServiceImpl: UnreadMessagesService {
    private enum Constants {
        static let minUpdateTimeInterval: TimeInterval = 5
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
    
    init(api: Api) {
        self.api = api
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

    private func loadUnreadMessagesCount(force: Bool) {
        if let uuid = user?.uuid, let appId = appId {
            let timePassedInterval = ProcessInfo.processInfo.systemUptime - (lastUpdateTimeInterval ?? 0)
            if force || lastUpdateTimeInterval == nil || timePassedInterval >= Constants.minUpdateTimeInterval {
                lastUpdateTimeInterval = ProcessInfo.processInfo.systemUptime
                
                api.getUnreadConversationCount(for: uuid, channedUUID: appId) { [weak self] count in
                    self?.notifyObservers(with: count)
                }
            }
        }
    }
    
    private func notifyObservers(with count: Int) -> Void {
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
