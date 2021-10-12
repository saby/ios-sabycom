//
//  CreateUserPresenter.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 08.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Foundation
import Sabycom

protocol CreateUserView: AnyObject {
    var viewDidLoadHandler: (() -> Void)? { get set }
    
    var didChangeName: ((_ name: String) -> Void)? { get set }
    var didChangeSurname: ((_ surname: String) -> Void)? { get set }
    var didChangePhone: ((_ phone: String) -> Void)? { get set }
    var didChangeEmail: ((_ email: String) -> Void)? { get set }
    
    var onSaveClicked: (() -> Void)? { get set }
    
    func update(with model: CreateUserModel)
    
    func clearRequiredFields()
}

class CreateUserPresenter {
    private let interactor: CreateUserInteractor
    private let router: CreateUserRouter
    private weak var view: CreateUserView?
    
    private var model = CreateUserModel()
    
    init(interactor: CreateUserInteractor,
         view: CreateUserView,
         router: CreateUserRouter) {
        self.interactor = interactor
        self.view = view
        self.router = router
        
        setHandlers()
    }
    
    private func saveUser() {
        model.markNameRequired = model.name.isEmpty
        model.markSurnameRequired = model.surname.isEmpty
        
        if model.isValid {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    return
                }
                
                self.interactor.createOrUpdateUser(name: self.model.name,
                                                   surname: self.model.surname,
                                                   email: self.model.email,
                                                   phone: self.model.phone)
                
                DispatchQueue.main.async { [weak self] in
                    self?.router.performAction(.dismiss)
                }
            }
        } else {
            router.performAction(.showError(ErrorMessage.requiredFieldsIsEmpty))
            view?.update(with: model)
        }
    }
    
    private func setHandlers() {
        view?.viewDidLoadHandler = { [weak self] in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let user = self?.interactor.getCurrentUser()
                
                let model = CreateUserModel(name: user?.name ?? "",
                                            surname: user?.surname ?? "",
                                            email: user?.email ?? "",
                                            phone: user?.phone ?? "")
                DispatchQueue.main.async { [weak self] in
                    self?.model = model
                    self?.view?.update(with: model)
                }
            }
        }
        
        view?.didChangeName = { [weak self] name in
            self?.model.name = name
            self?.view?.clearRequiredFields()
        }
        
        view?.didChangeSurname = { [weak self] surname in
            self?.model.surname = surname
            self?.view?.clearRequiredFields()
        }
        
        view?.didChangeEmail = { [weak self] email in
            self?.model.email = email
            self?.view?.clearRequiredFields()
        }
        
        view?.didChangePhone = { [weak self] phone in
            self?.model.phone = phone
            self?.view?.clearRequiredFields()
        }
        
        view?.onSaveClicked = { [weak self] in
            self?.saveUser()
        }
    }
    
    private enum ErrorMessage {
        static let requiredFieldsIsEmpty = "Заполните обязательные поля"
    }
}
