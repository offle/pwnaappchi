import Foundation
import Network
import Citadel
import NIO

class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    @Published var latency: TimeInterval? = nil
    @Published var isReachable: Bool = false
    @Published var isPort22Reachable: Bool = false
    @Published var isPort80Reachable: Bool = false
    @Published var isPort8080Reachable: Bool = false
    @Published var isPort8081Reachable: Bool = false
    @Published var configToml: String = ""
    @Published var configUpdated: Bool = false
    @Published var pwnyName: String = "<none>"
    @Published var webUiUser: String = "<none>"
    @Published var webUiPassword: String = "<none>"
    
    private let utils = Utils()
    private let timeoutDuration: TimeInterval = 5
    private var connectionCheckTimer: Timer?
    private var isCheckingConnection: Bool = false
    private var wasConnectionLost: Bool = true
    private let connectionQueue = DispatchQueue(label: "com.networkmanager.connection", qos: .utility)
    
    init() {
        debugPrint("NetworkManager initialized")
        setupPeriodicConnectionCheck()
    }
    
    deinit {
        stopPeriodicConnectionCheck()
    }
    
    private func setupPeriodicConnectionCheck() {
            // Ensure we're on the main thread for timer creation
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                // Stop any existing timer
                self.stopPeriodicConnectionCheck()
                
                // Create new timer on the main thread
                debugPrint("Setting up connection check timer")
                let timer = Timer(timeInterval: 5.0,
                                target: self,
                                selector: #selector(self.timerFired),
                                userInfo: nil,
                                repeats: true)
                
                // Add to RunLoop manually to ensure single registration
                RunLoop.main.add(timer, forMode: .common)
                self.connectionCheckTimer = timer
            }
        }
    
    @objc private func timerFired() {
        debugPrint("Timer fired at: \(Date())")
        performConnectionCheckIfNeeded()
    }
    
    private func stopPeriodicConnectionCheck() {
        connectionCheckTimer?.invalidate()
        connectionCheckTimer = nil
    }
    
    func performConnectionCheckIfNeeded() {
        debugPrint("performConnectionCheckIfNeeded")
        connectionQueue.async { [weak self] in
            guard let self = self, !self.isCheckingConnection else { return }
            self.isCheckingConnection = true
            self.checkConnection()
        }
    }
    
    private func resetPortAvailability() {
        self.isPort22Reachable = false
        self.isPort80Reachable = false
        self.isPort8080Reachable = false
        self.isPort8081Reachable = false
    }
    
    private func resetConnectionStatus() {
        DispatchQueue.main.async { [weak self] in
            self?.latency = nil
            self?.isReachable = false
            self?.resetPortAvailability()
        }
    }
    
    private func checkConnection() {
        let pwnIp = UserDefaults.standard.string(forKey: "pwnIp") ?? "172.20.10.6"
        let startTime = Date()
        debugPrint("\(Date()) Checking connection to \(pwnIp)...")

        let connection22Timeout = DispatchWorkItem {
            DispatchQueue.main.async {
                self.latency = nil
                self.isReachable = false
                self.isPort22Reachable = false
                self.isCheckingConnection = false
                self.wasConnectionLost = true
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeoutDuration, execute: connection22Timeout)
        let connection22 = NWConnection(host: NWEndpoint.Host(pwnIp), port: 22, using: .tcp)
        connection22.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            switch state {
            case .ready:
                connection22Timeout.cancel()
                let endTime = Date()
                let pingLatency = endTime.timeIntervalSince(startTime) * 1000
                DispatchQueue.main.async {
                    self.latency = pingLatency
                    self.isReachable = true
                }
                connection22.cancel()
                if self.wasConnectionLost {
                    Task {
                        do {
                            try await self.getPwnagotchiConfig(pwnIp: pwnIp)
                        } catch {
                            debugPrint("Failed to get config: \(error)")
                        }
                    }
                }
                
            case .failed(_):
                self.resetConnectionStatus()
                connection22.cancel()
            default:
                self.isCheckingConnection = false
                break
            }
            self.isCheckingConnection = false
        }
        connection22.start(queue: .global())
        
        checkPortWithTimeout(host: pwnIp, port: 22) { isReachable in
            DispatchQueue.main.async {
                self.isPort22Reachable = isReachable
            }
        }
        checkPortWithTimeout(host: pwnIp, port: 80) { isReachable in
            DispatchQueue.main.async {
                self.isPort80Reachable = isReachable
            }
        }
        checkPortWithTimeout(host: pwnIp, port: 8080) { isReachable in
            DispatchQueue.main.async {
                self.isPort8080Reachable = isReachable
            }
        }
        checkPortWithTimeout(host: pwnIp, port: 8081) { isReachable in
            DispatchQueue.main.async {
                self.isPort8081Reachable = isReachable
            }
        }
    }
    
    private func checkPortWithTimeout(host: String, port: UInt16, completion: @escaping (Bool) -> Void) {
        let timeout = DispatchWorkItem {
            DispatchQueue.main.async {
                completion(false) // set to false after timeout
            }
        }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeoutDuration, execute: timeout)
        
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                timeout.cancel() // Cancel Timeout when connected
                completion(true)
                connection.cancel()
            case .failed(_):
                completion(false)
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: .global())
    }
    
    func createClient() async throws -> SSHClient {
        let pwnIp = UserDefaults.standard.string(forKey: "pwnIp") ?? "127.0.0.1"
        let captureDirectory = UserDefaults.standard.string(forKey: "captureDir") ?? "/root/captures"
        let linuxUser = UserDefaults.standard.string(forKey: "linuxUser") ?? "root"
        let linuxPassword = UserDefaults.standard.string(forKey: "linuxPassword") ?? "root"
        debugPrint("Establishing connection to \(pwnIp) at folder \(captureDirectory)")
        do {
            let client = try await SSHClient.connect(
                host: pwnIp,
                authenticationMethod: .passwordBased(username: linuxUser, password: linuxPassword),
                hostKeyValidator: .acceptAnything(),
                reconnect: .always
            )
            return client
        } catch {
            throw error
        }
    }
    
    func getPwnagotchiConfig(pwnIp: String) async throws {

            let linuxUser = UserDefaults.standard.string(forKey: "linuxUser") ?? "root"
            let linuxPassword = UserDefaults.standard.string(forKey: "linuxPassword") ?? "root"
            do {
                debugPrint("Reading config.toml on \(pwnIp) with user \(linuxUser)")
                let client = try await SSHClient.connect(
                    host: pwnIp,
                    authenticationMethod: .passwordBased(username: linuxUser, password: linuxPassword),
                    hostKeyValidator: .acceptAnything(),
                    reconnect: .always
                )
                let sftp = try await client.openSFTP()
                let configStfp = try await sftp.openFile(filePath: "/etc/pwnagotchi/config.toml", flags: .read)
                let configContents = try await configStfp.readAll()
                let configTomlString = utils.byteBufferToString(byteBuffer: configContents) ?? ""
                let pwnName = utils.getValue(from: configTomlString, key: "main.name") ?? ""
                let pwnUser = utils.getValue(from: configTomlString, key: "ui.web.username") ?? "changeme"
                let pwnPassword = utils.getValue(from: configTomlString, key: "ui.web.password") ?? "changeme"
                
                DispatchQueue.main.async {
                    self.configToml = configTomlString
                    self.pwnyName = pwnName
                    self.webUiUser = pwnUser
                    self.webUiPassword = pwnPassword
                    self.configUpdated = true
                    debugPrint("Name is: \(self.pwnyName)")
                    self.wasConnectionLost = false
                }
                
                try await client.close()
            } catch {
                throw error
            }
        }
    
}
