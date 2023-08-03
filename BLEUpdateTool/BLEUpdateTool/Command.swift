//
//  Command.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/4/6.
//

import Foundation

open class Command {
    
    static let TAG = "Global_Com"
    
    static let STX = Utility.IntToHexString(0x02)
    static let ETX = Utility.IntToHexString(0x03)
    static let EOT = Utility.IntToHexString(0x04)
    
    static let ACK = Utility.IntToHexString(0x06)
    static let NAK = Utility.IntToHexString(0x15)
    static let DLE = Utility.IntToHexString(0x10)
    
    // send same data again
    static let other = Utility.IntToHexString(0x41)  //這只會出現在流程異常時出現。  x72同時傳了兩次，沒先等待好前一次回完、才送下一次。
    
    public static func otherStatus(_ rx:String){
        //Log_("",TAG,#function)
        if (rx == Command.NAK){
            Log_("T",self.TAG, "Device reture : NAK, stop work.")
            Stop()
        }else if (rx == Command.other){
            Log_("T",self.TAG, "Device state not Ready, wait 3s send again.")
            sleep(DT_WaitDeviceStatus)
            VngService.block += 1
            VNGstatus(UPDATE_STEP._WRITE_BLOCK.rawValue)
            VngService.VngSer.DoCommand(VngService.FileData, UInt32(0))
        }else{
            Log_("T",self.TAG, "Device reture : \(rx), please contact the repair center.")
            Stop()
        }
    }
    
    public static func _AddRules(comm:[UInt8]) -> [UInt8] {
        var outData: [UInt8] = [Utility.HexStringToBytes(Command.STX)[0]]
        for i in 0..<comm.count {
            outData.append(comm[i])
        }
        outData.append(Utility.HexStringToBytes(Command.ETX)[0])
        outData.append(Command._createLRC(outData))
        //Log_(#function,str: Utility.BytesToHexString(outData))
        return outData
    }
    
    public static func _GetInfo() -> Bool {
        //Log_("",TAG,#function)
        var outData: [UInt8] = []
        var sendStatus = false
        let _R0 = Utility.UTF8ToUInt8("R0")
        for i in 0..<_R0.count {
            outData.append(_R0[i])
        }
        outData = _AddRules(comm: outData)
        
        
        if (BLEController.shared_.sendData(Data(outData), uuidString: "C301", writeType: .withResponse)){
            //Log_("",self.TAG, "Send R0")
            sendStatus = true
        }else{
            Log_("",self.TAG, "Send R0 error ")
        }
        return sendStatus
    }
    
    public static func _GetStatus() -> Bool {
        //Log_("",TAG,#function)
        var outData: [UInt8] = []
        var sendStatus = false
        let _R1 = Utility.UTF8ToUInt8("R1")
        for i in 0..<_R1.count {
            outData.append(_R1[i])
        }
        outData = _AddRules(comm: outData)
        
        
        if (BLEController.shared_.sendData(Data(outData), uuidString: "C301", writeType: .withResponse)){
            //Log_("",self.TAG, "Send R1")
            sendStatus = true
        }else{
            Log_("",self.TAG, "Send R1 error ")
        }
        return sendStatus
    }
    
    public static func _GetAuthenticate(_ bData:[UInt8]) -> Bool {
        //Log_("",TAG,#function)
        var outData: [UInt8] = []
        var cutData: [UInt8] = []
        var sendStatus = false
        outData.append(contentsOf: Utility.UTF8ToUInt8("X72"))
        outData.append(contentsOf: Utility.HexStringToBytes("0E03"))
        outData.append(contentsOf: Utility.HexStringToBytes(Utility.IntToHexString(0x80 & 0xFF)))
        
        VngService.CutData = CutFrist(bData)
        cutData = VngService.CutData
        //cutData = CutFrist(bData)
        
        for i in 0..<cutData.count {
            outData.append(cutData[i])
        }
        outData = _AddRules(comm: outData)
        //Log_("",self.TAG, "FW download request1.")
        if(BLEController.shared_.sendData(Data(outData), uuidString: "C301", writeType: .withResponse)){
            //Log_("",self.TAG, "Send X72")
            sendStatus = true
        }else{
            Log_("",self.TAG, "Send X72 error ")
        }
        //let buf : [UInt8] = [88,55,50,0]  //58 37 32 00
        //let buf : [UInt8] = [88,55,51,1,0]  //58 37 33 00 00
        //VngService.VngSer.Cut_MESSAGE_RX(buf)
        //print("testCase 1 ")
        return sendStatus
    }
    
