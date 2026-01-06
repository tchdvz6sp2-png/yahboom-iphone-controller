//
//  KeychainManager.swift
//  YahboomController
//
//  Secure credential storage using iOS Keychain
//

import Foundation
import Security

/// Manager for secure credential storage in iOS Keychain
class KeychainManager {
    
    /// Save a password to the keychain
    /// - Parameters:
    ///   - password: Password to save
    ///   - key: Unique key for the password
    /// - Returns: True if successful
    @discardableResult
    static func save(password: String, for key: String) -> Bool {
        guard let data = password.data(using: .utf8) else {
            return false
        }
        
        // Delete any existing item
        delete(key: key)
        
        // Create query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        // Add to keychain
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Retrieve a password from the keychain
    /// - Parameter key: Key for the password
    /// - Returns: Password string if found, nil otherwise
    static func get(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    /// Delete a password from the keychain
    /// - Parameter key: Key for the password
    /// - Returns: True if successful
    @discardableResult
    static func delete(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Check if a password exists in the keychain
    /// - Parameter key: Key for the password
    /// - Returns: True if exists
    static func exists(key: String) -> Bool {
        return get(key: key) != nil
    }
}
