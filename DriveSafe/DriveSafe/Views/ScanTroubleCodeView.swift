//
//  ScanTroubleCodeView.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-16.
//

import SwiftUI

struct ScanTroubleCodeView: View {
    
    @State private var isConnected = false
    var body: some View {
        if isConnected {
            Text("Connected")
                .padding()
                .foregroundStyle(Color.white)
                .background(Color.accentColor)
                .clipShape(Capsule())
        }else {
            ConnectOBD2View()
        }
    }
}

#Preview {
    ScanTroubleCodeView()
}
