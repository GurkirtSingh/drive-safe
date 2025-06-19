//
//  OBD2Client.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-17.
//

import Foundation
import Network
internal import Combine

enum OBD2Error: Error{
    case message(String)
}

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
    
    static let shared = OBD2Client()
    
    @Published var isConnected:Bool = false
    
    private var connection: NWConnection?
    private let host = NWEndpoint.Host(OBD2Constants.Connection.hostName) // Replace with actual IP
    private let port = NWEndpoint.Port(integerLiteral: UInt16(OBD2Constants.Connection.port))
    
    private var responseBuffer = Data()
    
    func connect() async throws {
        
        connection = NWConnection(host: host, port: port, using: .tcp)
        
        try await withCheckedThrowingContinuation{ (continuation: CheckedContinuation<Void, Error>) in
            connection?.stateUpdateHandler = { state in
                switch state {
                    
                case .ready:
                    print("Connected to OBD2 adapter")
                    Task { @MainActor in
                        self.isConnected = true
                        do{
                            await self.setup()
                        }
                    }
                    continuation.resume(returning: ())
                    
                case .failed(let error):
                    print("Connection failed: \(error)")
                    Task { @MainActor in
                        self.disconnect()
                    }
                    
                case .waiting(let error):
                    print( "waiting: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                    
                default:
                    break
                }
            }
            connection?.start(queue: .main)
        }
    }
    
    func setup() async {
        let setupCommands = [
            OBD2Constants.ATCommands.reset,
            OBD2Constants.ATCommands.echoOff,
            OBD2Constants.ATCommands.spacesOff,
            OBD2Constants.ATCommands.headersOff,
            OBD2Constants.ATCommands.selectProtocolAuto,
            OBD2Constants.ATCommands.Protocols.protocol3
        ]
        for cmd in setupCommands{
            do {
                _ = try await sendCommand(command: cmd)
            }catch{
                print("Setup Error: \(error)")
            }
            usleep(100_000)
        }
    }
    
    func disconnect(){
        connection?.cancel()
        connection = nil
        isConnected = false
        responseBuffer = Data()
        print("disconnected from OBD2")
    }
    
    func sendCommand(command: String) async throws -> [String]? {
        guard let data = "\(command)\r".data(using: .ascii) else {
            throw OBD2Error.message("Invalid Command Data")
        }
        do {
            let response = try await sendAndRecieve(data: data)
            return processResponse(response)
        } catch {
            throw error
        }
    }
    
    private func sendAndRecieve(data: Data) async throws -> String {
        guard let connection = connection else {
            throw NSError(domain: "OBD2Client", code: -1, userInfo: [NSLocalizedDescriptionKey: ErrorMessage.noConnection])
        }
        
        return try await withCheckedThrowingContinuation{ continuation in
            connection.send(content: data, completion: .contentProcessed { sendError in
                if let sendError = sendError {
                    print("Error Sending Command")
                    continuation.resume(throwing: sendError)
                    return
                }
                
                // recieve data
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) {data, _, _, error in
                    if let error = error{
                        print("Error Recieving Data")
                        continuation.resume(throwing: error)
                        return
                    }
                    
                    guard let response = data, let responseString = String(data: response, encoding: .utf8) else {
                        print("Invalid Data")
                        continuation.resume(throwing: "Invaid Data" as! Error)
                        return
                    }
                    continuation.resume(returning: responseString)
                }
            })
        }
    }
    
    private func processResponse(_ response: String) -> [String]? {
        print("Raw Response: \(response)")
        
        var lines = response.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        guard !lines.isEmpty else {
            print("Empty response lines")
            return nil
        }
        
        if lines.last?.contains(">") == true {
            lines.removeLast()
        }
        
        if lines.first?.lowercased() == "no data" {
            return nil
        }
        
        return lines
        
    }
    
}

