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

            // Try to process if we have a complete HTTP request
            if self.tryProcessHTTPRequest(data: data, connection: connection) {
                return // Successfully processed
            }

            if isComplete || error != nil {
                // Connection closed — try to process whatever we have
                self.processBody(from: data, connection: connection)
            } else {
                // Need more data
                self.receiveData(on: connection, accumulated: data)
            }
        }
    }

    /// Attempt to parse a complete HTTP request. Returns true if processed.
    private func tryProcessHTTPRequest(data: Data, connection: NWConnection) -> Bool {
        let separator = Data([0x0D, 0x0A, 0x0D, 0x0A]) // \r\n\r\n
        guard let headerEnd = data.range(of: separator) else {
            return false // Haven't received full headers yet
        }

        // Parse Content-Length from headers
        let headerData = data[data.startIndex..<headerEnd.lowerBound]
        guard let headerString = String(data: headerData, encoding: .utf8) else {
            sendResponse(connection: connection)
            return true
        }

        let contentLength = parseContentLength(from: headerString)
        let bodyStart = headerEnd.upperBound
        let receivedBodyLength = data.count - bodyStart.advanced(by: 0)

        if receivedBodyLength >= contentLength {
            // We have the full body
            let body = data[bodyStart...]
            if !body.isEmpty {
                // Verbose payload logging (gated on Preferences toggle)
                if UserDefaults.standard.bool(forKey: "debugLogging"),
                   let raw = try? JSONSerialization.jsonObject(with: body) as? [String: Any] {
                    let keys = raw.keys.sorted().joined(separator: ", ")
                    Log.debug("Raw hook keys: \(keys)")
                    let known: Set = ["session_id", "cwd", "hook_event_name", "tool_name", "tool_input",
                                      "notification_type", "source", "gitBranch", "transcript_path", "message"]
                    let extras = raw.keys.filter { !known.contains($0) }
                    if !extras.isEmpty {
                        let desc = extras.map { "\($0)=\(raw[$0] ?? "nil")" }.joined(separator: " | ")
                        Log.debug("Extra fields: \(desc)")
                    }
                }
                do {
                    let event = try JSONDecoder().decode(HookEvent.self, from: body)
                    onEvent(event)
                } catch {
                    print("[CodeBar] Failed to parse hook event: \(error)")
                }
            }
            sendResponse(connection: connection)
            return true
        }

        return false // Need more body data
    }

    private func processBody(from data: Data, connection: NWConnection) {
        let separator = Data([0x0D, 0x0A, 0x0D, 0x0A])
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
        sendResponse(connection: connection)
    }

    private func parseContentLength(from headers: String) -> Int {
        for line in headers.components(separatedBy: "\r\n") {
            let parts = line.split(separator: ":", maxSplits: 1)
            if parts.count == 2,
               parts[0].trimmingCharacters(in: .whitespaces).lowercased() == "content-length" {
                return Int(parts[1].trimmingCharacters(in: .whitespaces)) ?? 0
            }
        }
        return 0
    }

    private func sendResponse(connection: NWConnection) {
        let response = "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n{}"
        connection.send(content: response.data(using: .utf8), completion: .contentProcessed { _ in
            connection.cancel()
        })
    }
}
