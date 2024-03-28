//
//  ConfigurationPresenter.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 07.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Sabycom

protocol ConfigurationView: AnyObject {
    var viewDidLoadHandler: (() -> Void)? { get set }
    var viewWillAppearHandler: (() -> Void)? { get set }
    
    var onCreateUserClicked: (() -> Void)? { get set }
    var onDeleteUserClicked: (() -> Void)? { get set }
    var onStartClicked: (() -> Void)? { get set }
    var onStartAnonymousClicked: (() -> Void)? { get set }
    
    var onHostChanged: ((_ host: SabycomHost.HostType) -> Void)? { get set }
    
    var onAppIdChanged: ((_ appId: String) -> Void)? { get set }
    
    func update(with user: SabycomUser?)
    func updateAppId(_ appId: String)
    func updateHost(_ hostType: SabycomHost.HostType)
    
    func showConfirmDeleteUserAlert(_ positiveCompletion: (() -> Void)?)
 
    func showErrorAlert(with message: String)
}

class ConfigurationPresenter {
    private let interactor: ConfigurationInteractor
    private let router: ConfigurationRouter
    
    private weak var view: ConfigurationView?
    
    init(interactor: ConfigurationInteractor,
         view: ConfigurationView,
         router: ConfigurationRouter) {
        self.interactor = interactor
        self.view = view
        self.router = router
        
        setHandlers()
    }
    
    private func setHandlers() {
        view?.viewWillAppearHandler = { [weak interactor, weak view] in
            DispatchQueue.global(qos: .userInitiated).async { [weak interactor, weak view] in
                let user = interactor?.getCurrentUser()
                let host = interactor?.getCurrentHostType() ?? .prod
                let appId = interactor?.getCurrentAppId() ?? ""
                DispatchQueue.main.async { [weak view] in
                    view?.update(with: user)
                    view?.updateHost(host)
                    view?.updateAppId(appId)
                }
            }
        }
        
        view?.onHostChanged = { [weak interactor] hostType in
            interactor?.saveHost(hostType)
        }
        
        view?.onAppIdChanged = { [weak interactor, weak view] appId in
            guard let _ = UUID(uuidString: appId) else {
                view?.showErrorAlert(with: "Введите корректный идентификатор канала")
                return
            }
            interactor?.saveAppId(appId)
        }
        
        view?.onCreateUserClicked = { [weak router] in
            router?.performAction(.createOrEditUser)
        }
        
        view?.onDeleteUserClicked = { [weak self] in
            self?.view?.showConfirmDeleteUserAlert { [weak self] in
                DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                    self?.interactor.deleteCurrentUser()
                    
                    DispatchQueue.main.async { [weak self] in
                        self?.view?.update(with: nil)
                    }
                }
            }
        }
        
        view?.onStartClicked = { [weak self] in
            self?.start()
        }
    
        view?.onStartAnonymousClicked = { [weak self] in
            self?.startAnonymous()
        }
    }
    
    private func start() {
        guard interactor.getCurrentAppId() != nil else {
            router.performAction(.showError(ErrorMessage.appIdIsEmpty))
            return
        }
        
        guard interactor.getCurrentUser() != nil else {
            router.performAction(.showError(ErrorMessage.userIsEmpty))
            return
        }
        
        interactor.clearAnonymousUser()
        
        router.performAction(.goToMain)
    }
    
    private func startAnonymous() {
        interactor.registerAnonymousUser()
        
        router.performAction(.goToMain)
    }
    
    private enum ErrorMessage {
        static let userIsEmpty = "Для начала создайте пользователя"
        static let appIdIsEmpty = "Введите идентификатор канала"
    }
}
