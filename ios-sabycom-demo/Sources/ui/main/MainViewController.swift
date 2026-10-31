//
//  MainViewController.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 07.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import UIKit

class MainViewController: UIViewController {
    private enum Constants {
        static let margin: CGFloat = 16
    }
    
    private let sabycomService: SabycomService
    private let notificationService: NotificationService
    
    private lazy var badgeLabel: UILabel = {
        let label = UILabel(frame: CGRect(x: 20, y: 0, width: 20, height: 20))
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
    
    required init(sabycomService: SabycomService = DIContainer.shared.resolve(type: SabycomService.self)!,
                  notificationService: NotificationService = DIContainer.shared.resolve(type: NotificationService.self)!) {
        self.sabycomService = sabycomService
        self.notificationService = notificationService
        
        sabycomService.configureSabycom()
        
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
        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        rightButton.setImage(UIImage(named: "saby_logo"), for: .normal)
        rightButton.addTarget(self, action: #selector(onSabycom(_:)), for: .touchUpInside)
        rightButton.addSubview(badgeLabel)

        let rightBarButtomItem = UIBarButtonItem(customView: rightButton)
        navigationItem.rightBarButtonItem = rightBarButtomItem
    }
    
    private func updateUnreadMessagesCount() {
        let count = sabycomService.unreadConversationCount
        
        if count > 0 {
            badgeLabel.isHidden = false
            badgeLabel.text = "\(count)"
        } else {
            badgeLabel.isHidden = true
        }
    }
    @objc
    private func onSabycom(_ sender: Any) {
        sabycomService.show(on: self, pushInfo: nil)
    }
    
    deinit {
        if let unreadMessagesObserver = unreadMessagesObserver {
            NotificationCenter.default.removeObserver(unreadMessagesObserver)
        }
    }
}
