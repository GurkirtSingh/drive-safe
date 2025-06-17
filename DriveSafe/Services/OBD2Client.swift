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
        print("Raw Response: \(response)")
        
        let cleaned = response
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: OBD2Constants.Response.promptCharacter.description, with: "")
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
        
        guard cleaned.count >= 4 else{
            print("Response too short")
            return
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
               let codes = decodeDTCs(from: pidOrData)
               print("Confirmed Trouble Codes: \(codes)")

           case "47": // Mode 07 response: Pending DTCs
               let codes = decodeDTCs(from: pidOrData)
               print("Pending Trouble Codes: \(codes)")

           case "4A": // Mode 0A response: Permanent DTCs
               let codes = decodeDTCs(from: pidOrData)
               print("Permanent Trouble Codes: \(codes)")

           case "44": // Mode 04 response: Clear DTCs
               print("Trouble codes cleared successfully.")

           default:
               print("Unknown mode response: \(cleaned)")
           }
        
    }
    
    private func decodeDTCs(from hexString: String) -> [String] {
        guard hexString.count >= 4 else { return [] }

        var dtcs: [String] = []
        let chars = Array(hexString)
        
        for i in stride(from: 0, to: chars.count, by: 4) {
            guard i + 3 < chars.count else { break }

            let A = chars[i]
            let B = chars[i + 1]
            let C = chars[i + 2]
            let D = chars[i + 3]

            let type: String
            switch A {
            case "0"..."3": type = "P0"
            case "4"..."7": type = "C0"
            case "8"..."B": type = "B0"
            case "C"..."F": type = "U0"
            default: type = "P0"
            }

            let code = "\(type)\(B)\(C)\(D)"
            if code != "P0000" { // ignore padding
                dtcs.append(code)
            }
        }

        return dtcs
    }

}

