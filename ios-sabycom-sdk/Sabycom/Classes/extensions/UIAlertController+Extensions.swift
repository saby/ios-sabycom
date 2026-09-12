//
//  UIAlertController+Extensions.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 18.01.2022.
//

import UIKit

extension UIAlertController {
    class func showNetworkNotAvailableAlert(on controller: UIViewController) {
        let errorTitle = Localization.shared.text(forKey: .errorTitle)
        let message = Localization.shared.text(forKey: .networkNotAvailable)
        let okButtonTitle = Localization.shared.text(forKey: .okButtonTitle)
        let alert = UIAlertController(title: errorTitle, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: okButtonTitle, style: .cancel, handler: nil))
        controller.present(alert, animated: true, completion: nil)
    }
}
 
