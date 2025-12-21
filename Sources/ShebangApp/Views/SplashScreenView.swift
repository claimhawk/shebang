// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI

/// Splash screen shown on app launch for 3 seconds
struct SplashScreenView: View {
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0
    @State private var textOpacity: Double = 0
    @State private var creditsOpacity: Double = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.08, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                Spacer()

                // Logo
                Image(nsImage: loadAppIcon())
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 36))
                    .shadow(color: .purple.opacity(0.5), radius: 30, x: 0, y: 10)
                    .scaleEffect(logoScale)
                    .opacity(logoOpacity)

                // App name and tagline
                VStack(spacing: 8) {
                    Text("Shebang!")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .purple.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )

                    Text("A truly intelligent development environment")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .opacity(textOpacity)

                Spacer()

                // Credits
                VStack(spacing: 12) {
                    Text("Created by Michael O'Neal")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(.secondary)

                    Text("Built with")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 4)

                    HStack(spacing: 24) {
                        CreditBadge(icon: "swift", text: "Swift")
                        CreditBadge(icon: "terminal", text: "SwiftTerm")
                        CreditBadge(icon: "sparkles", text: "Claude")
                    }

                    Text("v\(AppVersion.current) \u{2022} 2024")
                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                        .foregroundStyle(.tertiary)
                        .padding(.top, 8)
                }
                .opacity(creditsOpacity)
                .padding(.bottom, 40)
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                logoScale = 1.0
                logoOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.3)) {
                textOpacity = 1.0
            }

            withAnimation(.easeOut(duration: 0.6).delay(0.6)) {
                creditsOpacity = 1.0
            }
        }
    }

    private func loadAppIcon() -> NSImage {
        // Try to load from bundle resources first
        if let icon = NSImage(named: "AppIcon") {
            return icon
        }
        // Fallback to app icon
        return NSApp.applicationIconImage ?? NSImage()
    }
}

// MARK: - Credit Badge

struct CreditBadge: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12))
            Text(text)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Preview

#Preview {
    SplashScreenView()
        .frame(width: 600, height: 500)
}
