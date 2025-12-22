// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import SwiftUI

/// Setup wizard shown when required dependencies are missing
/// Guides users through installing Homebrew, dtach, and Claude Code
struct SetupWizardView: View {
    @State private var checker = DependencyChecker.shared
    @State private var isInstalling = false
    @State private var installOutput: String = ""
    @State private var currentStep: SetupStep = .welcome

    /// Callback when setup is complete (all deps installed or user skipped)
    var onComplete: () -> Void

    enum SetupStep {
        case welcome
        case installing
        case complete
    }

    var body: some View {
        ZStack {
            // Background gradient (matches splash)
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color(red: 0.1, green: 0.08, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("Shebang Setup")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Let's get your environment ready")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 40)
                .padding(.bottom, 30)

                // Content based on step
                switch currentStep {
                case .welcome:
                    welcomeContent
                case .installing:
                    installingContent
                case .complete:
                    completeContent
                }

                Spacer()

                // Footer buttons
                HStack {
                    if currentStep == .welcome && !checker.allDependenciesInstalled {
                        Button("Skip for Now") {
                            onComplete()
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if currentStep == .welcome {
                        if checker.allDependenciesInstalled {
                            Button("Continue") {
                                onComplete()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        } else {
                            Button("Install Dependencies") {
                                startInstallation()
                            }
                            .buttonStyle(PrimaryButtonStyle())
                        }
                    } else if currentStep == .complete {
                        Button("Get Started") {
                            onComplete()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }
                }
                .padding(30)
            }
        }
        .frame(minWidth: 500, minHeight: 450)
    }

    // MARK: - Welcome Content

    private var welcomeContent: some View {
        VStack(spacing: 20) {
            // Dependency checklist
            VStack(alignment: .leading, spacing: 12) {
                ForEach(checker.dependencies) { dep in
                    DependencyRow(dependency: dep)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal, 40)

            if checker.allDependenciesInstalled {
                Text("All dependencies installed!")
                    .font(.headline)
                    .foregroundColor(.green)
            } else {
                Text("Missing dependencies will be installed via Homebrew")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Installing Content

    private var installingContent: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .padding()

            Text("Installing dependencies...")
                .font(.headline)
                .foregroundColor(.white)

            // Installation output
            ScrollView {
                Text(installOutput)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.green.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(height: 150)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.3))
            )
            .padding(.horizontal, 40)

            Text("This may take a few minutes...")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Complete Content

    private var completeContent: some View {
        VStack(spacing: 20) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)

            Text("Setup Complete!")
                .font(.title2.bold())
                .foregroundColor(.white)

            // Show final status
            VStack(alignment: .leading, spacing: 8) {
                ForEach(checker.dependencies) { dep in
                    HStack {
                        Image(systemName: dep.isInstalled ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(dep.isInstalled ? .green : .red)
                        Text(dep.name)
                            .foregroundColor(.white)
                        Spacer()
                        if dep.isInstalled, let path = dep.path {
                            Text(path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
            )
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Installation Logic

    private func startInstallation() {
        currentStep = .installing
        isInstalling = true
        installOutput = ""

        Task {
            await installMissingDependencies()
            await checker.checkAll()
            isInstalling = false
            currentStep = .complete
        }
    }

    private func installMissingDependencies() async {
        // Install Homebrew first if needed
        if !checker.brewAvailable {
            appendOutput("Installing Homebrew...\n")
            let success = await runInstallCommand(
                "/bin/bash",
                args: ["-c", "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"]
            )
            if success {
                appendOutput("Homebrew installed!\n\n")
                // Add brew to PATH for subsequent commands
                _ = await runInstallCommand("/bin/bash", args: ["-c", "eval \"$(/opt/homebrew/bin/brew shellenv)\""])
            } else {
                appendOutput("Failed to install Homebrew. Please install manually.\n\n")
                return
            }
        }

        // Get brew path
        let brewPath = checker.brewPath ?? "/opt/homebrew/bin/brew"

        // Install dtach if needed
        if !checker.dtachAvailable {
            appendOutput("Installing dtach...\n")
            let success = await runInstallCommand(brewPath, args: ["install", "dtach"])
            if success {
                appendOutput("dtach installed!\n\n")
            } else {
                appendOutput("Failed to install dtach.\n\n")
            }
        }

        // Check Claude Code (optional - don't fail if missing)
        let claudeInstalled = checker.dependencies.first(where: { $0.id == "claude" })?.isInstalled ?? false
        if !claudeInstalled {
            appendOutput("Note: Claude Code not found.\n")
            appendOutput("Install with: npm install -g @anthropic-ai/claude-code\n\n")
        }

        appendOutput("Installation complete!\n")
    }

    private func runInstallCommand(_ command: String, args: [String]) async -> Bool {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: command)
                process.arguments = args

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = pipe

                // Stream output
                pipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                        DispatchQueue.main.async {
                            self.appendOutput(output)
                        }
                    }
                }

                do {
                    try process.run()
                    process.waitUntilExit()
                    pipe.fileHandleForReading.readabilityHandler = nil
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    DispatchQueue.main.async {
                        self.appendOutput("Error: \(error.localizedDescription)\n")
                    }
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func appendOutput(_ text: String) {
        installOutput += text
    }
}

// MARK: - Dependency Row

struct DependencyRow: View {
    let dependency: DependencyChecker.DependencyStatus

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: dependency.isInstalled ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 20))
                .foregroundColor(dependency.isInstalled ? .green : .secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(dependency.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)

                Text(dependency.description)
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if dependency.isInstalled, let path = dependency.path {
                Text(URL(fileURLWithPath: path).lastPathComponent)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Primary Button Style

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(Capsule())
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

// MARK: - Preview

#Preview {
    SetupWizardView(onComplete: {})
        .frame(width: 600, height: 500)
}
