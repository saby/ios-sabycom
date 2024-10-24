//
//  CreateUserRouter.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 08.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import UIKit

protocol CreateUserRouter {
    func performAction(_ action: CreateUserRouterAction)
}

enum CreateUserRouterAction {
    case dismiss
    case showError(String)
}

class CreateUserRouterImpl: CreateUserRouter {
    private weak var navigationController: UINavigationController?
    
    init(navigationController: UINavigationController?) {
        self.navigationController = navigationController
    }
    
    func performAction(_ action: CreateUserRouterAction) {
        switch action {
        case .dismiss:
            navigationController?.popViewController(animated: true)
        case .showError(let errorMessage):
            show(errorMessage: errorMessage)
        }
    }
    
    private func show(errorMessage: String) {
        let alert = UIAlertController(title: "Ошибка", message: errorMessage, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ок", style: .cancel, handler: nil))
        navigationController?.present(alert, animated: true, completion: nil)
    }
}
