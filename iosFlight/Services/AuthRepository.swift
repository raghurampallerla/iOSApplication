import Foundation

enum AuthResult {
    case success(token: String)
    case failure(message: String)
}

class AuthRepository {
    static let shared = AuthRepository()
    
    private let keychainManager = KeychainManager.shared
    
    private struct Keys {
        static let rememberMe = "remember_me"
        static let savedUsername = "saved_username"
        static let savedPassword = "saved_password"
        static let authToken = "auth_token"
        static let failureCount = "failure_count"
        static let lockoutTimestamp = "lockout_timestamp"
    }
    
    private let maxFailureAttempts = 3
    private let lockoutDurationMs: Int64 = 1 * 60 * 1000 // 1 minute
    
    private init() {}
    
    // MARK: - Authentication
    func authenticate(username: String, password: String) async -> AuthResult {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        // Mock authentication - require specific credentials for testing
        // Valid credentials: username="admin", password="password123"
        let validUsername = "admin"
        let validPassword = "password123"
        
        if username == validUsername && password == validPassword {
            // Generate a mock auth token on successful login
            let token = "auth_token_\(Int64(Date().timeIntervalSince1970 * 1000))_\(username)"
            return .success(token: token)
        } else {
            return .failure(message: "Invalid username or password")
        }
    }
    
    // MARK: - Failure Count Management
    func getFailureCount() -> Int {
        return UserDefaults.standard.integer(forKey: Keys.failureCount)
    }
    
    func incrementFailureCount() {
        let currentCount = getFailureCount()
        let newCount = currentCount + 1
        UserDefaults.standard.set(newCount, forKey: Keys.failureCount)
        
        // If we've reached max failures, set lockout timestamp
        if newCount >= maxFailureAttempts {
            let timestamp = Int64(Date().timeIntervalSince1970 * 1000)
            UserDefaults.standard.set(timestamp, forKey: Keys.lockoutTimestamp)
        }
    }
    
    func resetFailureCount() {
        UserDefaults.standard.removeObject(forKey: Keys.failureCount)
        UserDefaults.standard.removeObject(forKey: Keys.lockoutTimestamp)
    }
    
    // MARK: - Lockout Management
    func isLockedOut() -> Bool {
        guard let timestamp = UserDefaults.standard.object(forKey: Keys.lockoutTimestamp) as? Int64 else {
            return false
        }
        
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        let elapsed = currentTime - timestamp
        return elapsed < lockoutDurationMs
    }
    
    func getRemainingLockoutTime() -> Int64 {
        guard let timestamp = UserDefaults.standard.object(forKey: Keys.lockoutTimestamp) as? Int64 else {
            return 0
        }
        
        let currentTime = Int64(Date().timeIntervalSince1970 * 1000)
        let elapsed = currentTime - timestamp
        let remaining = lockoutDurationMs - elapsed
        return remaining > 0 ? remaining : 0
    }
    
    // MARK: - Remember Me & Credentials
    func saveRememberMe(username: String, password: String, remember: Bool) {
        UserDefaults.standard.set(remember, forKey: Keys.rememberMe)
        
        if remember {
            // Use Keychain for secure storage of credentials
            keychainManager.saveCredentials(username: username, password: password)
        } else {
            keychainManager.clearCredentials()
            keychainManager.clearToken()
        }
    }
    
    func getSavedCredentials() -> (username: String?, password: String?) {
        return keychainManager.getCredentials()
    }
    
    func getRememberMeFlag() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.rememberMe)
    }
    
    // MARK: - Auth Token Management
    func saveAuthToken(_ token: String) {
        keychainManager.saveToken(token)
    }
    
    func getAuthToken() -> String? {
        return keychainManager.getToken()
    }
    
    func clearAuthToken() {
        keychainManager.clearToken()
    }
}