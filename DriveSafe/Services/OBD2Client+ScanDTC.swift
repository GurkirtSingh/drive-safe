//
//  OBD2Client+ScanDTC.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-17.
//

import Foundation

extension OBD2Client {
    
    func scanDTC() async{
        do {
            let response = try await send(command: OBD2Constants.DiagnosticCommands.requestPendingDTCs)
            guard response.isEmpty else {
                print("Response is Empty")
                return
            }
            diagonistTroubleCodes = parseTroubleCodes(response)
            print("Codes: \(diagonistTroubleCodes)")
            
        } catch {
            print("error: \(error)")
        }
    }
    private func parseTroubleCodes(_ response: String) -> [String]{
        // Remove spaces and drop the first 2 characters (mode and count)
        let cleanResponse = response
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .replacingOccurrences(of: OBD2Constants.Response.promptCharacter.description, with: "")
            .replacingOccurrences(of: " ", with: "")
            .uppercased()
        let bytes = Array(cleanResponse.dropFirst(2)) // drop the mode byte

        var codes: [String] = []
        
        // Each DTC is 2 bytes = 4 hex characters
        for i in stride(from: 0, to: bytes.count, by: 4) {
            guard i + 3 < bytes.count else { break }
            
            // Form a 4-character hex string representing 2 bytes
            let hex = String(bytes[i...i+3])
            
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
