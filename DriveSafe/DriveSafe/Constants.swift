//
//  Constants.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-17.
//

/// A namespace for all constants used in the OBD2Client.
struct OBD2Constants {
    
    /// Constants related to the ELM327 socket connection.
    enum Connection {
        static let hostName = "192.168.0.10"
        static let port = 35000
    }
    
    /// AT commands used for ELM327 initialization and configuration.
    enum ATCommands {
        static let reset = "ATZ"                 // Reset all
        static let echoOff = "ATE0"              // Echo off
        static let lineFeedOff = "ATL0"          // Line feed off
        static let spacesOff = "ATS0"            // Spaces off
        static let headersOff = "ATH0"           // Headers off
        static let selectProtocolAuto = "ATSP0"  // Auto protocol select
    }
    
    /// Diagnostic commands defined by the OBD-II protocol.
    enum DiagnosticCommands {
        static let requestDTCs = "03"
        static let requestPendingDTCs = "07"
        static let requestPermanentDTCs = "0A"
        static let clearDTCs = "04"
        static let currentDataPrefix = "01"
    }
    
    /// Common OBD-II Parameter IDs (PIDs).
    enum PID {
        static let rpm = "0C"
        static let speed = "0D"
        static let coolantTemp = "05"
    }
    
    /// Expected response patterns from the ELM327 adapter.
    enum Response {
        static let promptCharacter: Character = ">"
        static let success = "OK"
        static let noData = "NO DATA"
        static let unknownCommand = "?"
        static let error = "ERROR"
        static let busy = "BUSY"
        static let timeout = "TIMEOUT"
        static let searching = "SEARCHING..."
    }
}

