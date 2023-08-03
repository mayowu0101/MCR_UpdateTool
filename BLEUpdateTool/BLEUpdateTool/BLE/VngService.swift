//
//  VngService.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/6/5.
//

import Foundation

// MARK: - CMD 作業狀態 作業處理
open class VngService : NSObject {
    
    let TAG = "VNG-MCR"
    public static let VngSer = VngService()
    
    // File Block
    static var FileList   = [String]()  // All File Name List.
    static var FileData   = [UInt8]()   // save a file Data.
    static var CutData    = [UInt8]()   //
    static var FileCount    = 0
    static var BlockCount   = 0      // for total blocks number.
    static var block        = 0      // for work blocks count.
    
    
    public var ACKstatus  = false
    static var State_open = false
    
    public func _checkACK(_ rxData:[UInt8],_ iRxLin:Int) -> (Bool, [UInt8]) {
        var RxData = rxData
        var status = false
        
        if (iRxLin == 1){
            if (VngService.VngSer._checkACK(Utility.UInt8ToHexString(RxData[0]))){
                //Log_("",TAG, " Get ACK")
                status = true
            } else {
                Log_("",TAG, " not Get ACK")
            }
        }else{
            if (RxData[0] != 0x02){
                if (VngService.VngSer._checkACK(Utility.UInt8ToHexString(RxData[0]))){
                    RxData = VngService.VngSer._cutACK(RxData)
                    //Log_("",TAG, " [0x02] and Get ACK")
                    status = true
                } else {
                    Log_("",TAG, " [0x02] and not Get ACK")
                }
            }else{
                if (ACKstatus){
                    //Log_("",TAG, " [0x02] has Get ACK")
                    status = true
                }else{
                    Log_("",TAG, " [0x02] has not Get ACK")
                }
            }
        }
        ACKstatus = status
        return (status, RxData)
    }
    
    
    public func _checkACK(_ rx:String) -> Bool {
        var status = false
        if (rx == Command.ACK){
            status = true
        }else{
            Command.otherStatus(rx)
        }
        return status
    }
    
    public func _cutACK(_ rx:[UInt8]) -> [UInt8]{
        var d = [UInt8]()
        d = Utility.arrayCopy(rx, 1, rx.count)
        //Log_("",TAG, "_cutACK() len >> \(d.count)")
        return d
    }
    
    public func _cutData(_ rx:[UInt8]) -> [UInt8]{
        var d = [UInt8]()
        d = Utility.arrayCopy(rx, 1, rx.count-2)
        //Log_("",TAG, "_cutData() len >> \(d.count)")
        return d
    }
    
