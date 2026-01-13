import SwiftUI
import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    
    // MARK: - Published properties
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var rememberMe: Bool = false
    @Published var isButtonEnabled: Bool = false
    @Published var isLockedOut: Bool = false
    @Published var lockoutMessage: String = ""
    @Published var isOffline: Bool = false
    @Published var errorMessage: String = ""
    @Published var loginSuccess: Bool = false
    @Published var failureCount: Int = 0
    @Published var isLoading: Bool = false
    
    // MARK: - Dependencies
    private let authRepository = AuthRepository.shared
    private let networkMonitor: NetworkMonitorProtocol
    private var lockoutTimerTask: Task<Void, Never>?
    
    // MARK: - Constants
    private let maxFailures = 3
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Init
    init(networkMonitor: NetworkMonitorProtocol = NetworkMonitor()) {
        self.networkMonitor = networkMonitor
        setupBindings()
        loadInitialState()
    }
    
    // MARK: - Combine bindings
    private func setupBindings() {
        // Enable/disable login button based on fields, offline, lockout, and loading state
        Publishers.CombineLatest4($username, $password, $isLockedOut, $isOffline)
            .combineLatest($isLoading)
            .map { args, isLoading in
                let (username, password, isLocked, isOffline) = args
                return !username.isEmpty && 
                       !password.isEmpty && 
                       !isLocked && 
                       !isOffline && 
                       !isLoading &&
                       password.count >= 6
            }
            .assign(to: &$isButtonEnabled)
        
        // Observe network changes
        networkMonitor.isOnlinePublisher
            .receive(on: RunLoop.main)
            .sink { [weak self] online in
                self?.isOffline = !online
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Initial State Loading
    private func loadInitialState() {
        Task {
            // Load saved credentials if remember me was enabled
            let rememberMeEnabled = authRepository.getRememberMeFlag()
            if rememberMeEnabled {
                let (savedUsername, savedPassword) = authRepository.getSavedCredentials()
                if let username = savedUsername, let password = savedPassword {
                    await MainActor.run {
                        self.username = username
                        self.password = password
                        self.rememberMe = true
                    }
                }
            }
            
            // Check if account is locked out
            await checkLockoutStatus()
        }
    }
    
    // MARK: - Login action
    func login() async {
        guard isButtonEnabled else { return }
        
        // Validation
        let validationError = validateInput(username: username, password: password)
        if let error = validationError {
            errorMessage = error
            return
        }
        
        // Check if offline
        if isOffline {
            errorMessage = "No internet connection. Please check your network."
            return
        }
        
        // Check lockout status
        if authRepository.isLockedOut() {
            await updateLockoutMessage()
            isLockedOut = true
            startLockoutTimerUpdate()
            return
        }
        
        // Proceed with login
        isLoading = true
        errorMessage = ""
        
        do {
            let result = await authRepository.authenticate(username: username, password: password)
            
            switch result {
            case .success(let token):
                // Reset failure count on success
                authRepository.resetFailureCount()
                
                // Save remember me preference with credentials
                authRepository.saveRememberMe(username: username, password: password, remember: rememberMe)
                
                // Persist auth token
                authRepository.saveAuthToken(token)
                
                // Update UI state
                loginSuccess = true
                errorMessage = ""
                failureCount = 0
                password = "" // Clear password from UI state on success
                isLoading = false
                
            case .failure(let message):
                // Increment failure count
                authRepository.incrementFailureCount()
                let newFailureCount = authRepository.getFailureCount()
                
                if newFailureCount >= maxFailures {
                    let remainingTime = authRepository.getRemainingLockoutTime()
                    let minutes = Int(remainingTime / 60000)
                    let seconds = Int((remainingTime % 60000) / 1000)
                    isLockedOut = true
                    lockoutMessage = "Account locked after 3 failed attempts. Please try again in \(minutes):\(String(format: "%02d", seconds))"
                    failureCount = newFailureCount
                    errorMessage = ""
                    startLockoutTimerUpdate()
                } else {
                    let remainingAttempts = maxFailures - newFailureCount
                    errorMessage = "\(message). \(remainingAttempts) attempt(s) remaining."
                    failureCount = newFailureCount
                }
                isLoading = false
            }
        } catch {
            authRepository.incrementFailureCount()
            let newFailureCount = authRepository.getFailureCount()
            errorMessage = "An error occurred: \(error.localizedDescription)"
            failureCount = newFailureCount
            isLoading = false
        }
    }
    
    // MARK: - Validation
    private func validateInput(username: String, password: String) -> String? {
        if username.isEmpty {
            return "Username cannot be empty"
        }
        if password.isEmpty {
            return "Password cannot be empty"
        }
        if password.count < 6 {
            return "Password must be at least 6 characters"
        }
        return nil
    }
    
    // MARK: - Lockout Management
    private func checkLockoutStatus() async {
        if authRepository.isLockedOut() {
            await updateLockoutMessage()
            isLockedOut = true
            startLockoutTimerUpdate()
        } else {
            failureCount = authRepository.getFailureCount()
        }
    }
    
    private func updateLockoutMessage() async {
        let remainingTime = authRepository.getRemainingLockoutTime()
        let minutes = Int(remainingTime / 60000)
        let seconds = Int((remainingTime % 60000) / 1000)
        lockoutMessage = "Account locked. Please try again in \(minutes):\(String(format: "%02d", seconds))"
    }
    
    private func startLockoutTimerUpdate() {
        lockoutTimerTask?.cancel()
        lockoutTimerTask = Task {
            while !Task.isCancelled && authRepository.isLockedOut() {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                
                if Task.isCancelled { break }
                
                let remaining = authRepository.getRemainingLockoutTime()
                if remaining > 0 {
                    let mins = Int(remaining / 60000)
                    let secs = Int((remaining % 60000) / 1000)
                    await MainActor.run {
                        lockoutMessage = "Account locked. Please try again in \(mins):\(String(format: "%02d", secs))"
                    }
                } else {
                    await MainActor.run {
                        isLockedOut = false
                        lockoutMessage = ""
                        failureCount = 0
                    }
                    authRepository.resetFailureCount()
                    break
                }
            }
        }
    }
    
    // MARK: - Reset login state
    func resetLoginState() {
        Task {
            // Clear auth token on logout
            authRepository.clearAuthToken()
            
            // Check the persisted rememberMe flag
            let rememberMeEnabled = authRepository.getRememberMeFlag()
            
            // If remember me is not enabled, clear saved credentials
            if !rememberMeEnabled {
                authRepository.saveRememberMe(username: "", password: "", remember: false)
            }
            
            // Reload credentials if remember me is enabled
            if rememberMeEnabled {
                let (savedUsername, savedPassword) = authRepository.getSavedCredentials()
                if let savedUsername = savedUsername, let savedPassword = savedPassword {
                    await MainActor.run {
                        username = savedUsername
                        password = savedPassword
                        rememberMe = true
                        loginSuccess = false
                        errorMessage = ""
                    }
                } else {
                    await MainActor.run {
                        loginSuccess = false
                        errorMessage = ""
                        password = ""
                    }
                }
            } else {
                await MainActor.run {
                    loginSuccess = false
                    errorMessage = ""
                    password = ""
                }
            }
        }
    }
    
    deinit {
        lockoutTimerTask?.cancel()
    }
}

