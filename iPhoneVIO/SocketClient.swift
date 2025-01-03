import SocketIO
import simd
import Combine

class DataPacket: Codable {
    var transformMatrix: simd_float4x4
    var timestamp: Double
    var buttonStates: [String: Bool]

    init(transformMatrix: simd_float4x4, timestamp: Double, buttonStates: [String: Bool]) {
        self.transformMatrix = transformMatrix
        self.timestamp = timestamp
        self.buttonStates = buttonStates
    }

    // Encode the DataPacket into JSON
    func toJSON() -> Data? {
        let encoder = JSONEncoder()

        // Optionally, you can format the output to be human-readable
        encoder.outputFormatting = .prettyPrinted

        do {
            // Convert to JSON data
            let jsonData = try encoder.encode(self)
            return jsonData
        } catch {
            print("Error encoding DataPacket to JSON: \(error)")
            return nil
        }
    }

    // Helper function to print the JSON as a string
    func toJSONString() -> String? {
        if let jsonData = toJSON() {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }

    // Custom encoding for simd_float4x4
    enum CodingKeys: String, CodingKey {
        case transformMatrix
        case timestamp
        case buttonStates
    }
}

extension simd_float4x4: Codable {
    // Encode the simd_float4x4 matrix as a 4x4 array of floats
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        // Iterate through rows and columns, adding each row as an array of floats
        for row in 0..<4 {
            var rowArray: [Float] = []
            for col in 0..<4 {
                rowArray.append(self[col][row])
            }
            try container.encode(rowArray)  // Encode the row as an array
        }
    }

    // Decode the simd_float4x4 matrix from a 4x4 array of floats
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var matrix = simd_float4x4()

        // Decode the matrix row by row
        for row in 0..<4 {
            let rowArray = try container.decode([Float].self)  // Decode each row as an array of floats
            for col in 0..<4 {
                matrix[col][row] = rowArray[col]  // Assign each value to the matrix
            }
        }
        self = matrix
    }
}

enum SocketCommand: String {
    case startHaptics = "start_haptics"
    case stopHaptics = "stop_haptics"
    case unknown
}

class SocketClient{
    private var manager: SocketManager?
    private var socket: SocketIOClient?
    
    var ready: Bool = false
    var socketOpened: Bool
    var prevTimestamp: Double = 0
    
    let commandStream = PassthroughSubject<SocketCommand, Never>()
    
    init(){
        socketOpened = false
    }

    func connect(hostIP: String, hostPort: Int) {
        self.ready = false
        print("Connecting to \(hostIP):\(hostPort)")
        self.manager = SocketManager(socketURL: URL(string: "http://\(hostIP):\(hostPort)")!, config: [.log(true), .compress])
        usleep(100000)
        self.socket = self.manager?.defaultSocket
        addListeners()
        self.socket?.connect()
        
        // Check if connection is established
        socket?.on(clientEvent: .connect) {data, ack in
            print("Socket connected")
        }
        socket?.on(clientEvent: .disconnect) {data, ack in
            print("Socket disconnected")
        }
        
        
        usleep(100000)
        self.ready = true
    }

    func sendData(_ data: DataPacket) {
        if !ready {
            print("Not ready to send")
            return
        }
//        print("Start sending package, freq: \(1/(data.timestamp - prevTimestamp))Hz")
        prevTimestamp = data.timestamp
        self.ready = false
        self.socket?.emit("update", data.toJSONString() ?? "")
        self.ready = true
    }

    func disconnect() {
        self.ready = false
        socket?.disconnect()
        usleep(100000)
        self.socketOpened = false
    }
    
    private func handleCommand(message: String) {
        let command = SocketCommand(rawValue: message.lowercased()) ?? .unknown
        print("Received command: \(command.rawValue)")
        commandStream.send(command)
    }
    
    private func addListeners() {
        socket?.on(clientEvent: .connect) { data, ack in
            print("Socket connected")
            self.ready = true  // Mark the socket as ready
        }

        socket?.on(clientEvent: .error) { data, ack in
            print("Socket connection error: \(data)")
        }

        socket?.on(clientEvent: .disconnect) { data, ack in
            print("Socket disconnected")
        }
        
        // Handle "command" event from server
        socket?.on("command") { [weak self] data, _ in
            print("Received 'command' event")
            guard let self = self else { return }
            if let message = data.first as? String {
                self.handleCommand(message: message)
            }
        }
    }
}
