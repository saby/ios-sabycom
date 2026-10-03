//
//  ReachabilityService.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 17.01.2022.
//

import Foundation

protocol ReachabilityObservable: AnyObject {
    func reachabilityChanged(_ available: Bool)
}

protocol ReachabilityService {
    var isAvailable: Bool { get }
    
    func registerObserver(_ observer: ReachabilityObservable)
    func unregisterObserver(_ observer: ReachabilityObservable)
}

class ReachabilityServiceImpl: ReachabilityService {
    var isAvailable: Bool {
        guard let reachability = reachability else {
            return false
        }
        
        return reachability.currentReachabilityStatus == .reachableViaWWAN || reachability.currentReachabilityStatus == .reachableViaWiFi
    }
    
    private let reachability: Reachability?
    
    private let queue = DispatchQueue(label: "ReachabilityObservable", qos: .userInitiated)
    
    private var observers: [Weak<ReachabilityObservable>] = []
    private var strongObservers: [ReachabilityObservable] {
        return observers.compactMap { $0.value }
    }
    
    init() {
        self.reachability = try? Reachability.reachabilityForInternetConnection()
        
        reachability?.whenReachable = { [weak self] _ in
            self?.notifyObservers(true)
        }
        
        reachability?.whenUnreachable = { [weak self] _ in
            self?.notifyObservers(false)
        }
        
        try? reachability?.startNotifier()
    }
    
    deinit {
        reachability?.stopNotifier()
    }
    
    func registerObserver(_ observer: ReachabilityObservable) {
        queue.async { [self] in
            if self.observers.contains(where: { $0.value === observer }) {
                return
            }
            self.observers.append(Weak(value: observer))
        }
    }

    func unregisterObserver(_ observer: ReachabilityObservable) {
        queue.sync {
            observers = observers.filter { $0.value !== observer }
        }
    }
    
    private func notifyObservers(_ available: Bool) {
        queue.sync {
            removeNilObservers()

            for observer in strongObservers {
                observer.reachabilityChanged(available)
            }
        }
    }


    private func removeNilObservers() {
        observers = observers.filter { nil != $0.value }
    }
}
