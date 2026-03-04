import Foundation

enum ShellError: LocalizedError {
    case failed(String, code: Int32)
    case notFound

    var errorDescription: String? {
        switch self {
        case .failed(let output, let code):
            return "Command failed (exit \(code)): \(output.trimmingCharacters(in: .whitespacesAndNewlines))"
        case .notFound:
            return "Executable not found"
        }
    }
}

enum Shell {
    static func execute(_ command: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", command]

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { proc in
                let outData = stdout.fileHandleForReading.readDataToEndOfFile()
                let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: outData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errData, encoding: .utf8) ?? ""

                if proc.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let message = errorOutput.isEmpty ? output : errorOutput
                    continuation.resume(throwing: ShellError.failed(message, code: proc.terminationStatus))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    static func stream(_ command: String) -> AsyncStream<String> {
        AsyncStream { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")
            process.arguments = ["-l", "-c", command]

            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe

            pipe.fileHandleForReading.readabilityHandler = { handle in
                let data = handle.availableData
                guard !data.isEmpty else {
                    pipe.fileHandleForReading.readabilityHandler = nil
                    return
                }
                if let line = String(data: data, encoding: .utf8) {
                    continuation.yield(line)
                }
            }

            process.terminationHandler = { _ in
                pipe.fileHandleForReading.readabilityHandler = nil
                continuation.finish()
            }

            do {
                try process.run()
            } catch {
                continuation.finish()
            }

            continuation.onTermination = { _ in
                if process.isRunning {
                    process.terminate()
                }
            }
        }
    }
}
