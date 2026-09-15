//
//  SabycomViewController.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 10.08.2021.
//  Copyright © 2021 Tensor. All rights reserved.
//

import WebKit
import UIKit

enum WebViewState: Equatable {
    case preparing
    case loading(url: URL)
    case loaded(url: URL)
    case error
}

class SabycomViewController: UIViewController, SabycomView {
    private enum Constants {
        static let popupCloseButtonSize: CGFloat = 44
        static let popupWebViewMargin: CGFloat = 16
        static let popupWebViewRatio: CGFloat = 0.75

        static let containerBackgroundColor = UIColor(red: 244.0/255.0, green: 244.0/255.0, blue: 244.0/255.0, alpha: 1)
        
        static let animationDuration: TimeInterval = 0.3
    }
    
    var presenter: SabycomPresenter!
    
    var state: WebViewState = .preparing {
        didSet {
            updateViewState()
        }
    }
    
    // MARK: - Private properties
    
    private var documentInteractionController: UIDocumentInteractionController?
    
    private var attachmentLoadingTask: URLSessionDataTask?
    private var attachmentLoadingTaskObservation: NSKeyValueObservation?
    
    private var delayProgressStart: DispatchWorkItem?
    
    private var _webView: WKWebView? = nil {
        didSet {
            _webView?.navigationDelegate = self
            _webView?.uiDelegate = self
        }
    }
    
    private lazy var loadIndicator: UIActivityIndicatorView = {
        let loadIndicator = UIActivityIndicatorView(style: .gray)
        loadIndicator.translatesAutoresizingMaskIntoConstraints = false
        return loadIndicator
    }()
    
    private lazy var webContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var webViewLoadIndicator: UIActivityIndicatorView = {
        let loadIndicator = UIActivityIndicatorView(style: .gray)
        loadIndicator.translatesAutoresizingMaskIntoConstraints = false
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
    
    private let unreadMessagesService: UnreadMessagesService?
    
    private var webContainerHeightConstraint: NSLayoutConstraint?
    
    private var keyboardWillShowObserver: Any?
    private var keyboardWillHideObserver: Any?
    
    init(unreadMessagesService: UnreadMessagesService) {
        self.unreadMessagesService = unreadMessagesService
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        attachmentLoadingTask?.cancel()
        attachmentLoadingTaskObservation?.invalidate()
    }
    
    //MARK: - SabycomView -
    
    var didLoadView: (() -> Void)?
    
    var viewWillAppear: (() -> Void)?
    
    func startedLoading() {
        webContainer.isHidden = true
        loadIndicator.startAnimating()
    }
    
    func load(_ url: URL) {
        state = .loading(url: url)
        loadWebPage()
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
        updateViewState()
        
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
        view.addSubview(loadIndicator)
        view.addSubview(webContainer)
        webContainer.addSubview(webViewLoadIndicator)
        
        let heightConstraint = webContainer.heightAnchor.constraint(equalTo: view.heightAnchor, constant: 0)
        self.webContainerHeightConstraint = heightConstraint
        
        NSLayoutConstraint.activate([
            webContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webContainer.topAnchor.constraint(equalTo: view.topAnchor),
            heightConstraint
        ])
        
        NSLayoutConstraint.activate([
            loadIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            webViewLoadIndicator.centerXAnchor.constraint(equalTo: webContainer.centerXAnchor),
            webViewLoadIndicator.centerYAnchor.constraint(equalTo: webContainer.centerYAnchor)
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
            webView.bottomAnchor.constraint(equalTo: webContainer.safeAreaLayoutGuide.bottomAnchor)
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
    
    private func loadWebPage() {
        let currentUrl: URL?
        
        switch state {
        case .loading(let url), .loaded(let url):
            currentUrl = url
        default:
            currentUrl = nil
        }
        guard isViewLoaded, let url = currentUrl else {
            return
        }
                
        webview { webView in
            let request = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy)
            _ = webView.load(request)
        }
    }
    
    // MARK: - update UI helper
    
    private func updateViewState() {
        guard isViewLoaded else {
            return
        }
        
        switch state {
        case .loading:
            webContainer.isHidden = true
            webViewLoadIndicator.startAnimating()
            
        case .preparing, .loaded:
            webContainer.isHidden = false
            webViewLoadIndicator.stopAnimating()
        case .error:
            webContainer.isHidden = true
            webViewLoadIndicator.stopAnimating()
        }
    }
    
    // MARK: - Attachments downloading -
    
    private func share(url: URL?) {
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
        documentInteractionController.presentOptionsMenu(from: view.frame, in: view, animated: true)
        
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
}

extension SabycomViewController: SabycomWidgetJSHandlerDelegate {
    func didClickClose() {
        Sabycom.hide()
    }
    
    func didReceiveNewMessage(unreadCount: Int) {
        unreadMessagesService?.updateUnreadMessagesCount(unreadCount)
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
        state = .error
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            state = .loaded(url: url)
        } else {
            state = .error
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
