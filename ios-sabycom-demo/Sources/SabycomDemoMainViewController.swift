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
    
    private enum Keys {
        static let userId = "SabycomUser.Id"
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
        
        let clearButton = UIButton(type: .custom)
        clearButton.translatesAutoresizingMaskIntoConstraints = false
        clearButton.setTitleColor(.blue, for: .normal)
        clearButton.setTitle("Сбросить пользователя", for: .normal)
        clearButton.addTarget(self, action: #selector(onClearUserClicked(_:)), for: .touchUpInside)
        view.addSubview(clearButton)
        
        view.addSubview(unreadCountLabel)
        view.addSubview(userIdLabel)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            clearButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            clearButton.topAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            unreadCountLabel.leftAnchor.constraint(equalTo: view.leftAnchor, constant: Constants.margin),
            unreadCountLabel.rightAnchor.constraint(equalTo: view.rightAnchor, constant: Constants.margin),
            unreadCountLabel.topAnchor.constraint(equalTo: clearButton.bottomAnchor, constant: Constants.margin)
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
    
    @objc private func onClearUserClicked(_ sender: UIButton) {
        UserDefaults.standard.removeObject(forKey: Keys.userId)
        
        let alert = UIAlertController(title: "Пользователь сброшен", message: "Чтобы зарегистрировать нового пользователя, перезагрузите приложение", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func registerUser() {
        let user = SabycomUser(uuid: getUserId(), name: "John", surname: "Doe", email: "John.Doe1@paradise.com", phone: "+1234567890")
        Sabycom.registerUser(user)
    }
    
    private func getUnreadConversationsCount() {
        Sabycom.getUnreadConversationCount { [weak unreadCountLabel] count in
            unreadCountLabel?.text = "Количество сообщений: \(count)"
        }
    }
    
    private func getUserId() -> String {
        guard let userId = UserDefaults.standard.string(forKey: Keys.userId) else {
            let id = UUID().uuidString
            UserDefaults.standard.setValue(id, forKey: Keys.userId)
            return id
        }
        
        return userId
    }
    
}

