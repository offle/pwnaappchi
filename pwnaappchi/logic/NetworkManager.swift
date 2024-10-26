import Foundation
import Network
import Citadel
import NIO

class NetworkManager: ObservableObject {
    @Published var latency: TimeInterval? = nil
    @Published var isReachable: Bool = false
    @Published var isPort22Reachable: Bool = false
    @Published var isPort80Reachable: Bool = false
    @Published var isPort8080Reachable: Bool = false
    @Published var isPort8081Reachable: Bool = false
    @Published var configToml: String = ""
    @Published var pwnagotchiName: String = "<none>"
    
    private let utils = Utils()

    private func resetPortAvailability() {
        self.isPort22Reachable = false
        self.isPort80Reachable = false
        self.isPort8080Reachable = false
        self.isPort8081Reachable = false
    }

    func checkConnection() {
        let pwnIp = UserDefaults.standard.string(forKey: "pwnIp") ?? "127.0.0.1"
        let startTime = Date()
        
        // Check TCP port 22 with latency
        let connection22 = NWConnection(host: NWEndpoint.Host(pwnIp), port: 22, using: .tcp)
        connection22.stateUpdateHandler = { state in
            switch state {
            case .ready:
                let endTime = Date()
                let pingLatency = endTime.timeIntervalSince(startTime) * 1000 // Latenz in ms
                DispatchQueue.main.async {
                    self.latency = pingLatency
                }
                connection22.cancel()
                Task {
                                do {
                                    try await self.getPwnagotchiConfig(pwnIp: pwnIp)
                                } catch {
                                    debugPrint("Failed to get config: \(error)")
                                }
                            }
                
            case .failed(_):
                DispatchQueue.main.async {
                    self.latency = nil
                    self.isReachable = false
                }
                connection22.cancel()
            default:
                break
            }
        }
        connection22.start(queue: .global())
        
        // Check TCP port 22 without latency
        checkPort(host: pwnIp, port: 22) { isReachable in
            DispatchQueue.main.async {
                self.isPort22Reachable = isReachable
            }
        }
        
        // Check TCP port 80 without latency
        checkPort(host: pwnIp, port: 80) { isReachable in
            DispatchQueue.main.async {
                self.isPort80Reachable = isReachable
            }
        }
        
        // Check TCP port 8080 without latency
        checkPort(host: pwnIp, port: 8080) { isReachable in
            DispatchQueue.main.async {
                self.isPort8080Reachable = isReachable
            }
        }
        
        // Check TCP port 8081 without latency
        checkPort(host: pwnIp, port: 8081) { isReachable in
            DispatchQueue.main.async {
                self.isPort8081Reachable = isReachable
            }
        }
        
        
    }

    private func checkPort(host: String, port: UInt16, completion: @escaping (Bool) -> Void) {
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
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
        let handshakeDirectory = UserDefaults.standard.string(forKey: "handshakeDir") ?? "/root/handshakes"
        let linuxUser = UserDefaults.standard.string(forKey: "linuxUser") ?? "root"
        let linuxPassword = UserDefaults.standard.string(forKey: "linuxPassword") ?? "root"
        debugPrint("Establishing connection to \(pwnIp) at folder \(handshakeDirectory)")
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
            debugPrint("Reading config.toml on \(pwnIp)")
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

            DispatchQueue.main.async {
                self.configToml = configTomlString
                self.pwnagotchiName = pwnName
                debugPrint("Name is: \(self.pwnagotchiName)")
            }
            
            try await client.close()
        } catch {
            throw error
        }
    }

}
    

