//
//  ScanTroubleCodeView.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-16.
//

import SwiftUI

struct ScanTroubleCodeView: View {
    
    @StateObject private var obdManager: OBD2Client = OBD2Client.shared
    @State private var diagonistTroubleCodes: [String] = []
    
    @State private var isAlertPresented: Bool = false
    @State private var alertMessage: String = ""
    
    var body: some View {
        if obdManager.isConnected {
            VStack{
                if !diagonistTroubleCodes.isEmpty{
                    ScrollView{
                        ForEach(diagonistTroubleCodes, id: \.self){ code in
                            Text(code)
                                .padding()
                                .clipShape(.rect)
                        }
                    }
                }
                Button{
                    Task{
                        do{
                            if let result = try await obdManager.scanDTC(){
                                withAnimation{
                                    diagonistTroubleCodes = result
                                }
                            } else{
                                isAlertPresented = true
                                alertMessage = ErrorMessage.noDTCsFound
                            }
                        } catch{
                            isAlertPresented = true
                            alertMessage = error.localizedDescription
                        }
                        
                        
                    }
                    
                } label: {
                    Text("Scan Codes")
                        .padding()
                        .foregroundStyle(Color.white)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
            }
            .padding(.bottom, 50)
            .alert(isPresented: $isAlertPresented){
                Alert(
                    title: Text("Warning") ,
                    message: Text(alertMessage),
                    dismissButton: .default(Text("Ok"))
                )
            }
        }else {
            ConnectOBD2View()
        }
    }
}

#Preview {
    ScanTroubleCodeView()
}
