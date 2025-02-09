//
//  KeychainKeeper.swift
//  KeychainKeeper
//
//  Created by Kim Nguyen on 24.05.24.
//

import Foundation
import Security

// MARK: - Protocols for Encoders & Decoders

/// Protocol for encoding objects into Data.
public protocol DataEncoder {
    func encode<T: Encodable>(_ value: T) throws -> Data
}

/// Protocol for decoding objects from Data.
public protocol DataDecoder {
    func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T
}

// Extend JSONEncoder & JSONDecoder to conform to the protocols
extension JSONEncoder: DataEncoder {}
extension JSONDecoder: DataDecoder {}

// MARK: - Keychain Error Handling

/// Errors that can occur when working with the Keychain.
public enum KeychainError: Error {
    case itemNotFound
    case itemAlreadyExists
    case encodingFailed(Error)
    case decodingFailed(Error)
    case operationFailed(OSStatus)
}

// MARK: - Keychain Keeper Class

/// A generic, Codable-based Keychain storage utility.
open class KeychainKeeper<SecureItem: Codable> {
    
    private let encoder: DataEncoder
    private let decoder: DataDecoder
    
    /// Initializes a `KeychainKeeper` instance using default encoder and decoder.
    public init(encoder: DataEncoder = JSONEncoder(), decoder: DataDecoder = JSONDecoder()) {
        self.encoder = encoder
        self.decoder = decoder
    }
    
    /// Saves a Codable item into the Keychain.
    /// - Parameters:
    ///   - item: The object to store (must conform to `Codable`).
    ///   - key: The unique key under which to store the item.
    public func addItem(_ item: SecureItem, forKey key: String) throws {
        if try itemExists(forKey: key) {
            throw KeychainError.itemAlreadyExists
        }
        
        let itemData = try encodeItem(item)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: itemData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.operationFailed(status)
        }
    }
    
    /// Retrieves an item from the Keychain.
    /// - Parameter key: The key associated with the stored item.
    /// - Returns: The retrieved `SecureItem`.
    public func retrieveItem(forKey key: String) throws -> SecureItem {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        
        guard status == errSecSuccess, let data = item as? Data else {
            throw status == errSecItemNotFound ? KeychainError.itemNotFound : KeychainError.operationFailed(status)
        }
        
        return try decodeItem(data)
    }
    
    /// Updates an existing item in the Keychain.
    /// - Parameters:
    ///   - item: The updated object.
    ///   - key: The key of the item to update.
    public func updateItem(_ item: SecureItem, forKey key: String) throws {
        guard try itemExists(forKey: key) else {
            throw KeychainError.itemNotFound
        }
        
        let itemData = try encodeItem(item)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: itemData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.operationFailed(status)
        }
    }
    
    /// Updates an existing item or adds a new one if it does not exist.
    /// - Parameters:
    ///   - item: The value to store or update.
    ///   - key: The key under which the item is stored.
    public func updateOrAddItem(_ item: SecureItem, forKey key: String) throws {
        let itemData = try encodeItem(item)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let attributesToUpdate: [String: Any] = [
            kSecValueData as String: itemData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
        
        if status == errSecItemNotFound {
            // If item doesn't exist, add it
            let addQuery = query.merging(attributesToUpdate) { (_, newQuery) in newQuery }
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            guard addStatus == errSecSuccess else {
                throw KeychainError.operationFailed(addStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.operationFailed(status)
        }
    }
    
    /// Deletes an item from the Keychain.
    /// - Parameter key: The key of the item to be deleted.
    public func deleteItem(forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess else {
            throw status == errSecItemNotFound ? KeychainError.itemNotFound : KeychainError.operationFailed(status)
        }
    }
    
    // MARK: - Private Helper Methods
    
    /// Checks if an item exists in the Keychain.
    /// - Parameter key: The key to check.
    /// - Returns: `true` if the item exists, `false` otherwise.
    private func itemExists(forKey key: String) throws -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    /// Encodes an item into Data.
    private func encodeItem(_ item: SecureItem) throws -> Data {
        do {
            return try encoder.encode(item)
        } catch {
            throw KeychainError.encodingFailed(error)
        }
    }
    
    /// Decodes an item from Data.
    private func decodeItem(_ data: Data) throws -> SecureItem {
        do {
            return try decoder.decode(SecureItem.self, from: data)
        } catch {
            throw KeychainError.decodingFailed(error)
        }
    }
}
