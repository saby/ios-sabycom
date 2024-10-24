//
//  ConfigurationRouter.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 07.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Foundation
import UIKit
import Sabycom

protocol ConfigurationRouter: AnyObject {
    func performAction(_ action: ConfigurationRouterAction)
}

enum ConfigurationRouterAction {
    case goToMain
    case createOrEditUser
    case showError(String)
}

class SabycomConfigurationRouterImpl: ConfigurationRouter {
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func performAction(_ action: ConfigurationRouterAction) {
        switch action {
        case .goToMain:
            goToMain()
        case .createOrEditUser:
            createOrEditUser()
        case .showError(let errorMessage):
            show(errorMessage: errorMessage)
        }
    }
    
    private func goToMain(){
        let controller = MainViewController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func createOrEditUser() {
        let interactor = CreateUserInteractor()
        let controller = CreateUserViewController()
        let router = CreateUserRouterImpl(navigationController: navigationController)
        let presenter = CreateUserPresenter(interactor: interactor, view: controller, router: router)
        controller.presenter = presenter
        
        navigationController?.pushViewController(controller, animated: true)
    }
    
    private func show(errorMessage: String) {
        let alert = UIAlertController(title: "Ошибка", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .cancel, handler: nil))
        navigationController?.present(alert, animated: true, completion: nil)
    }
}
