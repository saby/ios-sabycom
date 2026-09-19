//
//  CreateUserViewController.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 08.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import UIKit

class CreateUserViewController: UIViewController, CreateUserView {
    private enum Constants {
        static let margin: CGFloat = 16
        
        static let textFieldHeight: CGFloat = 50
        
        static let textFieldsSpacing: CGFloat = 16
    }
    
    var presenter: CreateUserPresenter?
    
    var viewDidLoadHandler: (() -> Void)?
    
    var didChangeName: ((_ name: String) -> Void)?
    var didChangeSurname: ((_ surname: String) -> Void)?
    var didChangePhone: ((_ phone: String) -> Void)?
    var didChangeEmail: ((_ email: String) -> Void)?
    
    var onSaveClicked: (() -> Void)?
    
    private lazy var textFieldsStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .equalSpacing
        stackView.alignment = .fill
        stackView.spacing = Constants.textFieldsSpacing
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private lazy var nameTextField: TextField = {
        let textField = createDefaultTextField()
        textField.placeholder = "Имя"
        return textField
    }()
    
    private lazy var surnameTextField: TextField = {
        let textField = createDefaultTextField()
        textField.placeholder = "Фамилия"
        return textField
    }()
    
    private lazy var emailTextField: TextField = {
        let textField = createDefaultTextField()
        textField.placeholder = "Email"
        textField.keyboardType = .emailAddress
        return textField
    }()
    
    private lazy var phoneTextField: TextField = {
        let textField = createDefaultTextField()
        textField.placeholder = "Телефон"
        textField.keyboardType = .phonePad
        return textField
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        setupViews()
        setupTextFieldsHandlers()
        createSaveButton()
        
        viewDidLoadHandler?()
    }
    
    func update(with model: CreateUserModel) {
        nameTextField.text = model.name
        surnameTextField.text = model.surname
        phoneTextField.text = model.phone
        emailTextField.text = model.email
        
        nameTextField.isErrorMode = model.markNameRequired
        surnameTextField.isErrorMode = model.markSurnameRequired
        phoneTextField.isErrorMode = model.markPhoneRequired
        emailTextField.isErrorMode = model.markEmailRequired
    }
    
    func clearRequiredFields() {
        nameTextField.isErrorMode = false
        surnameTextField.isErrorMode = false
        phoneTextField.isErrorMode = false
        emailTextField.isErrorMode = false
    }
    
    private func setupViews() {
        view.addSubview(textFieldsStackView)
        
        textFieldsStackView.addArrangedSubview(nameTextField)
        textFieldsStackView.addArrangedSubview(surnameTextField)
        textFieldsStackView.addArrangedSubview(phoneTextField)
        textFieldsStackView.addArrangedSubview(emailTextField)
        
        NSLayoutConstraint.activate([
            textFieldsStackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Constants.margin),
            textFieldsStackView.widthAnchor.constraint(equalTo: view.widthAnchor, constant: -2 * Constants.margin),
            textFieldsStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        NSLayoutConstraint.activate(textFieldsStackView.arrangedSubviews.map { $0.heightAnchor.constraint(equalToConstant: Constants.textFieldHeight)})
    }
    
    private func setupTextFieldsHandlers() {
        nameTextField.didChange = { [weak self] in
            self?.didChangeName?(self?.nameTextField.text ?? "")
        }
        
        surnameTextField.didChange = { [weak self] in
            self?.didChangeSurname?(self?.surnameTextField.text ?? "")
        }
        
        emailTextField.didChange = { [weak self] in
            self?.didChangeEmail?(self?.emailTextField.text ?? "")
        }
        
        phoneTextField.didChange = { [weak self] in
            self?.didChangePhone?(self?.phoneTextField.text ?? "")
        }
    }
    
    private func createSaveButton() {
        let button = UIBarButtonItem(title: "Сохранить", style: .done, target: self, action: #selector(onSave(_:)))
        navigationItem.rightBarButtonItem = button
    }
    
    private func createDefaultTextField() -> TextField {
        let textField = TextField()
        textField.activeColor = UIColor(named: "accent")
        textField.defaultColor = .gray
        textField.errorColor = .red
        return textField
    }
    
    @objc
    private func onSave(_ sender: Any) {
        onSaveClicked?()
    }
}
