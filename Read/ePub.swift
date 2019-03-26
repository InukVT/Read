//
//  ePub.swift
//  Read
//
//  Created by Bastian Inuk Christensen on 25/02/2019.
//  Copyright © 2019 Bastian Inuk Christensen. All rights reserved.
//
import Foundation
import WebKit
import ZIPFoundation
import XMLCoder

// MARK: - Book metadata
/// ePub handler class
class ePub {
    private let fileManager: FileManager
    private let workDir: URL
    private let compressedBook: Document
    private let bookFolder: String
    private var coverLink: String?
    /// ePub metadata, use this to get information
    private(set) var meta: EpubMeta? = nil
    private var manifest: Manifest? = nil
    private(set) var cover: UIImage?
    private(set) var OEPBS: String = ""
    
    init(_ compressedBook: Document) throws {
        self.fileManager = FileManager()
        self.compressedBook = compressedBook
        self.workDir = fileManager.temporaryDirectory
        self.bookFolder = URL(fileURLWithPath: compressedBook.fileURL.path).deletingPathExtension().lastPathComponent
        //self.coverLink = nil
        //self.cover = nil
        try doXML{ meta, manifest in
            self.meta = meta
            self.manifest = manifest
        }
    }
}
// MAKR: - New ePub XML Parser
extension ePub {
    
    private func doXML(closure: (EpubMeta, Manifest) -> ()) throws -> Void {
        
        try unpackEpub { dataPath in
            var rootfileXML = container()
            let decoder = XMLDecoder()
                decoder.shouldProcessNamespaces = true
            do {
                let xmlData = try Data(contentsOf: dataPath.appendingPathComponent("META-INF/container.xml"))
                let xmlString = String(data: xmlData, encoding: .utf8)
                rootfileXML = try decoder.decode(container.self, from: (xmlString?.data(using: .utf8))!)
                var oepbsURL: URL = URL(fileURLWithPath: (rootfileXML.rootfiles?.rootfile?.path)!)
                oepbsURL.deleteLastPathComponent()
                
                self.OEPBS = oepbsURL.lastPathComponent
                    
            } catch {
                throw XMLError.NotEpub
            }
            
            do {
                let xmlData = try Data(contentsOf: dataPath.appendingPathComponent((rootfileXML.rootfiles?.rootfile?.path!)!))
                let xmlString = String(data: xmlData, encoding: .utf8)
                var packageXML = package()
                    packageXML = try decoder.decode(package.self, from: (xmlString?.data(using: .utf8))!)
                closure(packageXML.metadata!, packageXML.manifest!)
            } catch {
                print(error)
                throw XMLError.SomethingWentWrong
            }
            
        }
    }
}
// MARK: - ePub unzipper
extension ePub {
    
    /// Unpack the epub, get specified xml file, container.xml if no `relativePath` has been passed in, parse xml file, and delete the unpacked epub file afterwards
    private func unpackEpub<T>(_ relativePath: String? = nil, closure: (URL) throws -> (T)) rethrows -> T{
        
        let compressedBookURL = self.compressedBook.fileURL
        var isZIP = false
        var uncompressedBookURL: URL = compressedBookURL
        if (!fileManager.fileExists(atPath: compressedBookURL.appendingPathComponent("META-INF").appendingPathComponent("container.xml").path)){
            uncompressedBookURL = unzip{
                uncompressedBookURL = workDir.appendingPathComponent(bookFolder)
                uncompressedBookURL.appendPathExtension("zip")
                
                if !fileManager.fileExists(atPath: uncompressedBookURL.path){
                    try! fileManager.copyItem(atPath: compressedBookURL.path, toPath: uncompressedBookURL.path)
                }
                return uncompressedBookURL
            }
            isZIP = true
        }
        
        let cover = try closure(uncompressedBookURL)
        if isZIP {
            try? fileManager.removeItem(at: uncompressedBookURL)
        }
        return cover
    }

    private func unzip(closure: () -> (URL)) -> URL {
        let archive: URL = closure()
        var destinationURL = workDir
        destinationURL = destinationURL.appendingPathComponent(self.bookFolder)
        do {
            try fileManager.createDirectory(at: destinationURL, withIntermediateDirectories: true, attributes: nil)
            try fileManager.unzipItem(at: archive, to: destinationURL)
            try fileManager.removeItem(at: archive)
        } catch {
            print("Extraction of ZIP archive failed with error:\(error)")
        }
        
        return destinationURL
    }
}
// MARK: - Cover generator
extension ePub {
    /// Returns the cover image of a given book as `UIImage`
    func getCover(frame: CGRect) throws -> UIImage {
        return try unpackEpub{ workDir -> UIImage in
            var coverName = ""
            
            if let items = self.meta?.meta {
                for item in items {
                    if item.name == "cover" {
                        coverName = item.content!
                    }
                }
            }
            
            if let items = self.manifest?.item {
                
                for item in items {
                    if item.name == coverName {
                        var coverURL = workDir
                        coverURL.appendPathComponent(self.OEPBS)
                        coverURL.appendPathComponent(item.link!)
                        let coverData = try Data(contentsOf: coverURL)
                        let cover = try UIImage(data: coverData)!
                        return cover
                    }
                }
            }
            
            throw XMLError.coverNotFound
        }
        
    }
}

fileprivate struct container: Codable {
    var rootfiles: rootfiles?
    enum CodingKeys: String, CodingKey {
        case rootfiles = "rootfiles"
    }
}

fileprivate struct rootfiles: Codable {
    var rootfile: rootfile?
    enum CodingKeys: String, CodingKey {
        case rootfile = "rootfile"
    }
}

fileprivate struct rootfile: Codable {
    var path: String?
    var mediaType: String?
    enum CodingKeys: String, CodingKey {
        case path = "full-path"
        case mediaType = "media-type"
    }
}

struct package: Codable {
    private(set) var metadata: EpubMeta?
    private(set) var manifest: Manifest?
}


// MARK: - EpubMetaData
struct EpubMeta: Codable {
    private(set) var title: String?
    private(set) var creator: [Creators]? 
    private(set) var meta: [Meta]?
}
struct Creators: Codable {
    let id: String?
    let value: String
}
struct Meta: Codable {
    let name: String?
    let content: String?
}

struct Manifest: Codable {
    var item: [Items]?
}

struct Items: Codable {
    var name: String?
    var mediatype: String?
    var link: String?
    enum CodingKeys: String, CodingKey {
        case name = "id"
        case mediatype = "media-type"
        case link = "href"
    }
}



// MARK: - Custom errors
enum XMLError: String, Error {
    case FileExists
    case SomethingWentWrong
    case coverNotFound = "Cover not found"
    case NotEpub = "The given fils is not a valid epub file"
}
