import SwiftUI
import RealityKit
import UIKit

struct ContentView : View {
    @StateObject var viewController: ViewController = ViewController()
    @State private var newHostIP: String = UserDefaults.standard.string(forKey: "HostIP") ?? "192.168.3.33"
    @State private var newHostPort: String = UserDefaults.standard.string(forKey: "HostPort") ?? "5555"
    @State private var buttonName1: String = UserDefaults.standard.string(forKey: "ButtonName1") ?? "Reset"
    @State private var buttonName2: String = UserDefaults.standard.string(forKey: "ButtonName2") ?? "Close"
    @State private var isEditing: Bool = false

    var body: some View {
        if isEditing {
            EditView(hostIP: $newHostIP, hostPort: $newHostPort, buttonName1: $buttonName1, buttonName2: $buttonName2, isEditing: $isEditing)
        } else {
            ARViewContainer(viewController: self.viewController)
                .edgesIgnoringSafeArea(.all).overlay(){
                    VStack{
                        Text(viewController.displayString)
                            .font(.system(size: 15).monospaced())
                            .foregroundColor(.white)
                            .padding(5)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(8)

                        HStack {
                            Text("Host: ")
                                .font(.system(size: 20).monospaced().italic().bold())
                                
                            Text("\(newHostIP):\(newHostPort)")
                                .font(.system(size: 20).monospaced())
                                .foregroundColor(.white)
                                .padding(5)
                                .background(Color.black.opacity(0.5))
                                .cornerRadius(8)

                        }
                        
                        
                        Button(action: {isEditing = true}) {
                            Text("Edit")
                                .font(.system(size: 25)) // Increased font size for better visibility
                                .frame(width: 150, height: 50) // Defined a larger tappable area
                                .padding()
                                .background(Color.gray.opacity(0.5))
                                .cornerRadius(10)
                                .foregroundColor(.white)
                        }
                        
                        Spacer().frame(height: 50)
                        
                        VStack(spacing: 30) {
                            Button{
                                ARManager.shared.actionStream.send(.update(ip: newHostIP, port: Int(newHostPort)!))
                                } label: {
                                    Image(systemName: "arrow.clockwise")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .padding()
                                        .background(.regularMaterial)
                                        .cornerRadius(16)
                                }
                            
                            Button(action: {}) {
                                Text(buttonName1)
                                    .font(.system(size: 25))
                                    .padding()
                                    .frame(width: 250, height: 100)
                                    .background(viewController.buttonStates[buttonName1] ?? false ? Color.green : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            }
                            .simultaneousGesture(DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    viewController.buttonStates[buttonName1] = true
                                }
                                .onEnded { _ in
                                    viewController.buttonStates[buttonName1] = false
                                }
                            )

                            Button(action: {}) {
                                Text(buttonName2)
                                    .font(.system(size: 25))
                                    .padding()
                                    .frame(width: 250, height: 100)
                                    .background(viewController.buttonStates[buttonName2] ?? false ? Color.green : Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(16)
                            }
                            .simultaneousGesture(DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    viewController.buttonStates[buttonName2] = true
                                }
                                .onEnded { _ in
                                    viewController.buttonStates[buttonName2] = false
                                }
                            )
                        }
                    }.padding()
                }
        }
    }
}

struct EditView: View {
    @Binding var hostIP: String
    @Binding var hostPort: String
    @Binding var buttonName1: String
    @Binding var buttonName2: String
    @Binding var isEditing: Bool

    var body: some View {
        VStack(spacing: 20) {
            Text("Edit Settings")
                .font(.title)
            
            Spacer().frame(height: 30)
            
            HStack {
                Text("Host IP:")
                    .font(.body)
                    .frame(width:120)
                TextField("Host IP", text: $hostIP)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
                    .onSubmit {
                        // Save the updated hostIP to UserDefaults
                        UserDefaults.standard.set(hostIP, forKey: "HostIP")
                    }
            }

            HStack {
                Text("Host Port:")
                    .font(.body)
                    .frame(width:120)
                TextField("Host Port", text: $hostPort)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
                    .onSubmit {
                        // Save the updated hostPort to UserDefaults
                        UserDefaults.standard.set(hostPort, forKey: "HostPort")
                    }
            }

            HStack {
                Text("Button 1 Name:")
                    .font(.body)
                    .frame(width:120)
                TextField("Button 1 Name", text: $buttonName1)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
                    .onSubmit {
                        // Save the updated buttonName1 to UserDefaults
                        UserDefaults.standard.set(buttonName1, forKey: "ButtonName1")
                    }
            }

            
            HStack {
                Text("Button 2 Name:")
                    .font(.body)
                    .frame(width:120)
                TextField("Button 2 Name", text: $buttonName2)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .background(Color.black.opacity(0.1))
                    .cornerRadius(10)
                    .onSubmit {
                        // Save the updated buttonName2 to UserDefaults
                        UserDefaults.standard.set(buttonName2, forKey: "ButtonName2")
                    }
            }
            
            Spacer().frame(height: 30)
            Button("Save") {isEditing = false
            }
                .font(.system(size: 20))
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .foregroundColor(.white)
        }
        .padding()
    }
}

struct ARViewContainer: UIViewControllerRepresentable {
    
    @ObservedObject var viewController: ViewController
    
    func makeUIViewController(context: Context) -> ViewController {
        return self.viewController
    }

    func updateUIViewController(_ uiViewController: ViewController, context: Context) {
    }
}

#Preview {
    ContentView()
}
