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
    
    func startedLoading() {
        webContainer.isHidden = true
        loadIndicator.startAnimating()
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
        view.addSubview(loadIndicator)
        view.addSubview(webContainer)
        webContainer.addSubview(webViewLoadIndicator)
        
        NSLayoutConstraint.activate([
            webContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webContainer.topAnchor.constraint(equalTo: view.topAnchor),
            webContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor)
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
            jsHandler.addTo(controller: contentController)
            
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

