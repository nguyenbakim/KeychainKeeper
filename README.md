# KeychainKeeper
KeychainKeeper is a lightweight utility for securely storing and retrieving Codable objects in the Keychain.

## Features
- Store and retrieve any Codable object securely
- Supports adding, updating, and deleting items in the Keychain
- Uses Dependency Injection (DataEncoder & DataDecoder) for flexibility
- Custom error handling using KeychainError enum
- Works on iOS & macOS


## Installation
### Using Swift Package Manager (SPM)
Follow Apple's guide for [adding a package dependency to your app]
```Swift
https://github.com/nguyenbakim/KeychainKeeper.git
```
or
```Swift
git@github.com:nguyenbakim/KeychainKeeper.git
```
### Manual
You can also manually copy the source code to your project
## Usage
```Swift
import KeychainKeeper
```
- Define codable struct to hold data
```Swift
struct Credentials: Codable {
    let username: String
    let password: String
}
let store = KeychainKeeper<Credentials>()
let credentials = Credentials(username: "john_doe", password: "SecureP@ssw0rd")
```
- Store item into Keychain
```Swift
do {
    try store.addItem(credentials, forKey: "current_user")
} catch {
    // handle error
}
```
- Retrieve an item from Keychain
```Swift
do {
    let credentials = try keychain.retrieveItem(forKey: "current_user")
} catch {
    // handle error
}
```
- Update an item
```Swift
do {
    let newCredentials = Credentials(username: "john_doe", password: "NewSecureP@ssw0rd")
    try keychain.updateItem(newCredentials, forKey: "current_user")
} catch {
    // handle error
}
```
- Update or add an item: Add an item if it does not exist or overwrite if it exists
```Swift
do {
    let credentials = Credentials(username: "new_user", password: "SecureP@assw0rd")
    try keychain.updateOrAddItem(credentials, forKey: "current_user")
} catch {
    // handle error
}
```
- Delete an item from the Keychain
```swift
do {
    try keychain.deleteItem(forKey: "current_user")
} catch {
    // handle error
}
```
# Error handling
KeychainKeeper provides detailed error via the KeychainError enum:
| Error | Meaning |
| ------ | ------ |
| .itemNotFound | The requested item does not exist in Keychain. |
| .itemAlreadyExists | Trying to add an item that already exists. |
| .encodingFailed(Error) | Failed to encode an object to Data before storing. |
| .decodingFailed(Error) | Failed to decode from Data an object when retrieving. |
| .operationFailed(OSStatus) | Generic Keychain error with an OSStatus code. |

```Swift
do {
    let credentials = try keychain.retrieveItem(forKey: "current_user")
} catch KeychainError.itemNotFound {
    print("No credentials found!")
} catch {
    print("Unknown error: \(error)")
}
```

[adding a package dependency to your app]: <https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app>
