//
//  ConfigurationViewController.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 08/10/2021.
//  Copyright (c) 2021 Tensor. All rights reserved.
//

import UIKit
import Sabycom

class ConfigurationViewController: UIViewController, ConfigurationView {
    private enum Constants {
        static let margin: CGFloat = 16
        
        static let pickerViewMargin: CGFloat = 16
        static let pickerViewHeight: CGFloat = 120
        
        static let appIdTextFieldHeight: CGFloat = 50
        
        static let userInfoTopMargin: CGFloat = 50
        
        static let startButtonHeight: CGFloat = 50
        static let startButtonTopMargin: CGFloat = 24
        
        static let backgroundColor = UIColor(named: "darkBackground")!
        
        static let accentColor = UIColor(named: "accent")!
    }
    
    private enum Keys {
        static let userId = "SabycomUser.Id"
    }
    
    private lazy var userStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = Constants.margin
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var addUserButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(.white, for: .normal)
        button.setTitle("+ Создать пользователя", for: .normal)
        button.addTarget(self, action: #selector(onCreateUser(_:)), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        return button
    }()
    
    private lazy var appIdTextField: TextField = {
        let textField = TextField()
        textField.activeColor = UIColor(named: "accent")
        textField.defaultColor = .white
        textField.errorColor = .red
        textField.attributedPlaceholder = NSAttributedString(string: "App Id", attributes: [.foregroundColor : UIColor.white])
        return textField
    }()
    
    private lazy var userInfoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.spacing = 5
        stackView.alignment = .fill
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        stackView.addArrangedSubview(usernameLabel)
        stackView.addArrangedSubview(phoneLabel)
        stackView.addArrangedSubview(emailLabel)
        stackView.addArrangedSubview(editUserButton)
        stackView.addArrangedSubview(removeUserButton)
        return stackView
    }()
    
    private lazy var usernameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        label.numberOfLines = 2
        return label
    }()

    private lazy var phoneLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var editUserButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(Constants.accentColor, for: .normal)
        button.setTitle("Редактировать пользователя", for: .normal)
        button.addTarget(self, action: #selector(onCreateUser(_:)), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        return button
    }()
    
    private lazy var removeUserButton: UIButton = {
        let button = UIButton()
        button.setTitleColor(Constants.accentColor, for: .normal)
        button.setTitle("Удалить пользователя", for: .normal)
        button.addTarget(self, action: #selector(onDeleteUser(_:)), for: .touchUpInside)
        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        return button
    }()
    
    private lazy var serverPickerView: UIPickerView = {
        let serverPickerView = UIPickerView(frame: CGRect(origin: .zero, size: CGSize(width: view.frame.width, height: Constants.pickerViewHeight)))
        serverPickerView.translatesAutoresizingMaskIntoConstraints = false
        serverPickerView.delegate = self
        serverPickerView.dataSource = self
        serverPickerView.selectRow(0, inComponent: 0, animated: false)
        return serverPickerView
    }()
    
    private lazy var startButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        button.addTarget(self, action: #selector(goToMain(_:)), for: .touchUpInside)
        button.setBackgroundImage(Constants.accentColor.image(), for: .normal)
        button.setTitle("Начать", for: .normal)
        button.setTitleColor(.white, for: .normal)
        return button
    }()
    
    var presenter: ConfigurationPresenter!
    
    var viewDidLoadHandler: (() -> Void)?
    
    var viewWillAppearHandler: (() -> Void)?
    
    var onCreateUserClicked: (() -> Void)?
    var onDeleteUserClicked: (() -> Void)?
    var onStartClicked: (() -> Void)?
    var onHostChanged: ((SabycomHost.HostType) -> Void)?
    var onAppIdChanged: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupViews()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tappedAround)))
        
        viewDidLoadHandler?()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewWillAppearHandler?()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        startButton.layer.cornerRadius = startButton.bounds.height / 2
    }
    
    func update(with user: SabycomUser?) {
        if let user = user {
            userInfoStackView.isHidden = false
            addUserButton.isHidden = true
            
            var name = [user.name, user.surname].compactMap { $0 }.joined(separator: " ")
            if name.isEmpty {
                name = "Пустое имя пользователя"
            }
            usernameLabel.text = name
            phoneLabel.text = user.phone
            emailLabel.text = user.email
        } else {
            userInfoStackView.isHidden = true
            addUserButton.isHidden = false
        }
    }
    
    func updateAppId(_ appId: String) {
        appIdTextField.text = appId
    }
    
    func updateHost(_ hostType: SabycomHost.HostType) {
        if let index = SabycomHost.HostType.allCases.firstIndex(of: hostType) {
            serverPickerView.selectRow(index, inComponent: 0, animated: false)
        }
    }
    
    func showConfirmDeleteUserAlert(_ positiveCompletion: (() -> Void)?) {
        let alert = UIAlertController(title: "Удалить пользователя?", message: nil, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Да", style: .default, handler: { _ in
            positiveCompletion?()
        }))
        alert.addAction(UIAlertAction(title: "Нет", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    @objc
    private func tappedAround(_ sender: Any) {
        view.endEditing(true)
    }
    
    private func setupViews() {
        view.backgroundColor = Constants.backgroundColor
        
        view.addSubview(userStackView)
        
        userStackView.addArrangedSubview(addUserButton)
        userStackView.addArrangedSubview(userInfoStackView)
        userStackView.addArrangedSubview(appIdTextField)
        
        NSLayoutConstraint.activate([
            userStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.userInfoTopMargin),
            userStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.margin),
            userStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
        
        NSLayoutConstraint.activate([
            appIdTextField.heightAnchor.constraint(equalToConstant: Constants.appIdTextFieldHeight)
        ])
        
        view.addSubview(startButton)
        view.addSubview(serverPickerView)
        
        NSLayoutConstraint.activate([
            startButton.heightAnchor.constraint(equalToConstant: Constants.startButtonHeight),
            startButton.topAnchor.constraint(equalTo: userStackView.bottomAnchor, constant: Constants.startButtonTopMargin),
            startButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate([
            serverPickerView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.pickerViewMargin),
            serverPickerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            serverPickerView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            serverPickerView.heightAnchor.constraint(equalToConstant: Constants.pickerViewHeight)
        ])
        
        appIdTextField.didChange = { [weak self] in
            self?.onAppIdChanged?(self?.appIdTextField.text ?? "")
        }
    }
    
    @objc
    private func onCreateUser(_ sender: UIButton) {
        onCreateUserClicked?()
    }
    
    @objc
    private func onDeleteUser(_ sender: UIButton) {
        onDeleteUserClicked?()
    }
    
    @objc
    private func goToMain(_ sender: UIButton) {
        onStartClicked?()
    }
}

extension ConfigurationViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return SabycomHost.HostType.allCases.count
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        var pickerLabel: UILabel
        if let label = view as? UILabel {
            pickerLabel = label
        } else {
            pickerLabel = UILabel()
            pickerLabel.textColor = .white
            pickerLabel.textAlignment = .center
        }
        
        let hostType = SabycomHost.HostType.allCases[row]
        pickerLabel.text = hostType.visibleName
        
        return pickerLabel
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let host = SabycomHost.HostType.allCases[row]
        onHostChanged?(host)
    }
}
