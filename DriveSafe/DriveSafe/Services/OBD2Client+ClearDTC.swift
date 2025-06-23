//
//  OBD2Client+ClearDTC.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-21.
//

extension OBD2Client {
    
    func clearDTC() async throws -> Bool{
        guard let response = try await sendCommand(command: OBD2Constants.DiagnosticCommands.clearDTCs) else {
            return false
        }
        return response.contains("44")
    }
}
