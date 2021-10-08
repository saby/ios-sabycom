//
//  TextField.swift
//  ios-sabycom-demo
//
//  Created by Sergey Iskhakov on 08.10.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import UIKit

class TextField: UITextField, UITextFieldDelegate {
    
    var defaultColor: UIColor? {
        didSet {
            self.updateColors()
        }
    }
    
    var activeColor: UIColor? {
        didSet {
            self.updateColors()
        }
    }
    
    var errorColor: UIColor? {
        didSet {
            self.updateColors()
        }
    }
    
    var isErrorMode = false {
        didSet {
            self.updateColors()
        }
    }
    
    var shouldBeginEditing : (() -> Bool)? {
        didSet {
            delegateIfNeeded()
        }
    }
    var didBeginEditing : (() -> ())? {
        didSet {
            delegateIfNeeded()
        }
    }
    var shouldEndEditing : (() -> Bool)? {
        didSet {
            delegateIfNeeded()
        }
    }
    var didEndEditing : (() -> ())? {
        didSet {
            delegateIfNeeded()
        }
    }
    var shouldChangeCharactersInRange : ((_ range: NSRange, _ replacement: String) -> Bool)?{
        didSet{
            delegateIfNeeded()
        }
    }
    var shouldClear : (() -> Bool)?{
        didSet {
            delegateIfNeeded()
        }
    }
    var shouldReturn : (() -> Bool)?{
        didSet {
            delegateIfNeeded()
        }
    }
    
    var didChange : (() -> ())? {
        didSet {
            delegateIfNeeded()
        }
    }
    
    private lazy var underlineView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = getPassiveColor()
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func delegateIfNeeded() -> Void {
        if self.delegate == nil {
            self.delegate = self
        } else if !self.delegate!.isEqual(self){
            self.delegate = self
        }
    }
    
    private func getActiveColor() -> UIColor? {
        guard !isErrorMode else {
            return errorColor
        }
        
        return activeColor
    }
    
    private func getPassiveColor() -> UIColor? {
        guard !isErrorMode else {
            return errorColor
        }
        
        return defaultColor
    }
    
    
    private func updateColors(){
        underlineView.backgroundColor = isEditing ? getActiveColor() : getPassiveColor()
        textColor = isEditing ? getActiveColor() : getPassiveColor()
    }
    
    @objc func textFieldDidChange(textField: UITextField) -> Void {
        didChange?()
        setNeedsDisplay()
    }
    
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        return shouldBeginEditing?() ?? true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        updateColors()
        didBeginEditing?()
    }
    
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        return shouldEndEditing?() ?? true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField, reason: UITextField.DidEndEditingReason) {
        updateColors()
        didEndEditing?()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return shouldChangeCharactersInRange?(range, string) ?? true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        return shouldClear?() ?? true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return shouldReturn?() ?? true
    }
    
    private func initialize(){
        self.addTarget(self, action:#selector(textFieldDidChange(textField:)), for: .editingChanged)
        
        self.delegateIfNeeded()
        
        self.addSubview(underlineView)
        NSLayoutConstraint.activate([
            underlineView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 0),
            underlineView.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: 0),
            underlineView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: 1),
            underlineView.heightAnchor.constraint(equalToConstant: 1)
        ])
    }
}
