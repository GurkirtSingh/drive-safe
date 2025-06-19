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
    private func parseTroubleCodes(_ processedResponse: [String]) -> [String]{
        let bytes = Array(processedResponse.dropFirst(2)) // drop the mode byte

        var codes: [String] = []
        
        // Each DTC is 2 bytes = 4 hex characters
        for i in stride(from: 0, to: bytes.count, by: 4) {
            guard i + 3 < bytes.count else { break }
            
            // Form a 4-character hex string representing 2 bytes
            let hex = bytes[i...i+3].joined()
            
            if let code = parseSingleDTC(from: hex), code != "P0000" {
                codes.append(code)
            }
        }
        
        return codes
    }

    private func parseSingleDTC(from hex: String) -> String? {
        guard hex.count == 4 else { return nil }
        let firstByte = Int(hex.prefix(2), radix: 16)!
        let secondByte = Int(hex.suffix(2), radix: 16)!
        
        let type = ["P", "C", "B", "U"][(firstByte & 0xC0) >> 6]
        let firstDigit = (firstByte & 0x30) >> 4
        let secondDigit = firstByte & 0x0F
        let thirdDigit = (secondByte & 0xF0) >> 4
        let fourthDigit = secondByte & 0x0F

        return String(format: "%@%01X%01X%01X%01X", type, firstDigit, secondDigit, thirdDigit, fourthDigit)
    }
}
