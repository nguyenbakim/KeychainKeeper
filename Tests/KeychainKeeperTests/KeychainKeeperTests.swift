//
//  KeychainKeeperTests.swift
//  KeychainKeeper
//
//  Created by Kim Nguyen on 24.05.24.
//

import XCTest
@testable import KeychainKeeper

/// Unit tests for `KeychainKeeper`
final class KeychainKeeperTests: XCTestCase {
    
    /// A simple struct to test KeychainKeeper with Codable data.
    struct Credentials: Codable, Equatable {
        let username: String
        let password: String
    }

    private var keychainKeeper: KeychainKeeper<Credentials>!
    private let testKey = "testCredentialsKey"
    private let sampleCredentials = Credentials(username: "testUser", password: "securePassword123")

    override func setUpWithError() throws {
    #if os(macOS)
    keychainKeeper = KeychainKeeper<Credentials>()
    #else
    throw XCTSkip("Skipping Keychain tests on iOS Simulator due to unsupported entitlement: OSStatus -34018 issue.")
    #endif
    }

    override func tearDownWithError() throws {
        try? keychainKeeper.deleteItem(forKey: testKey) // Clean up after each test
        keychainKeeper = nil
    }
    
    /// Test adding an item to Keychain
    func testAddItem() throws {
        XCTAssertNoThrow(try keychainKeeper.addItem(sampleCredentials, forKey: testKey))
        
        let retrievedItem = try keychainKeeper.retrieveItem(forKey: testKey)
        XCTAssertEqual(retrievedItem, sampleCredentials, "The retrieved credentials should match the saved ones.")
    }
    
    /// Test adding an item that already exists should throw `itemAlreadyExists`
    func testAddDuplicateItemThrowsError() throws {
        try keychainKeeper.addItem(sampleCredentials, forKey: testKey)
        
        XCTAssertThrowsError(try keychainKeeper.addItem(sampleCredentials, forKey: testKey)) { error in
            guard case .itemAlreadyExists = error as? KeychainError else {
                return XCTFail("Adding a duplicate item should throw itemAlreadyExists error.")
            }
        }
    }

    /// Test retrieving a non-existing item should throw `itemNotFound`
    func testRetrieveNonExistentItemThrowsError() throws {
        XCTAssertThrowsError(try keychainKeeper.retrieveItem(forKey: "nonExistentKey")) { error in
            guard case .itemNotFound = error as? KeychainError else {
                return XCTFail("Retrieving a non-existing item should throw itemNotFound error.")
            }
        }
    }

    /// Test updating an existing item in Keychain
    func testUpdateItem() throws {
        try keychainKeeper.addItem(sampleCredentials, forKey: testKey)
        let updatedCredentials = Credentials(username: "newUser", password: "newPassword456")
        
        XCTAssertNoThrow(try keychainKeeper.updateItem(updatedCredentials, forKey: testKey))
        
        let retrievedItem = try keychainKeeper.retrieveItem(forKey: testKey)
        XCTAssertEqual(retrievedItem, updatedCredentials, "The credentials should be updated in Keychain.")
    }
    
    /// Test updating a non-existing item should throw `itemNotFound`
    func testUpdateNonExistentItemThrowsError() throws {
        let updatedCredentials = Credentials(username: "newUser", password: "newPassword456")
        
        XCTAssertThrowsError(try keychainKeeper.updateItem(updatedCredentials, forKey: testKey)) { error in
            guard case .itemNotFound = error as? KeychainError else {
                return XCTFail("Updating a non-existing item should throw itemNotFound error.")
            }
        }
    }

    /// Test updateOrAddItem should update an existing item or add a new one
    func testUpdateOrAddItem() throws {
        // First updateOrAdd should add the item
        XCTAssertNoThrow(try keychainKeeper.updateOrAddItem(sampleCredentials, forKey: testKey))
        
        // Updating with new credentials
        let updatedCredentials = Credentials(username: "updatedUser", password: "updatedPassword")
        XCTAssertNoThrow(try keychainKeeper.updateOrAddItem(updatedCredentials, forKey: testKey))
        
        let retrievedItem = try keychainKeeper.retrieveItem(forKey: testKey)
        XCTAssertEqual(retrievedItem, updatedCredentials, "updateOrAddItem should update the item if it exists.")
    }

    /// Test deleting an item from Keychain
    func testDeleteItem() throws {
        try keychainKeeper.addItem(sampleCredentials, forKey: testKey)
        
        XCTAssertNoThrow(try keychainKeeper.deleteItem(forKey: testKey))
        
        XCTAssertThrowsError(try keychainKeeper.retrieveItem(forKey: testKey)) { error in
            guard case .itemNotFound = error as? KeychainError else {
                return XCTFail("Retrieving a deleted item should throw itemNotFound error.")
            }
        }
    }

    /// Test deleting a non-existing item should throw `itemNotFound`
    func testDeleteNonExistentItemThrowsError() throws {
        XCTAssertThrowsError(try keychainKeeper.deleteItem(forKey: testKey)) { error in
            guard case .itemNotFound = error as? KeychainError else {
                return XCTFail("Deleting a non-existent item should throw itemNotFound error.")
            }
        }
    }
}
