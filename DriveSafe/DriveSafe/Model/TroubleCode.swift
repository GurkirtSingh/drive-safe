//
//  TroubleCode.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-18.
//

import Foundation
import SwiftUI

enum TroubleCodeType: String {
    case pending
    case confirmed
    case permanent
}

struct TroubleCode: Identifiable, Hashable{
    var id: String { code }
    var code: String
    var status: TroubleCodeType
    var description: String {
        troubleCodeDescription[code] ?? "Unknown Code"
    }
}

