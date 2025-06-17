//
//  OBD2Client.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-17.
//

import Foundation
import Network
internal import Combine

/// `OBD2Client` is responsible for managing communication with an OBD-II adapter over Wi-Fi
///
/// It provides methods to connect to the adapter (via Wi-Fi),
/// send OBD-II commands, and receive responses from the vehicle's ECU.
///
/// Typical use cases include reading Diagnostic Trouble Codes (DTCs),
/// clearing codes, and accessing live sensor data such as RPM, speed, and oxygen levels.
///
/// Make sure to connect the client before sending commands.
class OBD2Client: ObservableObject{
    
    @Published var isConnected:Bool = false
    
    private var connection: NWConnection?
    private let host = NWEndpoint.Host(OBD2Constants.Connection.hostName) // Replace with actual IP
    private let port = NWEndpoint.Port(integerLiteral: UInt16(OBD2Constants.Connection.port))
    
    private var responseBuffer = Data()
    
    func connect() {
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        
        connection?.stateUpdateHandler = { state in
            switch state {
            case .preparing:
                print( "preparing")
            case .ready:
                print("Connected to OBD2 adapter")
                Task { @MainActor in
                    self.isConnected = true
                }
            case .failed(let error):
                print("Connection failed: \(error)")
            case .waiting(let error):
                print( "waiting: \(error.localizedDescription)")
            default:
                print("Unknown state: \(state)")
            }
        }
        connection?.start(queue: .main)
    }
    
    func send(command: String){
        guard let connection = connection else { return }
        let cmd = command + "\r"
        let data = cmd.data(using: .utf8)!
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Send error: \(error)")
                Task { @MainActor in
                    self.isConnected = false
                }
            } else {
                Task { @MainActor in
                    self.readResponse()
                }
            }
        })
    }
    func readResponse() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, error in
            if let error = error {
                print("Receive error: \(error.localizedDescription)")
                return
            }
            
            // TODO: - Optimize by handling data async
            if let data = data {
                Task { @MainActor in
                    self.responseBuffer.append(data)
                    
                    if let fullString = String(data: self.responseBuffer, encoding: .utf8),
                       fullString.contains(OBD2Constants.Response.promptCharacter) {
                        
                        // Full response received
                        self.parseResponse(fullString)
                        
                        // Clear buffer after parsing
                        self.responseBuffer = Data()
                    }
                }
            }
            
            if !isComplete {
                Task { @MainActor in
                    // Keep reading
                    self.readResponse()
                }
            }
        }
    }
    func parseResponse(_ response: String){
        let cleaned = response
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("Response: \(cleaned)")
    }
}

