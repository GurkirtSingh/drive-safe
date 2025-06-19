//
//  Utils.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-18.
//

import Foundation

func parseTroubleCodes(_ processedResponse: [String]) -> [String] {
    let bytes = Array(processedResponse.dropFirst()) // drop the mode byte "47"
    var codes: [String] = []

    // Each DTC is 2 bytes = 4 hex characters
    for i in stride(from: 0, to: bytes.count, by: 2) {
        guard i + 1 < bytes.count else { break }

        let hex = bytes[i] + bytes[i + 1] // combine 2 bytes like "04" + "20" = "0420"

        if let code = parseSingleDTC(from: hex), code != "P0000" {
            codes.append(code)
        }
    }

    return codes
}

func parseSingleDTC(from hex: String) -> String? {
    guard hex.count == 4,
          let firstByte = Int(hex.prefix(2), radix: 16),
          let secondByte = Int(hex.suffix(2), radix: 16) else {
        return nil
    }

    let type = ["P", "C", "B", "U"][(firstByte & 0xC0) >> 6]
    let firstDigit = (firstByte & 0x30) >> 4
    let secondDigit = firstByte & 0x0F
    let thirdDigit = (secondByte & 0xF0) >> 4
    let fourthDigit = secondByte & 0x0F

    return "\(type)\(firstDigit)\(String(format: "%X%X%X", secondDigit, thirdDigit, fourthDigit))"
}
