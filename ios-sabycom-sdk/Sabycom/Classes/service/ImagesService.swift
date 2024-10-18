//
//  ImagesService.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 12.11.2021.
//

import UIKit

protocol ImagesService {
    func getImage(from url: URL, completion: @escaping (_ image: UIImage?) -> Void) -> ImageLoadTask?
}

class ImagesServiceImpl: ImagesService {
    private let cacheService: ImagesCacheService
    
    init(cacheService: ImagesCacheService) {
        self.cacheService = cacheService
    }
    
    func getImage(from url: URL, completion: @escaping (_ image: UIImage?) -> Void) -> ImageLoadTask? {
        let task = ImageLoadTask(url: url, cacheService: cacheService) { image in
            DispatchQueue.main.async {
                completion(image)
            }
        }
        task.start()
        return task
    }
}

class ImageLoadTask {
    private let url: URL
    private let cacheService: ImagesCacheService
    private let completion: (_ image: UIImage?) -> Void
    
    private var workItem: DispatchWorkItem?
    
    private var retainedSelf: ImageLoadTask?
    
    init(url: URL, cacheService: ImagesCacheService, completion: @escaping (_ image: UIImage?) -> Void) {
        self.url = url
        self.cacheService = cacheService
        self.completion = completion
    }
    
    func start() {
        guard self.workItem == nil else {
            return
        }
        
        self.retainedSelf = self
        self.workItem = DispatchWorkItem(block: { [weak self] in
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self else {
                    return
                }
                
                if let image = self.cacheService.loadImage(for: self.url) {
                    self.completed(with: image)
                } else {
                    self.loadImage(from: self.url) { [weak self] image in
                        self?.completed(with: image)
                    }
                }
            }
        })
        self.workItem?.perform()
    }
    
    func cancel() {
        self.workItem?.cancel()
    }
    
    func loadImage(from url: URL, completion: @escaping (_ image: UIImage?) -> Void) {
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            let image = UIImage(data: data, scale: UIScreen.main.scale)
            if let image = image {
                self?.cacheService.saveImage(image, url: url)
            }
            completion(image)
        }.resume()
    }
    
    private func completed(with image: UIImage?) {
        completion(image)
        retainedSelf = nil
    }
}
