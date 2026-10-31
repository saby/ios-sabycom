//
//  SabycomDemoMainViewController.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 08/10/2021.
//  Copyright (c) 2021 Tensor. All rights reserved.
//

import UIKit
import Sabycom

class SabycomDemoMainViewController: UIViewController {
    private enum Constants {
        static let margin: CGFloat = 16
    }
    
    private lazy var unreadCountLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var userIdLabel: UILabel = {
        let label = UILabel()
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 5
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.blue, for: .normal)
        button.setTitle("Получить поддержку", for: .normal)
        button.addTarget(self, action: #selector(onHelpClicked(_:)), for: .touchUpInside)
        view.addSubview(button)
        
        view.addSubview(unreadCountLabel)
        view.addSubview(userIdLabel)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            unreadCountLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Constants.margin),
            unreadCountLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: Constants.margin),
            unreadCountLabel.topAnchor.constraint(equalTo: button.bottomAnchor, constant: Constants.margin)
        ])
        
        NSLayoutConstraint.activate([
            userIdLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Constants.margin),
            userIdLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: Constants.margin),
            userIdLabel.topAnchor.constraint(equalTo: unreadCountLabel.bottomAnchor, constant: Constants.margin)
        ])
        
        registerUser()
        getUnreadConversationsCount()
    }
    
    @objc private func onHelpClicked(_ sender: UIButton) {
        Sabycom.show(on: self)
    }
    
    private func registerUser() {
        let user = SabycomUser(uuid: UUID().uuidString, name: "John", surname: "Doe", email: "John.Doe@paradise.com", phone: "+1234567890")
        Sabycom.registerUser(user) { [weak userIdLabel] userId in
            if let userId = userId {
                userIdLabel?.text = "Пользователь зарегистрирован: \(userId)"
            } else {
                userIdLabel?.text = "Ошибка при регистрации пользователя"
            }
        }
    }
    
    private func getUnreadConversationsCount() {
        Sabycom.getUnreadConversationCount { [weak unreadCountLabel] count in
            unreadCountLabel?.text = "Количество сообщений: \(count)"
        }
    }
}

