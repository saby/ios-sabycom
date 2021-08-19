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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.black, for: .normal)
        button.setTitle("Получить поддержку", for: .normal)
        button.addTarget(self, action: #selector(onHelpClicked(_:)), for: .touchUpInside)
        view.addSubview(button)
        
        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func onHelpClicked(_ sender: UIButton) {
        Sabycom.show(on: self)
    }
}

