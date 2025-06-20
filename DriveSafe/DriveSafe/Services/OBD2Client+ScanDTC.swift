//
//  OBD2Client+ScanDTC.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-17.
//

import Foundation

extension OBD2Client {
    
    func scanDTC(_ type: TroubleCodeType) async throws -> [String]? {
        var rawResponse: [String]?
        switch type {
        case .pending:
            rawResponse = try await sendCommand(command: OBD2Constants.DiagnosticCommands.requestPendingDTCs)
        case .confirmed:
            rawResponse = try await sendCommand(command: OBD2Constants.DiagnosticCommands.requestDTCs)
        case .permanent:
            rawResponse = try await sendCommand(command: OBD2Constants.DiagnosticCommands.requestPermanentDTCs)  
        }
        guard let response = rawResponse else {
            return nil
        }
        return parseTroubleCodes(response)
    }
}
