//
//  SabycomViewController.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 10.08.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import WebKit
import UIKit

class SabycomViewController: UIViewController, SabycomView {
    private enum Constants {
        static let popupCloseButtonSize: CGFloat = 44
        static let popupWebViewMargin: CGFloat = 16
        static let popupWebViewRatio: CGFloat = 0.75
        
        static let margin: CGFloat = 16

        static let containerBackgroundColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1)
        
        static let animationDuration: TimeInterval = 0.3
    }
    
    var presenter: SabycomPresenter!
    
    // MARK: - Private properties
    
    private var documentInteractionController: UIDocumentInteractionController?
    
    private var attachmentLoadingTask: URLSessionDataTask?
    private var attachmentLoadingTaskObservation: NSKeyValueObservation?
    
    private var delayProgressStart: DispatchWorkItem?
    
    private var _webView: WKWebView? = nil {
        didSet {
            _webView?.navigationDelegate = self
            _webView?.uiDelegate = self
            _webView?.scrollView.contentInsetAdjustmentBehavior = .never
        }
    }
    
    private lazy var webContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var webViewLoadIndicator: UIActivityIndicatorView = {
        let loadIndicator = UIActivityIndicatorView(style: .gray)
        loadIndicator.translatesAutoresizingMaskIntoConstraints = false
        loadIndicator.hidesWhenStopped = true
        return loadIndicator
    }()
    
    private lazy var attachmentProgressContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .black.withAlphaComponent(0.5)
        return view
    }()
    
    private lazy var attachmentProgressLabel: UILabel = {
        let view = UILabel()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.textColor = .white
        view.font = .systemFont(ofSize: 20)
        view.textAlignment = .center
        view.numberOfLines = 2
        return view
    }()
    
    private lazy var closeAttachmentProgressContainerButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage.named("ic_close"), for: .normal)
        button.addTarget(self, action: #selector(onCloseAttachmentDownloadingProgress(_:)), for: .touchUpInside)
        return button
    }()
    
    private lazy var errorLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 0
        label.textColor = .gray
        label.textAlignment = .center
        label.text = Localization.shared.text(forKey: .networkError)
        label.isHidden = true
        return label
    }()
    
    private lazy var jsHandler: SabycomWidgetJSHandler = {
        let handler = SabycomWidgetJSHandler()
        handler.delegate = self
        return handler
    }()
    
    /// Идет ли процесс создания WebView
    private var webViewInTheMaking = false
    /// Стэк запросов на обращение в WebView, нужен чтобы не запрашивать несколько раз создание webview.
    private var webViewRequestsStack = [(WKWebView)-> Void]()
    
    private var lastResponse: WebResponse?
    
    private var webContainerHeightConstraint: NSLayoutConstraint?
    
    private var keyboardWillShowObserver: Any?
    private var keyboardWillHideObserver: Any?
        
    deinit {
        attachmentLoadingTask?.cancel()
        attachmentLoadingTaskObservation?.invalidate()
    }
    
    //MARK: - SabycomView -
    
    var didLoadView: (() -> Void)?
    var viewWillAppear: (() -> Void)?
    var viewWillDisappear: (() -> Void)?
    
    var didFinishLoading: ((_ url: URL) -> Void)?
    var didFinishLoadingWindow: ((_ url: URL) -> Void)?
    var didFailLoading: ((_ error: Error?) -> Void)?
    
    var didUpdateUnreadMessagesCount: ((Int) -> Void)?
    
    func load(_ url: URL, fromCache: Bool) {
        guard isViewLoaded else {
            return
        }
        
        webview { webView in
            let cachePolicy: URLRequest.CachePolicy = fromCache ? .returnCacheDataDontLoad : .reloadIgnoringLocalCacheData
            let request = URLRequest(url: url, cachePolicy: cachePolicy)
            _ = webView.load(request)
        }
    }
    
    func update(with state: WebViewState) {
        guard isViewLoaded else {
            return
        }
        
        switch state {
        case .loading, .loadingFromArchive, .preparing:
            webContainer.isHidden = true
            webViewLoadIndicator.startAnimating()
            errorLabel.isHidden = true
            
        case .loaded:
            webContainer.isHidden = false
            webViewLoadIndicator.stopAnimating()
            errorLabel.isHidden = true
        case .error:
            webContainer.isHidden = true
            webViewLoadIndicator.stopAnimating()
            errorLabel.isHidden = false
        }
    }
    
    func createWebArchive(completion: @escaping (Data?) -> Void) {
        if #available(iOS 14.0, *) {
            _webView?.createWebArchiveData(completionHandler: { result in
                switch result {
                case .success(let data):
                    completion(data)
                case .failure:
                    completion(nil)
                }
            })
        } else {
            completion(nil)
        }
    }
    
    func evaluateJavaScript(_ script: String) {
        _webView?.evaluateJavaScript(script, completionHandler: nil)
    }
    
    // MARK: - Lifecycle
    
    override func loadView() {
        super.loadView()
        
        // Создадим webview
        webview(completion: {_ in })
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white

        setupViews()
        setupAttachmentProgressView()
        setupWebView()
        
        didLoadView?()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewWillAppear?()
        
        keyboardWillShowObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main) { [weak self] notification in
                guard let heightConstraint = self?.webContainerHeightConstraint,
                      let info = notification.userInfo,
                      let keyboardRect = (info[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                    return
                }

                heightConstraint.constant = -keyboardRect.height
            }
        
        keyboardWillHideObserver = NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main) { [weak self] _ in
            
                guard let heightConstraint = self?.webContainerHeightConstraint else {
                    return
                }
                
                heightConstraint.constant = 0
            }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        viewWillDisappear?()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    
        _webView?.stopLoading()
        _webView = nil
        
        if let keyboardWillShowObserver = keyboardWillShowObserver {
            NotificationCenter.default.removeObserver(keyboardWillShowObserver)
        }
        if let keyboardWillHideObserver = keyboardWillHideObserver {
            NotificationCenter.default.removeObserver(keyboardWillHideObserver)
        }
    }
    
    private func setupViews() {
        view.addSubview(webContainer)
        view.addSubview(errorLabel)
        view.addSubview(webViewLoadIndicator)
        
        let heightConstraint = webContainer.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 0)
        self.webContainerHeightConstraint = heightConstraint
        
        NSLayoutConstraint.activate([
            webContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webContainer.topAnchor.constraint(equalTo: view.topAnchor),
            heightConstraint
        ])
        
        NSLayoutConstraint.activate([
            webViewLoadIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            webViewLoadIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            errorLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Constants.margin),
            errorLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Constants.margin),
            errorLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func setupAttachmentProgressView() {
        view.addSubview(attachmentProgressContainerView)
        attachmentProgressContainerView.addSubview(closeAttachmentProgressContainerButton)
        attachmentProgressContainerView.addSubview(attachmentProgressLabel)
        
        attachmentProgressContainerView.isHidden = true
        
        NSLayoutConstraint.activate([
            attachmentProgressContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            attachmentProgressContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            attachmentProgressContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            attachmentProgressContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            closeAttachmentProgressContainerButton.trailingAnchor.constraint(equalTo: attachmentProgressContainerView.trailingAnchor),
            closeAttachmentProgressContainerButton.topAnchor.constraint(equalTo: attachmentProgressContainerView.topAnchor),
            closeAttachmentProgressContainerButton.heightAnchor.constraint(equalToConstant: Constants.popupCloseButtonSize),
            closeAttachmentProgressContainerButton.widthAnchor.constraint(equalToConstant: Constants.popupCloseButtonSize)
        ])
        
        NSLayoutConstraint.activate([
            attachmentProgressLabel.leadingAnchor.constraint(equalTo: attachmentProgressContainerView.leadingAnchor, constant: Constants.popupWebViewMargin),
            attachmentProgressLabel.trailingAnchor.constraint(equalTo: attachmentProgressContainerView.trailingAnchor, constant: -Constants.popupWebViewMargin),
            attachmentProgressLabel.centerYAnchor.constraint(equalTo: attachmentProgressContainerView.centerYAnchor)
        ])
    }
    
    @objc
    private func onCloseAttachmentDownloadingProgress(_ sender: UIButton) {
        cancelAttachmentDownloading()
        hideAttachmentDownloadingProgress()
    }
    
    // MARK: - WebPage helpers
    
    private func setupWebView() {
        guard let webView = _webView, isViewLoaded else {
            return
        }
        
        webContainer.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.leftAnchor.constraint(equalTo: webContainer.leftAnchor),
            webView.topAnchor.constraint(equalTo: webContainer.topAnchor),
            webView.rightAnchor.constraint(equalTo: webContainer.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: webContainer.bottomAnchor)
        ])
                
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.scrollView.delegate = self
    }
    
    private func webview(completion: @escaping (WKWebView) -> Void) {
        webViewRequestsStack.append(completion)
        executeWebViewRequests()
    }
    
    private func executeWebViewRequests() {
        // Если webview в процессе создания - ждем.
        if webViewInTheMaking {
            return
        }
        // Если webview не создано - запускаем процес инициализации.
        guard let webView = _webView else {
            webViewInTheMaking = true
            
            let preferences = WKPreferences()
            preferences.javaScriptEnabled = true
            preferences.javaScriptCanOpenWindowsAutomatically = true
            
            let configuration = WKWebViewConfiguration()
            configuration.preferences = preferences
            configuration.suppressesIncrementalRendering = true
            configuration.dataDetectorTypes = [.all]
            configuration.allowsInlineMediaPlayback = true
            
            let contentController = WKUserContentController()
            jsHandler.addTo(controller: contentController)
            
            configuration.userContentController = contentController
            
            _webView = WKWebView(frame: view.bounds, configuration: configuration)
            
            setupWebView()
            webViewInTheMaking = false
            executeWebViewRequests()
                        
            return
        }
        webViewRequestsStack.forEach {
            $0(webView)
        }
        webViewRequestsStack.removeAll()
    }
    
    // MARK: - Attachments downloading -
    
    private func share(url: URL?) {
        guard presenter.isInternetAvailable else {
            UIAlertController.showNetworkNotAvailableAlert(on: self)
            return
        }
        
        if let url = url {
            
            updateProgressLabel(with: 0)
            showAttachmentDownloadingProgress()
            cancelAttachmentDownloading()
            
            let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
                guard let self = self, let data = data, error == nil else {
                    DispatchQueue.main.async { [weak self] in
                        self?.hideAttachmentDownloadingProgress()
                    }
                    return
                }
                
                let tmpURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent(response?.suggestedFilename ?? "fileName.png")
                
                do {
                    try data.write(to: tmpURL)
                    DispatchQueue.main.async { [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.hideAttachmentDownloadingProgress()
                        self.showDocumentInteractionController(with: tmpURL)
                    }
                } catch {
                    print(error)
                }

            }
            
            attachmentLoadingTaskObservation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
                DispatchQueue.main.async { [weak self] in
                    self?.updateProgressLabel(with: progress.fractionCompleted)
                }
            }
            
            attachmentLoadingTask = task
            attachmentLoadingTask?.resume()
        }
    }
    
    private func showDocumentInteractionController(with url: URL) {
        let documentInteractionController = UIDocumentInteractionController()
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent

        let frame = CGRect(x: view.frame.width / 2 - 1, y: view.frame.height / 2 - 1, width: 2, height: 2)
        documentInteractionController.presentOptionsMenu(from: frame, in: view, animated: true)
        
        self.documentInteractionController = documentInteractionController
    }
    
    private func updateProgressLabel(with progress: Double) {
        attachmentProgressLabel.text = "Загрузка\n\(Int(progress * 100))%"
    }
    
    private func cancelAttachmentDownloading() {
        attachmentLoadingTask?.cancel()
        attachmentLoadingTask = nil
    }
    
    private func showAttachmentDownloadingProgress() {
        let delayStart = DispatchWorkItem { [weak self] in
            guard let self = self else {
                return
            }
            self.attachmentProgressContainerView.alpha = 0
            self.attachmentProgressContainerView.isHidden = false
            
            UIView.animate(withDuration: Constants.animationDuration) {
                self.attachmentProgressContainerView.alpha = 1
            }
        }
        self.delayProgressStart = delayStart
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: delayStart)
    }
    
    private func hideAttachmentDownloadingProgress() {
        delayProgressStart?.cancel()
        delayProgressStart = nil
        
        if !attachmentProgressContainerView.isHidden {
            UIView.animate(withDuration: Constants.animationDuration, delay: 0, options: []) {
                self.attachmentProgressContainerView.alpha = 0
            } completion: { _ in
                self.attachmentProgressContainerView.isHidden = true
            }
        }
    }
    
    override open func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        defer {
            super.present(viewControllerToPresent, animated: flag, completion: completion)
        }
        guard #available(iOS 14, *) else {
            if viewControllerToPresent is UIDocumentMenuViewController {
                viewControllerToPresent.popoverPresentationController?.delegate = self
            }
            
            return
        }        
    }
}

