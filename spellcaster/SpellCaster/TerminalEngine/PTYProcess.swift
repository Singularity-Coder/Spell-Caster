import Foundation
import Darwin

// MARK: - Wait Status Macros
// These macros are not available in Swift, so we implement them manually

private func WIFEXITED(_ status: Int32) -> Bool {
    return (status & 0x7f) == 0
}

private func WEXITSTATUS(_ status: Int32) -> Int32 {
    return (status >> 8) & 0xff
}

private func WIFSIGNALED(_ status: Int32) -> Bool {
    return ((status & 0x7f) + 1) >> 1 > 0
}

private func WTERMSIG(_ status: Int32) -> Int32 {
    return status & 0x7f
}

/// PTY process management using forkpty
class PTYProcess {
    // MARK: - Properties
    
    private var masterFD: Int32 = -1
    private var childPID: pid_t = -1
    private var readSource: DispatchSourceRead?
    private var processSource: DispatchSourceProcess?
    private let queue = DispatchQueue(label: "com.spellcaster.pty", qos: .userInitiated)
    
    var isRunning: Bool {
        return childPID > 0 && masterFD >= 0
    }
    
    // MARK: - Callbacks
    
    var onOutput: ((Data) -> Void)?
    var onExit: ((Int32) -> Void)?
    
    // MARK: - Initialization
    
    init() {}
    
    deinit {
        terminate()
    }
    
    // MARK: - Process Management
    
    /// Launch a new PTY process
    func launch(
        command: String,
        arguments: [String] = [],
        environment: [String: String] = [:],
        workingDirectory: String? = nil,
        rows: Int = 24,
        columns: Int = 80
    ) throws {
        guard !isRunning else {
            throw PTYError.alreadyRunning
        }
        
        // Prepare window size
        var winsize = winsize(
            ws_row: UInt16(rows),
            ws_col: UInt16(columns),
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        
        // Prepare environment
        var env = ProcessInfo.processInfo.environment
        for (key, value) in environment {
            env[key] = value
        }
        
        // Add TERM if not present
        if env["TERM"] == nil {
            env["TERM"] = "xterm-256color"
        }
        
        // Convert environment to C strings
        let envStrings = env.map { "\($0.key)=\($0.value)" }
        let envPointers = envStrings.map { strdup($0) }
        defer {
            envPointers.forEach { free($0) }
        }
        
        // Prepare arguments
        let args = [command] + arguments
        let argPointers = args.map { strdup($0) }
        defer {
            argPointers.forEach { free($0) }
        }
        
        // Fork PTY
        var master: Int32 = -1
        let pid = forkpty(&master, nil, nil, &winsize)
        
        if pid < 0 {
            throw PTYError.forkFailed(errno)
        } else if pid == 0 {
            // Child process
            
            // Change working directory if specified
            if let cwd = workingDirectory {
                chdir(cwd)
            }
            
            // Execute command
            var argv = argPointers + [nil]
            var envp = envPointers + [nil]
            execve(command, &argv, &envp)
            
            // If execve returns, it failed
            perror("execve failed")
            _exit(1)
        } else {
            // Parent process
            self.masterFD = master
            self.childPID = pid
            
            // Set non-blocking mode
            var flags = fcntl(master, F_GETFL, 0)
            flags |= O_NONBLOCK
            fcntl(master, F_SETFL, flags)
            
            // Set up read source
            setupReadSource()
            
            // Set up process monitoring
            setupProcessMonitoring()
        }
    }
    
    /// Write data to the PTY
    func write(_ data: Data) throws {
        guard isRunning else {
            throw PTYError.notRunning
        }
        
        try data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            guard let baseAddress = bytes.baseAddress else { return }
            
            var totalWritten = 0
            let length = data.count
            
            while totalWritten < length {
                let written = Darwin.write(
                    masterFD,
                    baseAddress.advanced(by: totalWritten),
                    length - totalWritten
                )
                
                if written < 0 {
                    if errno == EAGAIN || errno == EINTR {
                        continue
                    }
                    throw PTYError.writeFailed(errno)
                }
                
                totalWritten += written
            }
        }
    }
    
    /// Write string to the PTY
    func write(_ string: String) throws {
        guard let data = string.data(using: .utf8) else {
            throw PTYError.invalidData
        }
        try write(data)
    }
    
