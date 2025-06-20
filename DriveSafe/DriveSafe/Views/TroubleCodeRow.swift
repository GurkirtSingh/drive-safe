//
//  TroubleCodeRow.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-18.
//

import SwiftUI

struct TroubleCodeRow: View {
    var troubleCode: TroubleCode
    var body: some View {
        HStack{
            VStack(alignment: .leading){
                Text(troubleCode.code)
                    .font(.headline)
                Text(troubleCode.description)
                    .font(.subheadline)
                    .lineLimit(1)
            }
            
            Spacer()
            
            switch troubleCode.status {
            case .pending:
                Label("Pending", systemImage: "clock.arrow.circlepath")
                    .foregroundColor(.gray)
            case .confirmed:
                Label("Confirmed", systemImage: "checkmark.seal")
                    .foregroundColor(.orange)
            case .permanent:
                Label("Permanent", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
        }
    }
}

#Preview {
    Group{
        TroubleCodeRow(troubleCode: TroubleCode(code: "P0420", status: .pending))
        TroubleCodeRow(troubleCode: TroubleCode(code: "P0420", status: .confirmed))
        TroubleCodeRow(troubleCode: TroubleCode(code: "P0420", status: .permanent))
    }
}
