//
//  OBD2Client+ScanDTC.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-17.
//

import Foundation

extension OBD2Client {
    
    func scanDTC(_ type: TroubleCodeType) async throws -> [String]? {
        var response: [String]?
        do {
            switch type {
            case .pending:
                response = try await sendCommand(command: OBD2Constants.DiagnosticCommands.requestPendingDTCs)
            case .confirmed:
                response = try await sendCommand(command: OBD2Constants.DiagnosticCommands.requestDTCs)
            case .permanent:
                response = try await sendCommand(command: OBD2Constants.DiagnosticCommands.requestPermanentDTCs)
                
                guard let response = response else {
                    return nil
                }
                return parseTroubleCodes(response)
            }
        }
        return response
    }
}
