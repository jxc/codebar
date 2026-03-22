import Foundation
import Network

/// Lightweight HTTP server using Network.framework.
/// Listens on localhost for Claude Code hook POSTs.
final class HookServer {
    private var listener: NWListener?
    private let port: UInt16
    private let onEvent: @Sendable (HookEvent) -> Void

    init(port: UInt16 = Constants.hookPort, onEvent: @escaping @Sendable (HookEvent) -> Void) {
        self.port = port
        self.onEvent = onEvent
    }

    func start() throws {
        let params = NWParameters.tcp
        params.allowLocalEndpointReuse = true
        listener = try NWListener(using: params, on: NWEndpoint.Port(rawValue: port)!)
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        listener?.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[CodeBar] Hook server listening on port \(self.port)")
            case .failed(let error):
                print("[CodeBar] Hook server failed: \(error)")
            default:
                break
            }
        }
        listener?.start(queue: .global(qos: .userInitiated))
    }

    func stop() {
        listener?.cancel()
        listener = nil
    }

    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global(qos: .userInitiated))
        receiveData(on: connection, accumulated: Data())
    }

    private func receiveData(on connection: NWConnection, accumulated: Data) {
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] content, _, isComplete, error in
            guard let self else { return }

            var data = accumulated
            if let content {
                data.append(content)
            }

            if isComplete || error != nil {
                self.processHTTPRequest(data: data, connection: connection)
            } else {
                self.receiveData(on: connection, accumulated: data)
            }
        }
    }

    private func processHTTPRequest(data: Data, connection: NWConnection) {
        // Find the body after \r\n\r\n
        let separator = Data([0x0D, 0x0A, 0x0D, 0x0A]) // \r\n\r\n
        if let range = data.range(of: separator) {
            let body = data[range.upperBound...]
            if !body.isEmpty {
                do {
                    let event = try JSONDecoder().decode(HookEvent.self, from: body)
                    onEvent(event)
                } catch {
                    print("[CodeBar] Failed to parse hook event: \(error)")
                }
            }
        }

        // Respond 200 OK with empty JSON body
        let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}"
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
