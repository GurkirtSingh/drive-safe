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
    @Published var diagonistTroubleCodes = []
    
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
                Task { @MainActor in
                    self.disconnect()
                }
            case .waiting(let error):
                print( "waiting: \(error.localizedDescription)")
                Task { @MainActor in
                    self.disconnect()
                }
            default:
                print("Unknown state: \(state)")
            }
        }
        connection?.start(queue: .main)
    }
    
    func disconnect(){
        connection?.cancel()
        connection = nil
        isConnected = false
        responseBuffer = Data()
        print("disconnected from OBD2")
    }
    
    func send(command: String) async throws -> String {
        guard let connection = connection else {
            throw NSError(domain: "OBD2Client", code: -1, userInfo: [NSLocalizedDescriptionKey: "No connection"])
        }
        
        let cmd = command + "\r"
        let data = cmd.data(using: .utf8)!
        
        return try await withCheckedThrowingContinuation{ continuation in
            connection.send(content: data, completion: .contentProcessed { sendError in
                if let sendError = sendError {
                    Task { @MainActor in
                        self.disconnect()
                    }
                    continuation.resume(throwing: sendError)
                    return
                }
                Task { @MainActor in
                    // After sending, start reading response
                    self.readResponseForContinuation(continuation)
                }
            })
        }
    }
    
    private func readResponseForContinuation(_ continuation: CheckedContinuation<String, Error>) {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, isComplete, error in
            if let error = error {
                continuation.resume(throwing: error)
                return
            }
            
            if let data = data {
                Task { @MainActor in
                    self.responseBuffer.append(data)
                    
                    if let fullString = String(data: self.responseBuffer, encoding: .utf8),
                       fullString.contains(OBD2Constants.Response.promptCharacter) {
                        // Got full response, clear buffer and resume continuation
                        self.responseBuffer = Data()
                        continuation.resume(returning: fullString)
                        return
                    }
                }
            }
            
            if !isComplete {
                Task { @MainActor in
                    // Keep reading until full response received
                    self.readResponseForContinuation(continuation)
                }
            }
        }
    }
    
    func parseResponse(_ response: String) async throws -> String{
        print("Raw Response: \(response)")
        
        let cleaned = response
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: OBD2Constants.Response.promptCharacter.description, with: "")
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
        
        guard cleaned.count >= 4 else{
            throw NSError(domain: "OBD2Client", code: -1, userInfo: [NSLocalizedDescriptionKey: "Response too short"])
        }
        
        let mode = String(cleaned.prefix(2))
        let pidOrData = String(cleaned.dropFirst(2))
        
        switch mode {
        case "41": // Mode 01 response (Live data)
            let pid = String(pidOrData.prefix(2))
            let data = String(pidOrData.dropFirst(2))
            
            switch pid {
            case OBD2Constants.PID.rpm:
                if data.count >= 4, let A = UInt8(data.prefix(2), radix: 16), let B = UInt8(data.dropFirst(2).prefix(2), radix: 16) {
                    let rpm = (256 * Int(A) + Int(B)) / 4
                    print("RPM: \(rpm)")
                }
                
            case OBD2Constants.PID.speed:
                if data.count >= 2, let speed = UInt8(data.prefix(2), radix: 16) {
                    print("Speed: \(speed) km/h")
                }
                
            case OBD2Constants.PID.coolantTemp:
                if data.count >= 2, let temp = UInt8(data.prefix(2), radix: 16) {
                    let coolant = Int(temp) - 40
                    print("Coolant Temp: \(coolant)°C")
                }
                
            default:
                print("Unhandled PID: \(pid), data: \(data)")
            }
            
        case "43": // Mode 03 response: Confirmed DTCs
            return pidOrData
        case "47": // Mode 07 response: Pending DTCs
            return pidOrData
        case "4A": // Mode 0A response: Permanent DTCs
            return pidOrData
        case "44": // Mode 04 response: Clear DTCs
            return "Trouble codes cleared successfully."
        default:
            throw NSError(domain: "OBD2Client", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unknown mode response: \(cleaned)"])
        }
        return ""
    }
    
}

