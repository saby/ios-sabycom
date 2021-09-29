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
    
    func forceInitialize()
    func startedLoading()
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
        view?.viewWillAppear = { [weak view] in
            view?.startedLoading()
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
