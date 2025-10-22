//
//  BRUploadPart.swift
//  BRNetwork
//
//  Created by BR on 2025/10/22.
//

import Foundation


/// 上傳檔案資料封裝
public struct BRUploadPart {
    public let key: String
    public let filename: String
    public let mimeType: MimeType
    public let data: Data
    
    public init(key: String, filename: String, mimeType: MimeType, data: Data) {
        self.key = key
        self.filename = filename
        self.mimeType = mimeType
        self.data = data
    }
    
    
}


public extension BRUploadPart {
    
    
    public struct MimeType: Hashable, Equatable, RawRepresentable, ExpressibleByStringLiteral {
        public var rawValue: String

        public init(rawValue: String) {
            self.rawValue = rawValue
        }

        public init(stringLiteral value: String) {
            self.rawValue = value
        }
        
        public static func custom(_ type: String) -> MimeType {
            MimeType(rawValue: type)
        }

        // MARK: - Images
        
        public static let jpeg: MimeType = "image/jpeg"
        public static let png: MimeType = "image/png"
        public static let gif: MimeType = "image/gif"
        public static let webp: MimeType = "image/webp"
        public static let svg: MimeType = "image/svg+xml"
        
        // MARK: - Documents
        
        public static let pdf: MimeType = "application/pdf"
        public static let doc: MimeType = "application/msword"
        public static let docx: MimeType = "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
        public static let xls: MimeType = "application/vnd.ms-excel"
        public static let xlsx: MimeType = "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
        public static let ppt: MimeType = "application/vnd.ms-powerpoint"
        public static let pptx: MimeType = "application/vnd.openxmlformats-officedocument.presentationml.presentation"
        public static let txt: MimeType = "text/plain"

        // MARK: - Archives
        
        public static let zip: MimeType = "application/zip"
        public static let rar: MimeType = "application/x-rar-compressed"
        public static let tar: MimeType = "application/x-tar"
        public static let gzip: MimeType = "application/gzip"

        // MARK: - Media
        
        public static let mp3: MimeType = "audio/mpeg"
        public static let mp4: MimeType = "video/mp4"
        public static let avi: MimeType = "video/x-msvideo"
        public static let mov: MimeType = "video/quicktime"
        public static let wav: MimeType = "audio/wav"

        // MARK: - Data
        
        public static let json: MimeType = "application/json"
        public static let xml: MimeType = "application/xml"
        public static let csv: MimeType = "text/csv"
        

        // MARK: - 副檔名轉換
        
        
        public static func from(fileExtension ext: String) -> MimeType {
            switch ext.lowercased() {
            case "jpg", "jpeg": return .jpeg
            case "png": return .png
            case "gif": return .gif
            case "webp": return .webp
            case "svg": return .svg
            case "pdf": return .pdf
            case "doc": return .doc
            case "docx": return .docx
            case "xls": return .xls
            case "xlsx": return .xlsx
            case "ppt": return .ppt
            case "pptx": return .pptx
            case "txt": return .txt
            case "zip": return .zip
            case "rar": return .rar
            case "tar": return .tar
            case "gz": return .gzip
            case "mp3": return .mp3
            case "mp4": return .mp4
            case "avi": return .avi
            case "mov": return .mov
            case "wav": return .wav
            case "json": return .json
            case "xml": return .xml
            case "csv": return .csv
            default: return .custom("application/octet-stream")
            }
        }
    }

    

}