    // ** rxBuf 是已經去掉 頭尾checksun 的長度，一定要確保資料長度正確 ** //
    public func Cut_MESSAGE_RX(_ rxBuf:[UInt8]){
        
        //Log_("",TAG, "rxBuf : \(Utility.BytesToHexString(rxBuf))")
        
        if (rxBuf[0] == 0x52){  // R0 or R1
            if (rxBuf[1] == 0x30){  // R0 suss
                if (rxBuf.count == 54){
                    var data0 = [UInt8]()
                    var data1 = [UInt8]()
                    var data2 = [UInt8]()
                    var data3 = [UInt8]()
                    var data4 = [UInt8]()
                    
                    for i in 2...17 {  // 16
                        if (rxBuf[i] != 0x00){
                            data0.append(rxBuf[i])
                        }
                    }
                    Log_("",TAG, "d0 : \(Utility.BytesToHexString(data0))")
                    for i in 18...25 { // 8
                        data1.append(rxBuf[i])
                    }
                    Log_("",TAG, "d1 : \(Utility.BytesToHexString(data1))")
                    for i in 26...33 { // 8
                        data2.append(rxBuf[i])
                    }
                    Log_("",TAG, "d2 : \(Utility.BytesToHexString(data2))")
                    for i in 34...49 { // 16
                        if (rxBuf[i] != 0x00 && rxBuf[i] != 0x20){
                            data3.append(rxBuf[i])
                        }
                    }
                    Log_("",TAG, "d3 : \(Utility.BytesToHexString(data3))")
                    for i in 50...53 { // 4
                        if (rxBuf[i] != 0x00 && rxBuf[i] != 0x20){
                            data4.append(rxBuf[i])
                        }
                    }
                    Log_("",TAG, "d4 : \(Utility.BytesToHexString(data4))")
                    
                    VNGstatus(UPDATE_STEP._JUMP_LOADER.rawValue)
                    
                    if (VngService.State_open){
                        // Update to BLE_VC when X81 restart
                        VNGstatus(UPDATE_STEP._WAIT_DONE.rawValue)
                        NotificationCenter.default.post(name: .GetInfo_two, object: nil, userInfo: ["FW" : data0, "FWV" : data1,"FWB" : data2, "sn" : data3,"CID" : data4])
                    }else{
                        // Update to Main_VC
                        NotificationCenter.default.post(name: .GetInfo, object: nil, userInfo: ["FW" : data0, "FWV" : data1,"FWB" : data2, "sn" : data3,"CID" : data4])
                    }
                    
                    data0 = [UInt8]()
                    data1 = [UInt8]()
                    data2 = [UInt8]()
                    data3 = [UInt8]()
                    data4 = [UInt8]()
                    // 有計算時間、設置 bUpdate = falte
                } else {
                    Log_("T",TAG, VNG_InfoWrongLen)
                    Stop()
                }
                
            } else if (rxBuf[1] == 0x31 && rxBuf.count == 3) {  // R1
                if (rxBuf[2] == 0x32){
                    Log_("T",TAG, VNG_Abnormal)
                    Stop()
                }else{
                    VngService.FileData = VngService.VngSer.BundleData(VngService.FileList[VngService.FileCount])
                    if (rxBuf[2] == 0x47){
                        Log_("",TAG, "R1 receive 0x47")
                        Tag_x72state = false
                        VngService.block = 0
                        VNGstatus(UPDATE_STEP._AUTHENTICATE.rawValue)
                        VngService.VngSer.DoCommand(VngService.FileData, UInt32(0))
                    }else{
                        Log_("T",TAG, "Wait Device Switch Mode.")
                        VNGstatus(UPDATE_STEP._AUTHENTICATE.rawValue)
                        VngService.VngSer.DoCommand(VngService.FileData,UInt32(0))
                    }
                }
            }
        } else if (rxBuf[0] == 0x58 && rxBuf[1] == 0x37){
            if (rxBuf[2] == 0x32){
                if (rxBuf[3] == 0x00){
                    if (Tag_x72state){
                        nowflowstate = 3
                        sleep(DT_WaitSwitchMode)
                        Tag_x72state = false
                        VNGstatus(UPDATE_STEP._AUTHENTICATE.rawValue)
                        VngService.VngSer.DoCommand(VngService.FileData,UInt32(0))
                    }else{
                        Log_("T",TAG, "\n\(VngService.FileCount+1)/\(VngService.FileList.count) , \(VngService.FileList[VngService.FileCount])")
                        NotificationCenter.default.post(name: .UpdateNumber, object: nil)
                        VNGstatus(UPDATE_STEP._WRITE_BLOCK.rawValue)
                        VngService.block = 0
                        VngService.VngSer.DoCommand(VngService.FileData, UInt32(0))
                    }
                }else{
                    if (vngStatus == UPDATE_STEP._JUMP_LOADER.rawValue){
                        Log_("T",TAG, "Jump to loader failed.\nError status = \(rxBuf[3])")
                        Stop()
                    }else{
                        //build version error.
                        Log_("T",TAG, "Authenticate error.\nError status = \(rxBuf[3])")
                        Stop()
                    }
                }
            } else if (rxBuf[2] == 0x33){
                //Log_("",TAG, "file block : \(VngService.block+1)/\(VngService.BlockCount)")
                if (rxBuf[3] == VngService.block+1){
                    if(rxBuf[4] == 0x00){
                        VngService.block += 1
                        if (VngService.block < VngService.BlockCount){
                            VNGstatus(UPDATE_STEP._WRITE_BLOCK.rawValue)
                            //Log_("",TAG, "check data : \(VngService.FileData.count)")
                            VngService.VngSer.DoCommand(VngService.FileData, UInt32(0))
                        }else{
                            Log_("",TAG, "\nfile transfer completed.")
                            VNGstatus(UPDATE_STEP._RESET_PROCESS.rawValue)
                            VngService.VngSer.DoCommand([], UInt32(0))
                        }
                    }else{
                        Log_("",TAG, "Image block \(rxBuf[3]) error.\nError status =  \(rxBuf[4])")
                        Log_("T",TAG, "Image block error.")
                        
                        Stop()
                    }
                } else {
                    Log_("T",TAG, "\(VngService.block+1)/\(VngService.BlockCount), block is not equl to \(rxBuf[3])")
                    Stop()
                }
            } else if (rxBuf[2] == 0x34){
                if (rxBuf[3] == 0x00){
                    VngService.FileCount += 1
                    if (VngService.FileCount < VngService.FileList.count){
                        VNGstatus(UPDATE_STEP._AUTHENTICATE.rawValue)
                        VngService.block = 0
                        VngService.FileData = VngService.VngSer.BundleData(VngService.FileList[VngService.FileCount])
                        if((VngService.FileList[VngService.FileCount-1]).contains("0000_")){
                            let queue = DispatchQueue(label: "first_x74")
                            let count = DispatchSemaphore(value: 1)
                            count.wait()
                            queue.sync {
                                Log_("T",self.TAG, "\nWait Device Reset.")
                                count.signal()
                            }
                            count.wait()
                            queue.sync { //After(deadline: .now() + .seconds(10)) {
                                Log_("T",self.TAG, "\nReConnect Device.")
                                BLEController.shared_.reConnectToDevice()
                                sleep(DT_WaitSwitchMode)
                                count.signal()
                            }
                            count.wait()
                            queue.sync { //After(deadline: .now() + .seconds(15)) {
                                Log_("",self.TAG, "restart job.")
                                //VngService.VngSer.DoCommand(VngService.FileData,UInt32(0))
                                count.signal()
                            }
                        }else{
                            VngService.VngSer.DoCommand(VngService.FileData,UInt32(0))
                        }
                    }else{
                        Log_("T",TAG, "\nWaiting Device Reset.")
                        VNGstatus(UPDATE_STEP._WAIT_DONE.rawValue)
                        VngService.VngSer.DoCommand(VngService.FileData,UInt32(0))
                        nowflowstate = 3
                        
                        VngService.State_open = true
                        NotificationCenter.default.post(name: .FinalStep, object: nil)
                    }
                }else {
                    
                    Log_("T",TAG, "Image download process error.\nError status = \(rxBuf[3])")
                    Stop()
                }
            }
        }
    }
    
//    public func Cut_MESSAGE_DEVICE_UPDATE(_ VNGstatus:Int){
//
//    }
    
