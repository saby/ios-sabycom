//
//  WebArchivesStorage.swift
//  Sabycom
//
//  Created by Sergey Iskhakov on 14.01.2022.
//

import Foundation

protocol WebArchivesStorage: AnyObject {
    func saveWebArchive(_ data: Data)
    func getWebArchiveURL() -> URL?
    func clear()
}

class WebArchivesStorageImpl: WebArchivesStorage {
    func saveWebArchive(_ data: Data) {
        guard let url = webArchiveURL() else {
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
            
            try data.write(to: url)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func getWebArchiveURL() -> URL? {
        guard let url = webArchiveURL(), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        
        return url
    }
    
    func clear() {
        guard let url = webArchiveURL() else {
            return
        }
        
        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func webArchiveURL() -> URL? {
        guard let docsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        
        let sabycomDir = docsDirectory.appendingPathComponent("sabycom")
        
        if !FileManager.default.fileExists(atPath: sabycomDir.path) {
            do {
                try FileManager.default.createDirectory(at: sabycomDir, withIntermediateDirectories: false, attributes: nil)
            } catch {
                return nil
            }
        }
        
        return sabycomDir.appendingPathComponent("sabycom.webarchive")
    }
}
