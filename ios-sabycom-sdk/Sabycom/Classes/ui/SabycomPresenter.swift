//
//  SabycomPresenter.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 19.08.2021.
//

import UIKit

protocol SabycomView: AnyObject {
    var didLoadView: (() -> Void)? { get set }
    var viewWillAppear: (() -> Void)? { get set }
    
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
    
    private func setViewHandlers() {
        view?.didLoadView = { [weak view] in
            view?.startedLoadingConfig()
            
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else {
                    return
                }
                
                let config = self.interactor.getConfig()
                DispatchQueue.main.async { [weak view] in
                    view?.updateWithConfig(config)
                }
            }
        }
        
        view?.viewWillAppear = { [weak view] in
            DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                guard let self = self else {
                    return
                }
                
                if let url = self.interactor.getUrl() {
                    DispatchQueue.main.async { [weak view] in
                        view?.loadUrl(url)
                    }
                }
                
            }
        }
    }
}
