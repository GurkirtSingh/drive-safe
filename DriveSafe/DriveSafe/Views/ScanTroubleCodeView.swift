//
//  ScanTroubleCodeView.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-16.
//

import SwiftUI

struct ScanTroubleCodeView: View {
    var body: some View {
        Button{
            // Implement OBD2 connection logic
            print("Connecting OBD2")
        } label: {
            Text("Connect OBD2")
                .padding()
                .foregroundStyle(Color.white)
                .background(Color.accentColor)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ScanTroubleCodeView()
}
