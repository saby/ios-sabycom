//
//  SabycomWidgetJSHandler.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 28.09.2021.
//

import WebKit

final class SabycomWidgetJSHandler: NSObject {
    weak var delegate: SabycomWidgetJSHandlerDelegate?
}

// MARK: - WKScriptMessageHandler
extension SabycomWidgetJSHandler: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        // TODO: Доделать обработчик
        guard let message = message.body as? String else {
//            assertionFailure("Expected a string")
            return
        }

//        delegate?.didClickClose()
    }
}

protocol SabycomWidgetJSHandlerDelegate: AnyObject {
    func didClickClose()
    func didReceiveNewMessage()
}
