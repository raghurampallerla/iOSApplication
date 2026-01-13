import SwiftUI

struct WelcomeView: View {
    @ObservedObject var viewModel: LoginViewModel

    var body: some View {
        VStack(spacing: 24) {
            // Success icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .padding(.bottom, 24)
                .accessibilityIdentifier("success_icon")
            
            // Success message
            Text("Login successful")
                .font(.title2)
                .bold()
                .padding(.bottom, 16)
                .accessibilityIdentifier("success_message")
            
            // Username card
            VStack(spacing: 8) {
                Text("Welcome,")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .accessibilityIdentifier("welcome_text")
                
                Text(viewModel.username)
                    .font(.title3)
                    .bold()
                    .accessibilityIdentifier("username_display")
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .cornerRadius(12)
            .accessibilityIdentifier("username_card")
            
            Spacer()
                .frame(height: 32)
            
            // Logout button
            Button(action: {
                viewModel.resetLoginState()
            }) {
                Text("Logout")
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("logout_button")
        }
        .padding()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true) // Prevent swipe back
    }
}

