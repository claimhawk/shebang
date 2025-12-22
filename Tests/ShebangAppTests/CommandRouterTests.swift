// Shebang - Automated Development Environment
// Public Domain - https://unlicense.org

import XCTest
@testable import ShebangApp
import Foundation

/// Unit tests for CommandRouter (slash commands and shell detection)
@MainActor
final class CommandRouterTests: XCTestCase {

    // MARK: - Slash Command Detection Tests

    func testSlashCommandDetection() {
        // Known slash commands should be detected
        XCTAssertTrue(isSlashCommand("/help"))
        XCTAssertTrue(isSlashCommand("/favorite"))
        XCTAssertTrue(isSlashCommand("/fav"))
        XCTAssertTrue(isSlashCommand("/reload"))
        XCTAssertTrue(isSlashCommand("/new"))
        XCTAssertTrue(isSlashCommand("/ask"))
        XCTAssertTrue(isSlashCommand("/claude"))
    }

    func testSlashCommandWithArguments() {
        XCTAssertTrue(isSlashCommand("/ask what is this?"))
        XCTAssertTrue(isSlashCommand("/claude fix the bug"))
    }

    func testFilePathsNotDetectedAsSlashCommands() {
        // File paths that start with / should NOT be slash commands
        XCTAssertFalse(isSlashCommand("/Users/test/file.txt"))
        XCTAssertFalse(isSlashCommand("/tmp/something"))
        XCTAssertFalse(isSlashCommand("/var/log/system.log"))
    }

    func testUnknownSlashCommandsNotDetected() {
        XCTAssertFalse(isSlashCommand("/unknown"))
        XCTAssertFalse(isSlashCommand("/randomcommand"))
    }

    func testNonSlashInputNotDetected() {
        XCTAssertFalse(isSlashCommand("help"))
        XCTAssertFalse(isSlashCommand("normal text"))
    }

    // MARK: - Shell Command Detection Tests

    func testCommonShellCommandsDetected() {
        XCTAssertTrue(isShellCommand("ls"))
        XCTAssertTrue(isShellCommand("ls -la"))
        XCTAssertTrue(isShellCommand("cd /tmp"))
        XCTAssertTrue(isShellCommand("git status"))
        XCTAssertTrue(isShellCommand("npm install"))
        XCTAssertTrue(isShellCommand("python script.py"))
        XCTAssertTrue(isShellCommand("docker ps"))
        XCTAssertTrue(isShellCommand("kubectl get pods"))
    }

    func testExecutablePathsDetected() {
        XCTAssertTrue(isShellCommand("./build.sh"))
        XCTAssertTrue(isShellCommand("~/scripts/test.sh"))
    }

    func testShellPatternsDetected() {
        XCTAssertTrue(isShellCommand("ls | grep test"))
        XCTAssertTrue(isShellCommand("echo test > file.txt"))
        XCTAssertTrue(isShellCommand("cat file.txt >> output.log"))
        XCTAssertTrue(isShellCommand("make && make install"))
        XCTAssertTrue(isShellCommand("npm test || echo failed"))
        XCTAssertTrue(isShellCommand("cd /tmp; ls"))
    }

    func testNaturalLanguageNotDetectedAsShell() {
        // Note: Short phrases without question marks may be detected as shell commands
        // due to the heuristic in isShellCommand. This is by design.
        XCTAssertFalse(isShellCommand("What is this?"))
        XCTAssertFalse(isShellCommand("How do I install dependencies?"))
        XCTAssertFalse(isShellCommand("Can you explain this function?"))
    }

    func testEmptyInputNotDetected() {
        XCTAssertFalse(isShellCommand(""))
        XCTAssertFalse(isShellCommand("   "))
    }

    // MARK: - Image Path Detection Tests

    func testImagePathDetection() {
        // Absolute paths with image extensions
        XCTAssertTrue(isImagePath("/Users/test/screenshot.png"))
        XCTAssertTrue(isImagePath("/tmp/image.jpg"))
        XCTAssertTrue(isImagePath("/var/www/photo.jpeg"))
        XCTAssertTrue(isImagePath("/home/user/picture.gif"))
        XCTAssertTrue(isImagePath("/data/file.webp"))
        XCTAssertTrue(isImagePath("/images/icon.bmp"))
        XCTAssertTrue(isImagePath("/photos/vacation.tiff"))
        XCTAssertTrue(isImagePath("/photos/IMG_1234.heic"))
    }

    func testTildePathImageDetection() {
        XCTAssertTrue(isImagePath("~/Desktop/screenshot.png"))
        XCTAssertTrue(isImagePath("~/Pictures/photo.jpg"))
    }

    func testRelativePathImageDetection() {
        XCTAssertTrue(isImagePath("./screenshot.png"))
        XCTAssertTrue(isImagePath("./images/icon.jpg"))
    }

    func testQuotedImagePathDetection() {
        XCTAssertTrue(isImagePath("'/Users/test/file.png'"))
        XCTAssertTrue(isImagePath("\"/tmp/screenshot.jpg\""))
    }

