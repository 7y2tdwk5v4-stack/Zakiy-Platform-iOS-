import Foundation

/// A minimal Socket.IO v4 (Engine.IO protocol v4) client built directly on
/// `URLSessionWebSocketTask`, with no third-party dependency. It talks to
/// the same Flask-SocketIO server as `app.py` — the group-room and live-class
/// real-time features (join_room, leaderboard_update, chat_message, board
/// strokes, etc.) all flow through this.
///
/// Only the pieces app.py actually uses are implemented: the WebSocket
/// transport (no long-polling fallback), the default `/` namespace, JSON
/// event payloads, and client-driven ping/pong heartbeats (Engine.IO v4
/// makes the client responsible for sending pings).
@MainActor
final class ZakiySocket: NSObject {
    enum ConnectionState {
        case disconnected
        case connecting
        case connected
    }

    private(set) var state: ConnectionState = .disconnected
    /// Marked `@MainActor` so it can be called as a plain synchronous
    /// function from other MainActor code (this class is `@MainActor`)
    /// without ever needing to send a non-`Sendable` `[String: Any]`
    /// payload across an isolation boundary.
    var onStateChange: (@MainActor (ConnectionState) -> Void)?

    private var task: URLSessionWebSocketTask?
    private var listeners: [String: [@MainActor ([String: Any]) -> Void]] = [:]
    private var pingIntervalMs: Int = 25000
    private var heartbeatTask: Task<Void, Never>?
    private var receiveTask: Task<Void, Never>?

    func on(_ event: String, handler: @escaping @MainActor ([String: Any]) -> Void) {
        listeners[event, default: []].append(handler)
    }

    func connect() {
        guard task == nil else { return }
        state = .connecting
        onStateChange?(state)

        var components = URLComponents(url: AppConfig.apiBaseURL, resolvingAgainstBaseURL: false)!
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        components.path = "/socket.io/"
        components.queryItems = [
            URLQueryItem(name: "EIO", value: "4"),
            URLQueryItem(name: "transport", value: "websocket"),
        ]

        let session = URLSession(configuration: .default)
        let socketTask = session.webSocketTask(with: components.url!)
        task = socketTask
        socketTask.resume()
        listenLoop()
    }

    func disconnect() {
        heartbeatTask?.cancel()
        receiveTask?.cancel()
        task?.cancel(with: .goingAway, reason: nil)
        task = nil
        state = .disconnected
        onStateChange?(state)
    }

    func emit(_ event: String, _ data: [String: Any] = [:]) {
        guard state == .connected else { return }
        send(packet: "42" + jsonArrayString([event, data]))
    }

    // MARK: - Wire protocol

    private func listenLoop() {
        receiveTask = Task { [weak self] in
            guard let self, let task = self.task else { return }
            while !Task.isCancelled {
                do {
                    let message = try await task.receive()
                    switch message {
                    case .string(let text):
                        self.handleIncoming(text)
                    case .data(let data):
                        self.handleIncoming(String(decoding: data, as: UTF8.self))
                    @unknown default:
                        break
                    }
                } catch {
                    self.state = .disconnected
                    self.onStateChange?(self.state)
                    self.task = nil
                    self.heartbeatTask?.cancel()
                    break
                }
            }
        }
    }

    private func handleIncoming(_ text: String) {
        guard let first = text.first else { return }
        let rest = String(text.dropFirst())

        switch first {
        case "0": // Engine.IO open
            if let data = rest.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let interval = json["pingInterval"] as? Int {
                pingIntervalMs = interval
            }
            send(packet: "40") // Socket.IO connect to default namespace
        case "2": // server ping (defensive — EIO4 servers don't normally send this)
            send(packet: "3")
        case "4": // Socket.IO payload
            handleSocketIOPacket(rest)
        default:
            break
        }
    }

    private func handleSocketIOPacket(_ payload: String) {
        guard let kind = payload.first else { return }
        let body = String(payload.dropFirst())

        switch kind {
        case "0": // CONNECT ack
            state = .connected
            onStateChange?(state)
            startHeartbeat()
        case "1": // DISCONNECT
            state = .disconnected
            onStateChange?(state)
        case "2": // EVENT
            guard let data = body.data(using: .utf8),
                  let array = try? JSONSerialization.jsonObject(with: data) as? [Any],
                  let eventName = array.first as? String else { return }
            let payloadDict = (array.count > 1 ? array[1] as? [String: Any] : nil) ?? [:]
            for handler in listeners[eventName] ?? [] {
                handler(payloadDict)
            }
        case "4": // CONNECT_ERROR
            state = .disconnected
            onStateChange?(state)
        default:
            break
        }
    }

    private func startHeartbeat() {
        heartbeatTask?.cancel()
        heartbeatTask = Task { [weak self] in
            guard let self else { return }
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: UInt64(self.pingIntervalMs) * 1_000_000)
                if Task.isCancelled { break }
                self.send(packet: "2")
            }
        }
    }

    private func send(packet: String) {
        task?.send(.string(packet)) { _ in }
    }

    private func jsonArrayString(_ array: [Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: array),
              let string = String(data: data, encoding: .utf8) else { return "[]" }
        return string
    }
}