    public static func _GetDownloadBlock(_ bBlock:Int,_ bData:[UInt8]) -> Bool {
        //Log_("",TAG,#function)
        var outData: [UInt8] = []
        var cutData: [UInt8] = []
        var sendStatus = false
        outData.append(contentsOf: Utility.UTF8ToUInt8("X73"))
        outData.append(contentsOf: Utility.HexStringToBytes(Utility.IntToHexString(bBlock+1 & 0xFF)))
        
        VngService.CutData = VngService.VngSer.CutString(bData)
        cutData = VngService.CutData
        //cutData = VngService.VngSer.CutString(bData)
        
        for i in 0..<cutData.count {
            outData.append(cutData[i])
        }
        outData = _AddRules(comm: outData)
        //Log_("",self.TAG, "FW download request2.");
        if(BLEController.shared_.sendData(Data(outData), uuidString: "C301", writeType: .withResponse)){
            //Log_("",self.TAG, "Send X73")
            sendStatus = true
        }else{
            Log_("",self.TAG, "Send X73 error ")
        }
        //let one = Utility.HexStringToBytes(Utility.IntToHexString(bBlock+1 & 0xFF))
        //let buf : [UInt8] = [88,55,51,one[0],0]  //58 37 33 00 00
        //VngService.VngSer.Cut_MESSAGE_RX(buf)
        //print("testCase 2 ")
        return sendStatus
    }
    
    public static func _GetDownloadProcess() -> Bool {
        //Log_("",TAG,#function)
        var outData: [UInt8] = []
        var sendStatus = false
        outData.append(contentsOf: Utility.UTF8ToUInt8("X74"))
        outData = _AddRules(comm: outData)
        //Log_("",self.TAG, "FW download request3.");
        if(BLEController.shared_.sendData(Data(outData), uuidString: "C301", writeType: .withResponse)){
            //Log_("",self.TAG, "Send X74")
            sendStatus = true
        }else{
            Log_("",self.TAG, "Send X74 error ")
        }
        //let buf : [UInt8] = [88,55,52,0,0]  //58 37 34 00 00
        //VngService.VngSer.Cut_MESSAGE_RX(buf)
        //print("testCase 3 ")
        return sendStatus
    }
    
    public static func _GetDeviceReset() -> Bool {
        //Log_("",TAG,#function)
        var outData: [UInt8] = []
        var sendStatus = false
        outData.append(contentsOf: Utility.UTF8ToUInt8("X81"))
        outData = _AddRules(comm: outData)
        if(BLEController.shared_.sendData(Data(outData), uuidString: "C301", writeType: .withResponse)){
            //Log_("",self.TAG, "Send X81")
            sendStatus = true
        }else{
            Log_("",self.TAG, "Send X81 error ")
        }
        return sendStatus
    }
    
    public static func _ACK() -> Bool {
        //Log_("",TAG,#function)
        var outData: [UInt8] = []
        var sendStatus = false
        
        outData.append(Utility.HexStringToBytes(Command.ACK)[0])
        if(BLEController.shared_.sendData(Data(outData), uuidString: "C301", writeType: .withResponse)){
            //Log_("",self.TAG, "Send ACK")
            sendStatus = true
        }else{
            Log_("",self.TAG, "Send ACK error ")
        }
        return sendStatus
    }
    
    public static func _createLRC(_ data:[UInt8]) -> UInt8 {
        var LRC: UInt8 = data[1]
        for d in 2..<data.count {
            LRC = LRC^data[d]
        }
        //Log_("", Utility.UInt8ToHexString(LRC))
        return LRC
    }
    
    public static func _checkLRC(_ data:[UInt8]) -> Bool {
        var status = false
        var LRC: UInt8 = data[1]
        //Log_("", "len : \(data.count)")
        
        for d in 2..<data.count-1 {
            LRC = LRC^data[d]
        }
        //Log_("",TAG, "calc out: "+Utility.UInt8ToHexString(LRC))
        
        if (LRC == data[data.count-1]){
            status = true
        }
        return status
    }
    
    static func CutFrist(_ data:[UInt8]) -> [UInt8]{  //string is 896 len
        var cutD = [UInt8]()
        //Log_("",self.TAG, "Cut Frist : \(data.count-896)")
        cutD = Utility.arrayCopy(data, (data.count-896), data.count)
        return cutD
    }
    
    
}
