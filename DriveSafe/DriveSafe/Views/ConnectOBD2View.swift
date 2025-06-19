//
//  ConnectOBD2View.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-17.
//

import SwiftUI

struct ConnectOBD2View: View {
    
    @State private var isConnecting: Bool = false
    @State private var isAlertPresented: Bool = false
    @State private var alertMessage: String = ""
    
    @StateObject private var obdManager: OBD2Client = OBD2Client.shared
    
    var body: some View {
        if !obdManager.isConnected{
            if isConnecting{
                ProgressView("Connecting...")
            } else{
                VStack {
                    Button{
                        // Implement OB2 connection logic
                        print("Connecting OBD2")
                        isConnecting = true
                        Task{
                            do{
                                try await obdManager.connect()
                            } catch{
                                isAlertPresented = true
                                alertMessage = error.localizedDescription
                                isConnecting = false
                            }
                        }
                    } label: {
                        Text("Connect OBD2")
                            .padding()
                            .foregroundStyle(Color.white)
                            .background(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }.alert(isPresented: $isAlertPresented) {
                    Alert(
                        title: Text("Warning"),
                        message: Text(alertMessage),
                        dismissButton: .default(Text("Ok")))
                }
            }
            
        } else{
            Text("OBD2 is Connected!")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ConnectOBD2View()
}
