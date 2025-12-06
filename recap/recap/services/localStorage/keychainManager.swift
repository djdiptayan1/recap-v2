//
//  keychainManager.swift
//  recap
//
//  Created by Diptayan Jash on 06/12/25.
//

import Foundation
import Security

enum KeychainError: Error {
    case duplicateEntry
    case unknown(OSStatus)
    case noToken
    case noLibraryId
    case noLibraryName
    case unexpectedTokenData
    case unexpectedLibraryIdData
    case unexpectedLibraryNameData
}
class KeychainManager {
    static let shared = KeychainManager()
    private init() {}
    
    private let service = "com.recap.app"
    private let documentID = "documentID"
    private let patientUID = "patientUID"
    
    // MARK: - Token Methods
    
    func saveDocumentID(_ token: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: documentID,
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try updateDocumentID(token)
        } else if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }
    
    func getDocumentID() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: documentID,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            throw KeychainError.noToken
        }
        
        return token
    }
    
    private func updateDocumentID(_ token: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: documentID
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: token.data(using: .utf8)!
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status != errSecSuccess {
            throw KeychainError.unknown(status)
        }
    }
    
    func deleteDocumentID() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: documentID
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unknown(status)
        }
    }
}
