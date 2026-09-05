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
    func load(_ url: URL)
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
        view?.didLoadView = { [weak view, weak interactor] in
            view?.startedLoading()
            
            if let url = interactor?.getUrl() {
                view?.load(url)
            }
        }
    }
}
