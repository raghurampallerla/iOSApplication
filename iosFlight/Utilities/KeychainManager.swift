import Foundation
import Security

class KeychainManager {
    static let shared = KeychainManager()
    
    private let serviceName = "com.iosFlight.app"
    private let tokenKey = "auth_token"
    private let usernameKey = "username"
    private let passwordKey = "password"
    
    // MARK: - Token Management
    func saveToken(_ token: String) {
        saveToKeychain(key: tokenKey, value: token)
    }
    
    func getToken() -> String? {
        return getFromKeychain(key: tokenKey)
    }
    
    func clearToken() {
        deleteFromKeychain(key: tokenKey)
    }
    
    // MARK: - Credentials Management
    func saveCredentials(username: String, password: String) {
        saveToKeychain(key: usernameKey, value: username)
        saveToKeychain(key: passwordKey, value: password)
    }
    
    func getCredentials() -> (username: String?, password: String?) {
        let username = getFromKeychain(key: usernameKey)
        let password = getFromKeychain(key: passwordKey)
        return (username, password)
    }
    
    func clearCredentials() {
        deleteFromKeychain(key: usernameKey)
        deleteFromKeychain(key: passwordKey)
    }
    
    // MARK: - Keychain Helper Methods
    private func saveToKeychain(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func deleteFromKeychain(key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

