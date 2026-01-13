import SwiftUI

struct LoginView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                VStack(spacing: 16) {
                    // Title
                    Text("Login")
                        .font(.largeTitle)
                        .bold()
                        .padding(.bottom, 8)
                        .accessibilityIdentifier("login_title")
                    
                    // Offline indicator
                    if viewModel.isOffline {
                        HStack {
                            Image(systemName: "wifi.slash")
                            Text("⚠️ No internet connection")
                                .font(.caption)
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .accessibilityIdentifier("offline_indicator")
                    }
                    
                    // Lockout message
                    if viewModel.isLockedOut {
                        HStack {
                            Image(systemName: "lock.fill")
                            Text(viewModel.lockoutMessage)
                                .font(.caption)
                                .multilineTextAlignment(.center)
                        }
                        .foregroundColor(.red)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .accessibilityIdentifier("lockout_message")
                    }
                    
                    // Error message
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                            .accessibilityIdentifier("error_message")
                    }
                    
                    // Username field
                    TextField("Username", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disabled(viewModel.isLoading || viewModel.isLockedOut)
                        .accessibilityIdentifier("username_field")
                    
                    // Password field
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .disabled(viewModel.isLoading || viewModel.isLockedOut)
                        .accessibilityIdentifier("password_field")
                    
                    // Remember Me toggle
                    HStack {
                        Toggle("Remember Me", isOn: $viewModel.rememberMe)
                            .disabled(viewModel.isLoading || viewModel.isLockedOut)
                            .accessibilityIdentifier("remember_me_checkbox")
                    }
                    .accessibilityIdentifier("remember_me_label")
                    
                    // Failure count indicator
                    if viewModel.failureCount > 0 && !viewModel.isLockedOut {
                        Text("Failed attempts: \(viewModel.failureCount)/3")
                            .font(.caption)
                            .foregroundColor(.red)
                            .accessibilityIdentifier("failure_count")
                    }
                    
                    // Login button
                    Button(action: {
                        Task { await viewModel.login() }
                    }) {
                        if viewModel.isLoading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                Text("Logging in...")
                            }
                        } else {
                            Text("Login")
                        }
                    }
                    .disabled(!viewModel.isButtonEnabled)
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .accessibilityIdentifier("login_button")
                    
                    Spacer()
                }
                .padding()
                .navigationDestination(isPresented: $viewModel.loginSuccess) {
                    WelcomeView(viewModel: viewModel)
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
            }
        } else {
            // Fallback on earlier versions
            NavigationView {
                VStack(spacing: 16) {
                    Text("Login")
                        .font(.largeTitle)
                        .bold()
                        .accessibilityIdentifier("login_title")
                    
                    TextField("Username", text: $viewModel.username)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .accessibilityIdentifier("username_field")
                    
                    SecureField("Password", text: $viewModel.password)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.none)
                        .accessibilityIdentifier("password_field")
                    
                    Toggle("Remember Me", isOn: $viewModel.rememberMe)
                        .accessibilityIdentifier("remember_me_checkbox")
                    
                    if !viewModel.errorMessage.isEmpty {
                        Text(viewModel.errorMessage)
                            .foregroundColor(.red)
                            .accessibilityIdentifier("error_message")
                    }
                    
                    Button("Login") {
                        Task { await viewModel.login() }
                    }
                    .disabled(!viewModel.isButtonEnabled)
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("login_button")
                    
                    Spacer()
                }
                .padding()
                .navigationTitle("Login")
            }
        }
    }
}

