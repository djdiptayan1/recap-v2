//
//  CloudinaryUtility.swift
//  recap
//
//  Created by Gemini CLI on 06/04/26.
//

import Foundation

struct CloudinaryUtility {
    
    enum ImageTransform {
        case thumbnail
        case detail
        case avatar
        case custom(String)
        
        var stringValue: String {
            switch self {
            case .thumbnail:
                return "c_thumb,w_400,h_400,g_face,f_auto,q_auto"
            case .detail:
                return "w_1200,c_limit,f_auto,q_auto"
            case .avatar:
                return "c_fill,w_200,h_200,g_face,f_auto,q_auto"
            case .custom(let val):
                return val
            }
        }
    }
    
    /// Optimizes a Cloudinary URL by inserting transformation parameters.
    /// Example: .../upload/v1234/path/to/image.jpg -> .../upload/c_thumb,w_400/v1234/path/to/image.jpg
    static func optimize(_ urlString: String?, transform: ImageTransform = .thumbnail) -> String {
        guard let urlString = urlString, !urlString.isEmpty else { return "" }

        // Only transform Cloudinary URLs
        if !urlString.contains("cloudinary.com") {
            return urlString
        }

        guard let uploadRange = urlString.range(of: "/upload/") else {
            return urlString
        }

        let suffix = String(urlString[uploadRange.upperBound...])
        let firstSegment = suffix.split(separator: "/", maxSplits: 1, omittingEmptySubsequences: true).first

        // If the first segment after /upload/ is not a version marker, assume the URL already
        // contains a transformation and avoid stacking another one on top of it.
        if let firstSegment, !firstSegment.hasPrefix("v") {
            return urlString
        }

        let parts = urlString.components(separatedBy: "/upload/")
        if parts.count == 2 {
            return "\(parts[0])/upload/\(transform.stringValue)/\(parts[1])"
        }

        return urlString
    }
}
