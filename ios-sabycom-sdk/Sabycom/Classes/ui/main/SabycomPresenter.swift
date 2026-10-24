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
    
    func startedLoading()
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
    }
    
    deinit {
        if let appWillEnterForegroundObserver = appWillEnterForegroundObserver {
            NotificationCenter.default.removeObserver(appWillEnterForegroundObserver)
        }
    }
    
    private func setViewHandlers() {
        view?.didLoadView = { [weak view, weak interactor] in
            view?.startedLoading()
            
            if let url = interactor?.getUrl() {
                view?.load(url)
            }
        }
    }
    
    private func subscribeApplicationStateChanges() {
        appWillEnterForegroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main) { [weak view, weak interactor] _ in
                if let url = interactor?.getUrl() {
                    view?.load(url)
                }
            }
    }
}
