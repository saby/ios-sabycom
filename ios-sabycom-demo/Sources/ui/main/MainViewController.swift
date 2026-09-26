//
//  MainViewController.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 07.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import Foundation
import UIKit
import Sabycom

class MainViewController: UIViewController {
    private enum Constants {
        static let margin: CGFloat = 16
    }
    
    private let appId: String
    private let user: SabycomUser
    private let host: SabycomHost.HostType
    
    private lazy var badgeLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 10, y: -10, width: 20, height: 20))
        label.layer.cornerRadius = label.bounds.size.height / 2
        label.textAlignment = .center
        label.layer.masksToBounds = true
        label.font = .systemFont(ofSize: 12)
        label.textColor = .white
        label.backgroundColor = .red
        label.text = "0"
        label.isHidden = true
        label.isUserInteractionEnabled = false
        
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = .systemFont(ofSize: 16)
        label.textColor = .black
        label.textAlignment = .center
        label.numberOfLines = 0
        label.text = "Нажмите кнопку в правом верхнем углу, \nчтобы открыть виджет"
        
        return label
    }()
    
    private var unreadMessagesObserver: Any?
    
    required init(appId: String, user: SabycomUser, host: SabycomHost.HostType) {
        self.appId = appId
        self.user = user
        self.host = host
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupViews()
        createRightBarButtonItem()
        updateUnreadMessagesCount()
        
        Sabycom.initialize(appId: appId, host: host)
        Sabycom.registerUser(user)
        
        unreadMessagesObserver = NotificationCenter.default.addObserver(
            forName: .SabycomUnreadConversationCountDidChange,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.updateUnreadMessagesCount()
            }
    }
    
    private func setupViews() {
        view.addSubview(messageLabel)
        
        NSLayoutConstraint.activate([
            messageLabel.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.margin),
            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            messageLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func createRightBarButtonItem(){
        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        rightButton.setImage(UIImage(named: "saby_logo"), for: .normal)
        rightButton.addTarget(self, action: #selector(onSabycom(_:)), for: .touchUpInside)
        rightButton.addSubview(badgeLabel)

        let rightBarButtomItem = UIBarButtonItem(customView: rightButton)
        navigationItem.rightBarButtonItem = rightBarButtomItem
    }
    
    private func updateUnreadMessagesCount() {
        let count = Sabycom.unreadConversationCount
        
        if count > 0 {
            badgeLabel.isHidden = false
            badgeLabel.text = "\(count)"
        } else {
            badgeLabel.isHidden = true
        }
    }
    @objc
    private func onSabycom(_ sender: Any) {
        Sabycom.show(on: self)
    }
    
    deinit {
        if let unreadMessagesObserver = unreadMessagesObserver {
            NotificationCenter.default.removeObserver(unreadMessagesObserver)
        }
        Sabycom.destroy()
    }
}
