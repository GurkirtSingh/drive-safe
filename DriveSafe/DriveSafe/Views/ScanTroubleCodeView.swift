//
//  ScanTroubleCodeView.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-16.
//

import SwiftUI

struct ScanTroubleCodeView: View {
    
    @StateObject private var troubleCodeManager: TroubleCodeManager = TroubleCodeManager(obd2Client: OBD2Client.shared)
    
    @State private var isAlertPresented: Bool = false
    @State private var showClearCodesConfirmation: Bool = false
    
    var body: some View {
        if troubleCodeManager.isOBD2Connected {
            VStack{
                if !troubleCodeManager.troubleCodeList.isEmpty{
                    ScrollView{
                        ForEach(troubleCodeManager.troubleCodeList, id: \.self){ code in
                            TroubleCodeRow(troubleCode: code)
                        }
                    }
                }
                Button{
                    Task{
                        await troubleCodeManager.scanCodes()
                    }
                } label: {
                    Text("Scan Codes")
                        .padding()
                        .foregroundStyle(Color.white)
                        .background(Color.accentColor)
                        .clipShape(Capsule())
                }
                Button{
                    showClearCodesConfirmation = true
                } label: {
                    Text("Clear Codes")
                        .padding()
                        .foregroundStyle(Color.white)
                        .background(Color.secondary)
                        .clipShape(Capsule())
                }
                .confirmationDialog("Clear DTCs?", isPresented: $showClearCodesConfirmation, titleVisibility: .visible) {
                    Button("Clear", role: .destructive){
                        Task{
                            await troubleCodeManager.clearCodes()
                        }
                    }
                } message: {
                    Text(ConfirmationMessgae.clear)
                }
            }
            .padding(.bottom, 50)
            .alert(isPresented: $isAlertPresented){
                Alert(
                    title: Text("Warning") ,
                    message: Text(troubleCodeManager.errorMessage),
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
