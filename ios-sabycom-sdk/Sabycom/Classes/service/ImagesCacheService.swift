//
//  ImagesCacheService.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 12.11.2021.
//

import UIKit

protocol ImagesCacheService {
    func saveImage(_ image: UIImage, url: URL)
    func loadImage(for url: URL) -> UIImage?
}

class ImagesCacheServiceImpl: ImagesCacheService {
    private static let cachePath = "image-cache"

    private static let cacheDirectoryURL: URL? = {
        guard let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first else {
            return nil
        }
        return url.appendingPathComponent(cachePath)
    }()
    
    func saveImage(_ image: UIImage, url: URL) {
        guard let path = pathToImage(with: url)?.path else {
            return
        }

        guard let data = image.pngData() else {
            print("Не удалось создать файл картинки в формате png")
            return
        }

        do {
            try data.write(to: URL(fileURLWithPath: path), options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            print("Ошибка записи файла на диск по пути \(path)")
        }
    }

    /// Загружает картинку по уникальному идентификатору из указанной папки
    func loadImage(for url: URL) -> UIImage? {
        guard let path = pathToImage(with: url)?.path else {
            return nil
        }

        if !FileManager.default.fileExists(atPath: path) {
            return nil
        }

        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: NSData.ReadingOptions.mappedIfSafe)
            return UIImage(data: data)
        } catch {
            print("Ошибка загрузки файла с диска по пути: \(path)")
        }

        return nil
    }
    
    private func pathToImage(with url: URL) -> URL? {
        guard let cacheDirectoryURL = ImagesCacheServiceImpl.cacheDirectoryURL else {
            return nil
        }

        if !FileManager.default.fileExists(atPath: cacheDirectoryURL.path) {
            try? FileManager.default.createDirectory(at: cacheDirectoryURL, withIntermediateDirectories: true, attributes:nil)
        }
        
        guard FileManager.default.fileExists(atPath: cacheDirectoryURL.path) else {
            return nil
            
        }
        
        let imageName = url.dataRepresentation.base64EncodedString()
        let imageUrl = cacheDirectoryURL.appendingPathComponent(imageName)
        return imageUrl
    }
}