extension SabycomViewController: UIPopoverPresentationControllerDelegate {
    func prepareForPopoverPresentation(_ popoverPresentationController: UIPopoverPresentationController) {
        popoverPresentationController.sourceView = self.view
        popoverPresentationController.sourceRect = CGRect(x: 80, y: self.view.frame.height - 80, width: 2, height: 2)
    }
}

extension SabycomViewController: SabycomWidgetJSHandlerDelegate {
    func windowLoaded() {
        if let url = _webView?.url {
            didFinishLoadingWindow?(url)
        } else {
            didFailLoading?(nil)
        }
    }
    
    func didClickClose() {
        Sabycom.hide()
    }
    
    func didReceiveNewMessage(unreadCount: Int) {
        didUpdateUnreadMessagesCount?(unreadCount)
    }
}

extension SabycomViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            if let url = navigationAction.request.url, UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        lastResponse = WebResponse(wkResponse: navigationResponse)
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        didFailLoading?(error)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            didFinishLoading?(url)
        } else {
            didFailLoading?(nil)
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Error navigation \(error)")
    }
}

extension SabycomViewController: WKUIDelegate {
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        guard navigationAction.navigationType == .other else {
            return webView
        }

        share(url: navigationAction.request.url)
        
        return WKWebView(frame: view.bounds, configuration: configuration)
    }
}

extension SabycomViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Чтобы не съезжало вверх при открытии клавиатуры
        scrollView.setContentOffset(.zero, animated: false)
    }
}

private struct WebResponse {
    
    var error: (code: Int, message: String)?
    var isCache: Bool = false
    var date: Date?
    
    init(wkResponse: WKNavigationResponse) {
        guard let httpResponse = wkResponse.response as? HTTPURLResponse else {
            return
        }
        
        if httpResponse.statusCode >= 400 {
            error = (httpResponse.statusCode, HTTPURLResponse.localizedString(forStatusCode: httpResponse.statusCode))
        }
        
        let headerDict = httpResponse.allHeaderFields
        let dateString = headerDict["Date"] as! String
        let dateFormat = DateFormatter()
        dateFormat.locale = Locale(identifier: "en_US")
        dateFormat.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
        date = dateFormat.date(from: dateString)
        
        isCache = (date == nil || Date().timeIntervalSince(date!) > 3)
    }
    
}

extension URL {
    var typeIdentifier: String? {
        return (try? resourceValues(forKeys: [.typeIdentifierKey]))?.typeIdentifier
    }
    var localizedName: String? {
        return (try? resourceValues(forKeys: [.localizedNameKey]))?.localizedName
    }
}
