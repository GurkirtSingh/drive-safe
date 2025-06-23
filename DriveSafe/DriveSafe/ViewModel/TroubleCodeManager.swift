//
//  TroubleCodeManager.swift
//  DriveSafe
//
//  Created by Gurkirt Singh on 2025-06-19.
//

import Foundation
internal import Combine
import SwiftUI

@MainActor
class TroubleCodeManager: ObservableObject{
    
    @Published var isOBD2Connected: Bool = false
    @Published var isScanning: Bool = false
    @Published var errorMessage: String = ErrorMessage.unexpected
    @Published var isDTCCleared: Bool = false
    @Published var isAlertPresented: Bool = false
    
    private var troubleCodes: [String: TroubleCode] = [:]
    // get list of trouble codes
    var troubleCodeList:[TroubleCode] {
        Array(troubleCodes.values)
    }
    
    private var cancellable = Set<AnyCancellable>()
    
    private let obd2Client: OBD2Client
    
    init(obd2Client: OBD2Client){
        self.obd2Client = obd2Client
        
        obd2Client.$isConnected
            .assign(to: &$isOBD2Connected)
    }
    
    func upsert(code: String, newStatus: TroubleCodeType) {
        if var existing = troubleCodes[code] {
            existing.status = newStatus
            troubleCodes[code] = existing
        } else {
            troubleCodes[code] = TroubleCode(code: code, status: newStatus)
        }
    }
    
    
    
    // reset troubleCodes List
    private func resetTroubleCodeList(){
        troubleCodes = [:]
    }
    
    // set error message
    private func setErrorMessage(message: String){
        errorMessage = message
    }
    
    private func clearErrorMessage(){
        errorMessage = ErrorMessage.unexpected
    }
    private func setIsScanning(){
        isScanning = true
    }
    private func resetIsScanning(){
        isScanning = false
    }
    
    private func setIsDTCCleared(){
        isDTCCleared = true
    }
    
    private func resetIsDTCCleared(){
        isDTCCleared = false
    }
    
    private func setIsAlertPresented(){
        isAlertPresented = true
    }
    
    func scanCodes() async {
        
        resetTroubleCodeList()
        setIsScanning()
        clearErrorMessage()
        
        do {
            if let results = try await obd2Client.scanDTC(.pending){
                for code in results {
                    upsert(code: code, newStatus: .pending)
                }
            }
            if let results = try await obd2Client.scanDTC(.confirmed){
                for code in results {
                    upsert(code: code, newStatus: .pending)
                }
            }
            if let results = try await obd2Client.scanDTC(.permanent){
                for code in results {
                    upsert(code: code, newStatus: .pending)
                }
            }
        } catch {
            setIsAlertPresented()
            setErrorMessage(message: error.localizedDescription)
        }
        resetIsScanning()
    }
    
    func clearCodes() async {
        clearErrorMessage()
        do{
            let clear = try await obd2Client.clearDTC()
            if clear{
                setIsDTCCleared()
            } else{
                resetIsDTCCleared()
                setIsAlertPresented()
                setErrorMessage(message: "Failed to clear DTCs.")
            }
        }catch {
            resetIsDTCCleared()
            setIsAlertPresented()
            setErrorMessage(message: error.localizedDescription)
        }
    }
}
