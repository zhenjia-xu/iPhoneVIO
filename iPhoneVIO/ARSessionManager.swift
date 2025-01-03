import Foundation
import ARKit
import Combine

class ViewController: UIViewController, ARSessionDelegate, ObservableObject {
    @Published var displayString: String = ""
    @Published var buttonStates: [String: Bool] = [:]

    let session = ARSession()
    let socketClient = SocketClient()
    var hostIP: String = "192.168.123.18"
    var hostPort: Int = 5555
    var prevTimestamp: Double = 0.0
    
    private var cancellables: Set<AnyCancellable> = []
    private var publishPose: Bool = false
    
    private var isHapticRunning: Bool = false
    private var hapticGenerator: UIImpactFeedbackGenerator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARSession()
        subscribeToActionStream()
        subscribeToCommandsStream()  // Added subscription to commandsStream
    }
    
    func setupARSession() {
        socketClient.connect(hostIP: hostIP, hostPort: hostPort)
        self.publishPose = true
        session.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        session.run(configuration)
    }

    func subscribeToActionStream() {
        ARManager.shared
            .actionStream
            .sink { [weak self] action in
                switch action {
                    case .update(let ip, let port):
                        self?.publishPose = false
                        self?.socketClient.disconnect()
                        self?.hostIP = ip
                        self?.hostPort = port
                        print("Reconnecting to ZMQ Publisher: \(self!.hostIP):\(self!.hostPort)")
                        self?.socketClient.connect(hostIP: self!.hostIP, hostPort: self!.hostPort)
                        self?.publishPose = true
                        
                        // custimized resetting steps
                        self?.stopHapticFeedback()
                }
            }
            .store(in: &cancellables)
    }

    // Subscribe to the commandsStream from SocketClient
    func subscribeToCommandsStream() {
        socketClient.commandsStream
            .sink { [weak self] commands in
                // Handle the received list of commands (strings)
                for command in commands {
                    self?.handleCommand(command)
                }
            }
            .store(in: &cancellables)
    }
    
    func handleCommand(_ command: String) {
        // Here, you can perform specific actions based on the received command
        // For example, starting or stopping haptic feedback:
        switch command.lowercased() {
        case "start_haptics":
            startHapticFeedback()
        case "stop_haptics":
            stopHapticFeedback()
        default:
            print("error: unknown command")
        }
    }


    // ARSessionDelegate method
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let transform = frame.camera.transform
        let timestamp = frame.timestamp

        displayString = "x: \(String(format: "%.4f", transform[3][0]))\n"
        displayString += "y: \(String(format: "%.4f", transform[3][1]))\n"
        displayString += "z: \(String(format: "%.4f", transform[3][2]))\n"
        displayString += "fps: \(String(format: "%.3f", 1/(timestamp - self.prevTimestamp)))"
        prevTimestamp = timestamp

        if publishPose {
            let dataPacket = DataPacket(
                transformMatrix: transform,
                timestamp: timestamp,
                buttonStates: buttonStates
            )
            socketClient.sendData(dataPacket)
        }
    }
    
    func startHapticFeedback() {
        guard !isHapticRunning else { return }
        isHapticRunning = true
        hapticGenerator = UIImpactFeedbackGenerator(style: .medium)
        hapticGenerator?.prepare()

        DispatchQueue.global().async { [weak self] in
            while self?.isHapticRunning == true {
                DispatchQueue.main.async {
                    self?.hapticGenerator?.impactOccurred()
                }
                usleep(50000) // 50ms delay between vibrations
            }
        }
    }

    func stopHapticFeedback() {
        isHapticRunning = false
        hapticGenerator = nil
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        session.pause()
        stopHapticFeedback()
    }
}
