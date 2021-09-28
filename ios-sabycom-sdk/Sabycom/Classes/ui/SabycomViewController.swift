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
        static let headerHeight: CGFloat = 44
        static let headerMargins: CGFloat = 16
        static let titleLabelFont = UIFont.systemFont(ofSize: 16)
    }
    
    var presenter: SabycomPresenter!
    
    var state: WebViewState = .preparing {
        didSet {
            updateViewState()
        }
    }
    
   // MARK: - Private properties
    private var _webView: WKWebView? = nil {
        didSet {
            _webView?.navigationDelegate = self
        }
    }
    
    private lazy var container: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    private lazy var loadIndicator: UIActivityIndicatorView = {
        let loadIndicator = UIActivityIndicatorView(style: .gray)
        loadIndicator.translatesAutoresizingMaskIntoConstraints = false
        return loadIndicator
    }()
    
    private lazy var headerContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .red
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.font = Constants.titleLabelFont
        label.textAlignment = .center
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage.named("ic_close"), for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .clear
        button.titleLabel?.font = UIFont.systemFont(ofSize: 24, weight: .medium)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
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
    
    init(unreadMessagesService: UnreadMessagesService) {
        self.unreadMessagesService = unreadMessagesService
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - SabycomView -
    
    var didLoadView: (() -> Void)?
    
    var viewWillAppear: (() -> Void)?
    
    func forceInitialize() {
        view.setNeedsLayout()
    }
    
    func startedLoadingConfig() {
        container.isHidden = true
        loadIndicator.startAnimating()
    }
    
    func updateWithConfig(_ config: SabycomConfig) {
        container.isHidden = false
        loadIndicator.stopAnimating()
        
        titleLabel.text = config.title
        headerContainer.backgroundColor = config.headerColor
    }
    
    func loadUrl(_ url: URL) {
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
        setupWebViewConstraints()
        updateViewState()
        
        didLoadView?()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        viewWillAppear?()
    }
    
    private func setupViews() {
        view.addSubview(container)
        view.addSubview(loadIndicator)
        container.addSubview(webContainer)
        container.addSubview(headerContainer)
        container.addSubview(webViewLoadIndicator)
        headerContainer.addSubview(closeButton)
        headerContainer.addSubview(titleLabel)
        
        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.topAnchor.constraint(equalTo: view.topAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            loadIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            headerContainer.leftAnchor.constraint(equalTo: container.leftAnchor),
            headerContainer.topAnchor.constraint(equalTo: container.topAnchor),
            headerContainer.rightAnchor.constraint(equalTo: container.rightAnchor),
            headerContainer.heightAnchor.constraint(equalToConstant: Constants.headerHeight)
        ])
        
        NSLayoutConstraint.activate([
            closeButton.rightAnchor.constraint(equalTo: headerContainer.rightAnchor),
            closeButton.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            closeButton.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            closeButton.widthAnchor.constraint(equalTo: closeButton.heightAnchor)
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: headerContainer.leadingAnchor, constant: Constants.headerMargins),
            titleLabel.topAnchor.constraint(equalTo: headerContainer.topAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: Constants.headerMargins)
        ])
        
        NSLayoutConstraint.activate([
            webContainer.leftAnchor.constraint(equalTo: container.leftAnchor),
            webContainer.topAnchor.constraint(equalTo: headerContainer.bottomAnchor),
            webContainer.rightAnchor.constraint(equalTo: container.rightAnchor),
            webContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        NSLayoutConstraint.activate([
            webViewLoadIndicator.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            webViewLoadIndicator.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        closeButton.addTarget(self, action: #selector(onClose(_:)), for: .touchUpInside)
        titleLabel.text = "Sabycom"
    }
    // MARK: - WebPage helpers
    
    private func setupWebViewConstraints() {
        guard let webView = _webView, isViewLoaded else {
            return
        }
        
        webContainer.addSubview(webView)
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            webView.leftAnchor.constraint(equalTo: webContainer.leftAnchor),
            webView.topAnchor.constraint(equalTo: webContainer.topAnchor),
            webView.rightAnchor.constraint(equalTo: webContainer.rightAnchor),
            webView.bottomAnchor.constraint(equalTo: webContainer.bottomAnchor)
        ])
        
        webView.configuration.suppressesIncrementalRendering = true
        webView.configuration.preferences.javaScriptCanOpenWindowsAutomatically = true
        webView.scrollView.bounces = false
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
            self.webViewInTheMaking = true
            
            let preferences = WKPreferences()
            preferences.javaScriptEnabled = true
            
            let configuration = WKWebViewConfiguration()
            configuration.preferences = preferences
            
            let contentController = WKUserContentController()
            contentController.add(jsHandler, name: "mobileParent")
            
            configuration.userContentController = contentController
            
            self._webView = WKWebView(frame: view.bounds, configuration: configuration)
            self._webView?.translatesAutoresizingMaskIntoConstraints = false
            
            setupWebViewConstraints()
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
    
    @objc private func onClose(_ sender: UIButton) {
        Sabycom.hide()
    }
}

extension SabycomViewController: SabycomWidgetJSHandlerDelegate {
    func didClickClose() {
        Sabycom.hide()
    }
    
    func didReceiveNewMessage() {
        unreadMessagesService?.updateUnreadMessagesCount()
    }
}

extension SabycomViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Swift.Void) {
        lastResponse = WebResponse(wkResponse: navigationResponse)
        
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        state = .error
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if lastResponse?.error != nil {
            state = .error
        } else if let url = webView.url {
            state = .loaded(url: url)
        } else {
            state = .error
        }
    }
    
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        print("Error navigation \(error)")
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