    public func DoCommand(_ data:[UInt8],_ sleepTime:UInt32){
        //Log_("",self.TAG, "do DoCommand()")
        
        if (Device_TimeOut){
            var bRun = false
            let queue_g = DispatchQueue.global()
            let queue_1 = DispatchQueue(label: "Do_Command")
            let count = DispatchSemaphore(value: 1)
            queue_g.sync {
                count.wait()
                queue_1.sync{
                    if(sleepTime != 0){
                        sleep(sleepTime)
                        //Log_("",self.TAG, "sleepTime")
                    }
                    count.signal()
                }
                count.wait()
                queue_1.sync{
                    switch (vngStatus){
                    case 0: //
                        Log_("",self.TAG, "0")
                    case 1:
                        bRun = Command._GetInfo()
                        count.signal()
                    case 2:
                        bRun = Command._GetStatus()
                        count.signal()
                    case 3:
                        bRun = Command._GetAuthenticate(data)
                        count.signal()
                    case 4:
                        bRun = Command._GetDownloadBlock(VngService.block, data)
                        count.signal()
                    case 5:
                        bRun = Command._GetDownloadProcess()
                        count.signal()
                    case 6:
                        bRun = Command._GetDeviceReset()
                        count.signal()
                    default:
                        Log_("",self.TAG, "unkown case.")
                        count.signal()
                    }
                }
                count.wait()
                queue_1.sync{
                    if (!bRun) {
                        //Log_("",self.TAG, "DoCommand() succ.")
                    //}else{
                        Log_("",self.TAG, "DoCommand() fail.")
                        Stop()
                    }
                    count.signal()
                }
            }
        }else{
            Log_("T", TAG, "Stop Device Connect.")
            Stop()
        }
        
    }
    
    
    
