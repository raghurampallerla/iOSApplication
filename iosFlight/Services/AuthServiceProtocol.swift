import Foundation

protocol AuthServiceProtocol {
    func login(username: String, password: String) async throws -> String
}

enum AuthError: Error, LocalizedError, Equatable {
    case invalidCredentials
    case serverError
    
    var errorDescription: String? {
        switch self {
        case .invalidCredentials: return "Invalid username or password"
        case .serverError: return "Server error. Please try again."
        }
    }
}

class AuthService: AuthServiceProtocol {
    private let authRepository = AuthRepository.shared
    
    func login(username: String, password: String) async throws -> String {
        let result = await authRepository.authenticate(username: username, password: password)
        
        switch result {
        case .success(let token):
            return token
        case .failure(let message):
            throw AuthError.invalidCredentials
        }
    }
}

class MockAuthService: AuthServiceProtocol {
    var shouldSucceed = true
    var token = "mockToken123"
    var errorToThrow: Error?
    
    func login(username: String, password: String) async throws -> String {
        if let error = errorToThrow { throw error }
        if shouldSucceed { return token }
        throw AuthError.invalidCredentials
    }
}

