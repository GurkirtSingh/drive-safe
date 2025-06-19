//
//  OBD2Client+ScanDTC.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-17.
//

import Foundation

extension OBD2Client {
    
    func scanDTC() async throws -> [String]? {
        do {
            if let response = try await sendCommand(command: OBD2Constants.DiagnosticCommands.requestDTCs){
                return parseTroubleCodes(response)
            }else{ return nil }
            
        }
    }
}
