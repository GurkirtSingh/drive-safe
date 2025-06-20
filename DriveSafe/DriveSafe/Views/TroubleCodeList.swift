//
//  TroubleCodeList.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-19.
//

import SwiftUI

struct TroubleCodeList: View {
    var troubleCodes: [TroubleCode]
    var body: some View {
        NavigationSplitView {
            List(troubleCodes) { code in
                NavigationLink{
                    TroubleCodeDetail(troubleCode: code)
                } label: {
                    TroubleCodeRow(troubleCode: code)
                }
            }
            .navigationTitle("Trouble Codes")
        } detail: {
            Text("Select a Trouble Code")
        }
    }
}

#Preview {
    TroubleCodeList(troubleCodes: [
        .init(code: "P0420", status: .confirmed),
        .init(code: "P0430", status: .pending),
        .init(code: "P0240", status: .permanent)
    ])
}
