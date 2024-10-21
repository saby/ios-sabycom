//
//  SabycomWidgetJSHandler.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 28.09.2021.
//

import WebKit

final class SabycomWidgetJSHandler: NSObject {
    weak var delegate: SabycomWidgetJSHandlerDelegate?
    
    private var scriptToInject: WKUserScript = {
        let scriptString = """
            window.mobileParent = {
                postMessage: function(data, origin) {
                    window.webkit.messageHandlers.mobileParent.postMessage(data);
                }
            };
        """
        
        let script = WKUserScript(source: scriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        return script
    }()
        
    func addTo(controller: WKUserContentController) {
        controller.add(self, name: "mobileParent")
        controller.addUserScript(scriptToInject)
    }
}

// MARK: - WKScriptMessageHandler
extension SabycomWidgetJSHandler: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let message = message.body as? String else {
            assertionFailure("Expected a string")
            return
        }

        if let data = message.data(using: .utf8), let dict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            if let action = dict["action"] as? String {
                switch action {
                case "toggleWindow":
                    let closed = dict["value"] as? Bool
                    if closed == false {
                        delegate?.didClickClose()
                    }
                case "unreadChange":
                    if let count = dict["value"] as? Int {
                        delegate?.didReceiveNewMessage(unreadCount: count)
                    }
                default:
                    break
                }
            }
        }
    }
}

protocol SabycomWidgetJSHandlerDelegate: AnyObject {
    func didClickClose()
    func didReceiveNewMessage(unreadCount: Int)
}