    /// Resize the PTY
    func resize(rows: Int, columns: Int) throws {
        guard isRunning else {
            throw PTYError.notRunning
        }
        
        var winsize = winsize(
            ws_row: UInt16(rows),
            ws_col: UInt16(columns),
            ws_xpixel: 0,
            ws_ypixel: 0
        )
        
        if ioctl(masterFD, TIOCSWINSZ, &winsize) < 0 {
            throw PTYError.resizeFailed(errno)
        }
    }
    
    /// Send a signal to the child process
    func sendSignal(_ signal: Int32) throws {
        guard isRunning else {
            throw PTYError.notRunning
        }
        
        if kill(childPID, signal) < 0 {
            throw PTYError.signalFailed(errno)
        }
    }
    
    /// Terminate the process gracefully
    func terminate() {
        guard isRunning else { return }
        
        // Cancel sources
        readSource?.cancel()
        readSource = nil
        processSource?.cancel()
        processSource = nil
        
        // Send SIGHUP to child
        _ = try? sendSignal(SIGHUP)
        
        // Wait briefly for graceful exit
        usleep(100_000) // 100ms
        
        // Force kill if still running
        if kill(childPID, 0) == 0 {
            _ = try? sendSignal(SIGKILL)
        }
        
        // Close master FD
        if masterFD >= 0 {
            close(masterFD)
            masterFD = -1
        }
        
        // Wait for child
        if childPID > 0 {
            var status: Int32 = 0
            waitpid(childPID, &status, WNOHANG)
            childPID = -1
        }
    }
    
    // MARK: - Private Methods
    
    private func setupReadSource() {
        readSource = DispatchSource.makeReadSource(fileDescriptor: masterFD, queue: queue)
        
        readSource?.setEventHandler { [weak self] in
            self?.handleRead()
        }
        
        readSource?.setCancelHandler { [weak self] in
            guard let self = self else { return }
            if self.masterFD >= 0 {
                close(self.masterFD)
                self.masterFD = -1
            }
        }
        
        readSource?.resume()
    }
    
    private func handleRead() {
        let bufferSize = 4096
        var buffer = [UInt8](repeating: 0, count: bufferSize)
        
        while true {
            let bytesRead = read(masterFD, &buffer, bufferSize)
            
            if bytesRead > 0 {
                let data = Data(buffer.prefix(bytesRead))
                onOutput?(data)
            } else if bytesRead == 0 {
                // EOF
                break
            } else {
                if errno == EAGAIN || errno == EWOULDBLOCK {
                    // No more data available
                    break
                } else if errno != EINTR {
                    // Error
                    break
                }
            }
        }
    }
    
    private func setupProcessMonitoring() {
        guard childPID > 0 else { return }
        
        processSource = DispatchSource.makeProcessSource(
            identifier: childPID,
            eventMask: .exit,
            queue: queue
        )
        
        processSource?.setEventHandler { [weak self] in
            guard let self = self else { return }
            
            var status: Int32 = 0
            waitpid(self.childPID, &status, WNOHANG)
            
            let exitCode: Int32
            if WIFEXITED(status) {
                exitCode = WEXITSTATUS(status)
            } else if WIFSIGNALED(status) {
                exitCode = 128 + WTERMSIG(status)
            } else {
                exitCode = -1
            }
            
            self.childPID = -1
            self.onExit?(exitCode)
        }
        
        processSource?.resume()
    }
}

// MARK: - PTY Error

enum PTYError: Error, LocalizedError {
    case alreadyRunning
    case notRunning
    case forkFailed(Int32)
    case writeFailed(Int32)
    case resizeFailed(Int32)
    case signalFailed(Int32)
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .alreadyRunning:
            return "PTY process is already running"
        case .notRunning:
            return "PTY process is not running"
        case .forkFailed(let errno):
            return "Failed to fork PTY: \(String(cString: strerror(errno)))"
        case .writeFailed(let errno):
            return "Failed to write to PTY: \(String(cString: strerror(errno)))"
        case .resizeFailed(let errno):
            return "Failed to resize PTY: \(String(cString: strerror(errno)))"
        case .signalFailed(let errno):
            return "Failed to send signal: \(String(cString: strerror(errno)))"
        case .invalidData:
            return "Invalid data encoding"
        }
    }
}
