//
//  Extensions.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/6/2.
//

import Foundation

extension Notification.Name {
    
    // Main VC
    static let UpdateTableview = Notification.Name("UpdateTableview")
    static let GetInfo         = Notification.Name("GetInfo")
    
    // BLE VC
    static let UpdateNumber    = Notification.Name("UpdateNumber")
    static let UpdateTextViewD = Notification.Name("UpdateTextViewD")
    static let UpdateTextView  = Notification.Name("UpdateTextView")
    static let FinalStep       = Notification.Name("FinalStep")
    static let GetInfo_two     = Notification.Name("GetInfo_two")
    static let StopWrok        = Notification.Name("StopWrok")
    static let scheduledTimer  = Notification.Name("scheduledTimer")
    
    // BLE Controller
    static let FirstWakeUp     = Notification.Name("FirstWakeUp")
    static let ACK_status      = Notification.Name("ACK_status")
    
}


