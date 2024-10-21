//
//  SabycomNotificationView.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 03.11.2021.
//

import UIKit

class SabycomNotificationView: UIView {
    private static var instance: SabycomNotificationView?
    
    private let imagesService: ImagesService
    
    private var model: SabycomNotificationModel?
    
    private weak var imageLoadTask: ImageLoadTask?
    
    private lazy var containerView: UIView = {
        let containerView = UIView()
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = Constants.containerCornerRadius
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.layer.shadowColor = Constants.containerShadowColor.cgColor
        containerView.layer.shadowOffset = Constants.containerShadowOffset
        containerView.layer.shadowOpacity = 1
        containerView.layer.shadowRadius = Constants.containerShadowRadius
        return containerView
    }()
    
    private lazy var avatarView: UIImageView = {
        let view = UIImageView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = Constants.avatarBackgroundColor
        return view
    }()
    
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.textColor = Constants.channelNameColor
        label.font = Constants.channelNameFont
        return label
    }()
    
    private lazy var messageLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentHuggingPriority(.defaultLow, for: .horizontal)
        label.textColor = Constants.messageColor
        label.font = Constants.messageFont
        return label
    }()
    
    private lazy var messageDateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.textColor = Constants.messageDateColor
        label.font = Constants.messageDateFont
        return label
    }()
    
    private lazy var unreadCountLabel: UILabel = {
        let label = UILabel()
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.backgroundColor = Constants.unreadCountBackgroundColor
        label.textColor = Constants.unreadCountColor
        label.font = Constants.unreadCountFont
        label.textAlignment = .center
        return label
    }()
    
    private lazy var closeButton: UIButton = {
        let closeButton = UIButton()
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(hide), for: .touchUpInside)
        closeButton.setImage(UIImage.named("ic_close"), for: .normal)
        return closeButton
    }()
    
    private var appDidEnterBackgroundObserver: Any?
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private init(imagesService: ImagesService) {
        self.imagesService = imagesService
        
        super.init(frame: .zero)
        
        initializeViews()
        initializeGestureRecognizer()
        
        subscribeApplicationStateChanges()
    }
    
    deinit {
        imageLoadTask?.cancel()
        imageLoadTask = nil
        
        if let appDidEnterBackgroundObserver = appDidEnterBackgroundObserver {
            NotificationCenter.default.removeObserver(appDidEnterBackgroundObserver)
        }
    }
    
    class func show(imagesService: ImagesService, model: SabycomNotificationModel, parentView: UIView) {
        guard model.unreadCount > 0 else {
            print("Нет непрочитанных сообщений. Плашку не показываем")
            return
        }
        
        let instance = SabycomNotificationView.instance ?? SabycomNotificationView(imagesService: imagesService)
        
        self.instance = instance
        
        instance.update(with: model)
        instance.show(in: parentView)
    }
    
    class func hide() {
        instance?.hide()
    }
    
    class func destroy() {
        instance = nil
    }
    
    private func update(with model: SabycomNotificationModel) {
        self.model = model
        updateContent()
    }
    
    private func show(in parentView: UIView) {
        guard superview == nil else {
            print("Плашка уже показывается. Еще раз не показываем")
            return
        }
        
        parentView.addSubview(self)
        
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.leadingAnchor),
            trailingAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.trailingAnchor),
            bottomAnchor.constraint(equalTo: parentView.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        alpha = 0
        
        setNeedsLayout()
        layoutIfNeeded()
        
        UIView.animate(withDuration: Constants.animationDuration) {
            self.alpha = 1
        }
    }
    
    @objc
    private func hide() {
        UIView.animate(withDuration: Constants.animationDuration,
                       delay: 0,
                       options: []) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }

    }
    
    private func initializeViews() {
        self.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(containerView)
        addSubview(closeButton)
        
        containerView.addSubview(avatarView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(messageLabel)
        containerView.addSubview(messageDateLabel)
        containerView.addSubview(unreadCountLabel)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Constants.containerMarginHorizontal),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Constants.containerMarginHorizontal),
            containerView.topAnchor.constraint(equalTo: topAnchor, constant: Constants.containerMarginTop),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Constants.containerMarginBottom)
        ])
        
        NSLayoutConstraint.activate([
            avatarView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: Constants.containerPaddingHorizontal),
            avatarView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.containerPaddingTop),
            avatarView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -Constants.containerPaddingBottom),
            avatarView.widthAnchor.constraint(equalToConstant: Constants.avatarSize),
            avatarView.heightAnchor.constraint(equalToConstant: Constants.avatarSize)
        ])
        
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: Constants.labelsPaddingLeft),
            titleLabel.trailingAnchor.constraint(equalTo: messageDateLabel.leadingAnchor, constant: -Constants.containerPaddingHorizontal),
            titleLabel.bottomAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            messageDateLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.containerPaddingHorizontal),
            messageDateLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: avatarView.trailingAnchor, constant: Constants.labelsPaddingLeft),
            messageLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            messageLabel.topAnchor.constraint(equalTo: avatarView.centerYAnchor)
        ])
        
        NSLayoutConstraint.activate([
            unreadCountLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -Constants.containerPaddingHorizontal),
            unreadCountLabel.centerYAnchor.constraint(equalTo: messageLabel.centerYAnchor),
            unreadCountLabel.widthAnchor.constraint(greaterThanOrEqualTo: unreadCountLabel.heightAnchor),
            unreadCountLabel.heightAnchor.constraint(equalToConstant: Constants.unreadCountHeight)
        ])
        
        NSLayoutConstraint.activate([
            closeButton.centerXAnchor.constraint(equalTo: containerView.rightAnchor),
            closeButton.centerYAnchor.constraint(equalTo: containerView.topAnchor, constant: Constants.closeButtonMarginTop),
            closeButton.widthAnchor.constraint(equalToConstant: Constants.closeButtonSize),
            closeButton.heightAnchor.constraint(equalToConstant: Constants.closeButtonSize)
        ])
    }
    
    private func initializeGestureRecognizer() {
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(onOpenSabycom))
        addGestureRecognizer(tapRecognizer)
    }
    
    private func updateContent() {
        imageLoadTask?.cancel()
        
        if let model = model {
            titleLabel.text = model.title
            messageLabel.text = model.body.isEmpty ? " " : model.body
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd MMM"
            
            messageDateLabel.text = dateFormatter.string(from: model.messageDate)
            
            unreadCountLabel.isHidden = Sabycom.unreadConversationCount <= 0
            unreadCountLabel.text = "\(Sabycom.unreadConversationCount)"
            
            if let url = URL(string: model.operatorPhoto) {
                imageLoadTask = imagesService.getImage(from: url) { [weak self] image in
                    self?.avatarView.image = image
                }
            }
        }
    }
    
    @objc private func onOpenSabycom() {
        hide()
        if let viewController = UIApplication.shared.windows.first?.rootViewController {
            Sabycom.show(on: viewController)
        }
    }
    
    private func subscribeApplicationStateChanges() {
        appDidEnterBackgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main) { [weak self] _ in
                self?.hide()
            }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        avatarView.layer.cornerRadius = avatarView.frame.height / 2
        avatarView.layer.masksToBounds = true
        
        unreadCountLabel.layer.cornerRadius = unreadCountLabel.frame.height / 2
        unreadCountLabel.layer.masksToBounds = true
    }
    
    private enum Constants {
        static let containerMarginHorizontal: CGFloat = 22
        static let containerMarginBottom: CGFloat = 48
        static let containerMarginTop: CGFloat = 20
        static let containerPaddingHorizontal: CGFloat = 11
        static let containerPaddingTop: CGFloat = 9
        static let containerPaddingBottom: CGFloat = 11
        
        static let containerCornerRadius: CGFloat = 8
        
        static let containerShadowColor: UIColor = UIColor.black.withAlphaComponent(0.3)
        static let containerShadowOffset: CGSize = CGSize(width: 0, height: 4)
        static let containerShadowRadius: CGFloat = 30.0
        
        static let labelsPaddingLeft: CGFloat = 9
        static let labelsSpacing: CGFloat = 4
        
        static let avatarSize: CGFloat = 48
        static let avatarBackgroundColor: UIColor = UIColor(red: 241.0/255, green: 96.0/255, blue: 99.0/255, alpha: 1)

        static let channelNameFont: UIFont = UIFont.systemFont(ofSize: 16)
        static let messageFont: UIFont = UIFont.systemFont(ofSize: 14)
        static let messageDateFont = UIFont.systemFont(ofSize: 10, weight: .medium)
        static let unreadCountFont = UIFont.systemFont(ofSize: 10)
        
        static let channelNameColor: UIColor = .black
        static let messageColor: UIColor = .black.withAlphaComponent(0.5)
        static let messageDateColor: UIColor = .black.withAlphaComponent(0.5)
        static let unreadCountColor: UIColor = .white
        
        static let closeButtonSize: CGFloat = 40
        static let closeButtonMarginTop: CGFloat = 6
        
        static let unreadCountHeight: CGFloat = 16
        static let unreadCountBackgroundColor: UIColor = UIColor(red: 211.0/255, green: 78.0/255, blue: 14.0/255, alpha: 1)
        
        static let animationDuration: TimeInterval = 0.25
    }
}
