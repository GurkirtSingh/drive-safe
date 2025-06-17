//
//  ConnectOBD2View.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-17.
//

import SwiftUI

struct ConnectOBD2View: View {
    @State var isConnected: Bool = false
    var body: some View {
        if !isConnected {
            Button{
                // Implement OB2 connection logic
                print("Connecting OBD2")
                
            }label: {
                Text("Connect OBD2")
                    .padding()
                    .foregroundStyle(Color.white)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
        }
    }
}

#Preview {
    ConnectOBD2View()
}
