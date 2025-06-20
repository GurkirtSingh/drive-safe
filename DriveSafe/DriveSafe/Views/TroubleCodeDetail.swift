//
//  TroubleCodeDetail.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-19.
//

import SwiftUI

struct TroubleCodeDetail: View {
    var troubleCode: TroubleCode
    var body: some View {
        VStack(alignment: .leading, spacing: 20){
            Text(troubleCode.code)
                .font(.largeTitle)
                .bold()
                .lineLimit(1)
                .padding(.top, 50)
            VStack{
                switch troubleCode.status {
                case .pending:
                    Label("Pending", systemImage: "clock.arrow.circlepath")
                        .foregroundColor(.orange)
                case .confirmed:
                    Label("Confirmed", systemImage: "checkmark.seal")
                        .foregroundColor(.red)
                case .permanent:
                    Label("Permanent", systemImage: "exclamationmark.triangle")
                        .foregroundColor(.gray)
                }
            }
            Divider()
            Text(troubleCode.description)
                .font(.headline)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .navigationTitle("Trouble Code Detail")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    TroubleCodeDetail(troubleCode: .init(code: "P0430", status: .permanent))
}