    // MARK: - Cut File Function
    
    public func BundleList() -> [String] {
        var sort     = [String]()
        var sortName = [String]()
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let FolderPath = "\(documentsDirectory)/assets/"
        do{
            let FileList = try FileManager.default.contentsOfDirectory(atPath: FolderPath)
            for name in FileList{
                if (name.contains(".COR")){
                    let index = name.index(name.startIndex, offsetBy: name.count-4)
                    sortName.append(String(name[..<index]))
                }
            }
        }catch{
            Log_("",TAG,"BundleList() fail : \(error.localizedDescription)")
        }
        
        sort = sortName.sorted()
        return sort
    }
    
    public func BundleData(_ fileName:String) -> [UInt8]{
        var fileData = [UInt8]()
        
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let documentsDirectory = paths[0]
        let FolderPath = "\(documentsDirectory)/assets/\(fileName).COR"
        
        do {
            let readHandler = try FileHandle(forReadingFrom:URL(string: FolderPath)!)
            let data = readHandler.readDataToEndOfFile()
            //Log_("",TAG, "FileName: \(fileName), Size: \(data), Times:\((data.count-896)/2048)") //, data: \(Utility.BytesToHexString(Array(data)))
            fileData = Array(data)
            VngService.BlockCount = (data.count-896)/2048
        } catch {
            Log_("T",TAG,"Get data is fail: \(error.localizedDescription)")
            Stop()
        }
        
        return fileData
    }
    
    // MARK: - wath path is Bundle
//    public func BundleList() -> [String]{
//        var sort     = [String]()
//        var sortName = [String]()
//
//        //if let bundlePath = Bundle.main.path(forResource: "assets", ofType: "bundle", inDirectory: ""){
//        if let bundlePath = Bundle.main.path(forResource: "P_assets2", ofType: "bundle", inDirectory: ""){
//            //Log_("",TAG, "OS Path: \(bundlePath)")
//            let fileManager = FileManager.default
//            do {
//                let filesFromBundle = try fileManager.contentsOfDirectory(atPath: bundlePath)
//                for name in filesFromBundle{
//                    if (name.contains(".COR")){
//                        let index = name.index(name.startIndex, offsetBy: name.count-4)
//                        sortName.append(String(name[..<index]))
//                    }
//                }
//            } catch {
//                Log_("T",TAG,"Open \(bundlePath) is fail.")
//                Stop()
//            }
//        }else{
//            Log_("T",TAG, "Open assets filder is fail.")
//            Stop()
//        }
//        sort = sortName.sorted()
//        return sort
//    }
    
//    public func BundleData(_ fileName:String) -> [UInt8] {
//        var fileData = [UInt8]()
//        //if let bundleURL = "\(documentsDirectory)/assets/",
//
//        if let bundleURL = Bundle.main.url(forResource: "P_assets2", withExtension: "bundle"),
//           let bundle = Bundle(url: bundleURL){
//            let fileURL = bundle.url(forResource: fileName , withExtension: "COR")!
//            print(bundleURL)
//            do {
//                let data = try Data(contentsOf: fileURL, options: .mappedIfSafe)
//                //Log_("",TAG, "FileName: \(fileName), Size: \(data), Times:\((data.count-896)/2048)") //, data: \(Utility.BytesToHexString(Array(data)))
//                fileData = Array(data)
//                VngService.BlockCount = (data.count-896)/2048
//            } catch {
//                Log_("T",TAG,"Get \(fileURL) data is fail.")
//                Stop()
//            }
//        }
//        return fileData
//    }
    
    public func culcFile() -> Int {
        var num = 0
        let list = BundleList()
        for i in list {
            _ = BundleData(i)
            num += VngService.BlockCount
        }
        return num
    }
    
    public func CutString(_ data:[UInt8]) -> [UInt8]{  //string is 2048 len
        var cutD = [UInt8]()
        //Log_("",self.TAG, "Cut String : \((VngService.block & 0xFF)*2048) to \(((VngService.block & 0xFF)*2048)+2048)")
        cutD = Utility.arrayCopy(data, (VngService.block & 0xFF)*2048, ((VngService.block & 0xFF)*2048)+2048)
        return cutD
    }
    
} // end VngService class

