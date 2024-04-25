//
//  NetworkListener.swift
//  GStreamerSwiftUIDemo
//
//  Created by Devon Quispe on 4/4/24.
//

import Network

class NetworkListener {
    let listener: NWListener
    var cameraViewController: CameraViewController?
    
    init?(cameraViewController: CameraViewController) {
        self.cameraViewController = cameraViewController
        do {
            listener = try NWListener(using: .tcp, on: 8080)
        } catch {
            print("Failed to create a listener: \(error)")
            return nil
        }
    }
    
    func start() {
        listener.newConnectionHandler = { newConnection in
            self.handleConnection(newConnection)
        }
        
        listener.start(queue: .global())
        print("Listener started on port 8080")
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .global())
        connection.receive(minimumIncompleteLength: 1, maximumLength: 10) { (data, _, isComplete, error) in
            guard let data = data, !data.isEmpty, error == nil else {
                print("Error in receiving data or connection closed")
                return
            }
            
            if let commandString = String(data: data, encoding: .utf8) {
                switch commandString {
                case "Up":
                    self.cameraViewController?.indexUp()
                case "Down":
                    self.cameraViewController?.indexDown()
                default:
                    print("Unknown command")
                }
            }
            
            if isComplete {
                connection.cancel()
            } else {
                // Continue receiving if not complete
                self.handleConnection(connection)
            }
        }
    }
}

