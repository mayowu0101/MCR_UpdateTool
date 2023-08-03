//
//  VngService.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/5/31.
//

import UIKit

public protocol PhysicalPort {
    
    func GcpOpen() -> Bool
    func GcpClose() -> Bool
    func GcpWrite(_ buff:UInt8,_ inLen:Int) -> Bool  //UInt8 = Byte
    func IsGcpPairing() -> Bool
    func GcpRead(_ buff:UInt8,_ inLen:Int) -> Int
    
    // Android this function, can get func name
    init(copy: Self)
    func copy() -> any PhysicalPort
    
    // Notification BLE connention status
    func setCallback(_ notionBLE:Notification)
    
}

