//
//  SabycomPresenter.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import Foundation

protocol SabycomView: AnyObject {
    var didLoadView: (() -> Void)? { get set }
    
    func forceInitialize()
    func startedLoadingConfig()
    func updateWithConfig(_ config: SabycomConfig)
    func loadUrl(_ url: URL)
}

class SabycomPresenter {
    private let interactor: SabycomInteractor
    private weak var view: SabycomView?
    
    init(interactor: SabycomInteractor, view: SabycomView) {
        self.interactor = interactor
        self.view = view
        
        setViewHandlers()
    }
    
    func forceInitialize() {
        view?.forceInitialize()
    }
    
    private func setViewHandlers() {
        view?.didLoadView = { [weak view] in
            view?.startedLoadingConfig()
            
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else {
                    return
                }
                
                let config = self.interactor.getConfig()
                let url = self.interactor.getUrl()
                DispatchQueue.main.async { [weak view] in
                    view?.updateWithConfig(config)
                    
                    if let url = url {
                        view?.loadUrl(url)
                    }
                }
            }
        }
    }
}