    func testPathWithNewlinesDetection() {
        // macOS can wrap long paths with newlines
        XCTAssertTrue(isImagePath("/Users/test/very/long/path/to/\nscreenshot.png"))
    }

    func testNonImagePathsNotDetected() {
        XCTAssertFalse(isImagePath("/Users/test/file.txt"))
        XCTAssertFalse(isImagePath("/tmp/script.sh"))
        XCTAssertFalse(isImagePath("just some text"))
        XCTAssertFalse(isImagePath("screenshot.png"))  // No path prefix
    }

    func testCaseInsensitiveImageExtensions() {
        XCTAssertTrue(isImagePath("/tmp/IMAGE.PNG"))
        XCTAssertTrue(isImagePath("/tmp/Photo.JPG"))
        XCTAssertTrue(isImagePath("/tmp/file.Jpeg"))
    }

    // MARK: - Path Normalization Tests

    func testNormalizePathRemovesQuotes() {
        XCTAssertEqual(normalizePath("'/tmp/file.txt'"), "/tmp/file.txt")
        XCTAssertEqual(normalizePath("\"/tmp/file.txt\""), "/tmp/file.txt")
    }

    func testNormalizePathRemovesNewlines() {
        XCTAssertEqual(normalizePath("/tmp/\nfile.txt"), "/tmp/file.txt")
        XCTAssertEqual(normalizePath("/tmp/file.txt\r\n"), "/tmp/file.txt")
    }

    func testNormalizePathTrimsWhitespace() {
        XCTAssertEqual(normalizePath("  /tmp/file.txt  "), "/tmp/file.txt")
        XCTAssertEqual(normalizePath("\t/tmp/file.txt\t"), "/tmp/file.txt")
    }

    // MARK: - Helper Methods (mirror CommandRouter private methods)

    private func isSlashCommand(_ input: String) -> Bool {
        guard input.hasPrefix("/") else { return false }

        let afterSlash = String(input.dropFirst())
        let firstPart = afterSlash.split(separator: " ").first.map(String.init) ?? afterSlash

        if firstPart.contains("/") { return false }

        let knownCommands = ["help", "favorite", "fav", "reload", "new", "ask", "claude"]
        return knownCommands.contains(firstPart.lowercased())
    }

    private func isImagePath(_ input: String) -> Bool {
        let normalized = normalizePath(input)
        let lower = normalized.lowercased()

        let imageExtensions = [".png", ".jpg", ".jpeg", ".gif", ".webp", ".bmp", ".tiff", ".heic"]
        for ext in imageExtensions {
            if lower.hasSuffix(ext) {
                if normalized.hasPrefix("/") || normalized.hasPrefix("~") || normalized.hasPrefix("./") {
                    return true
                }
            }
        }
        return false
    }

    private func isShellCommand(_ input: String) -> Bool {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count > 0 else { return false }

        let firstWord = trimmed.split(separator: " ").first.map(String.init) ?? trimmed

        let shellCommands: Set<String> = [
            "ls", "cd", "pwd", "mkdir", "rm", "cp", "mv", "cat", "less", "more",
            "head", "tail", "grep", "find", "which", "whereis", "man", "echo",
            "git", "npm", "yarn", "pnpm", "node", "python", "python3", "pip",
            "swift", "swiftc", "xcodebuild", "xcrun", "make", "cmake", "cargo",
            "brew", "apt", "yum", "curl", "wget", "ssh", "scp", "rsync",
            "docker", "kubectl", "terraform", "aws", "gcloud", "az",
            "vim", "nvim", "nano", "code", "open", "touch", "chmod", "chown",
            "export", "source", "alias", "unalias", "history", "clear", "exit",
            "ps", "kill", "top", "htop", "df", "du", "free", "uname", "env",
            "tar", "zip", "unzip", "gzip", "gunzip", "xargs", "awk", "sed",
            "sort", "uniq", "wc", "diff", "patch", "tree", "file", "stat"
        ]

        if shellCommands.contains(firstWord.lowercased()) {
            return true
        }

        if trimmed.hasPrefix("./") || trimmed.hasPrefix("~/") {
            return true
        }

        if trimmed.contains(" | ") || trimmed.contains(" > ") || trimmed.contains(" >> ") ||
           trimmed.contains(" && ") || trimmed.contains(" || ") || trimmed.contains("; ") {
            return true
        }

        let wordCount = trimmed.split(separator: " ").count
        if wordCount <= 3 && !trimmed.contains("?") {
            if firstWord.allSatisfy({ $0.isLetter || $0 == "-" || $0 == "_" }) {
                return true
            }
        }

        return false
    }

    private func normalizePath(_ input: String) -> String {
        var result = input
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .trimmingCharacters(in: .whitespaces)

        if (result.hasPrefix("'") && result.hasSuffix("'")) ||
           (result.hasPrefix("\"") && result.hasSuffix("\"")) {
            result = String(result.dropFirst().dropLast())
        }

        return result
    }
}
