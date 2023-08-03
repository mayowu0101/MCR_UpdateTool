//
//  global.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/3/31.
//

import UIKit
import CoreBluetooth

// MARK: - RXTX timeCount
var Device_TimeOut     = true  //equal false is TimeOut.
let TimeOut_s : Double = 5

// MARK: - WaitDeviceState DelayTime(s)
let DT_WaitSwitchMode     :UInt32 = 10
let DT_WaitSendACK        :UInt32 = UInt32(0.2)
let DT_WaitDeviceStatus   :UInt32 = 2
let DT_WaitReConnect      :UInt32 = 30

// MARK: - Device Parameter
let XAC_UUID_SERVICE = "FF01"
let XAC_UUID_TX_MCR  = "C300"   //MCR C300 notifying:YES
let XAC_UUID_RX_MCR  = "C301"   //MCR C301 notifying:NO

struct BLEstandard{
    var name   : String
    var CBUUID : String
    var cbPeri : CBPeripheral
    var RSSI   : String
}

var devicelist : [BLEstandard] = []  // Device List
var select_row = 0
var currentGBUUID = ""

//確定機器連線取得didDiscoverDescriptorsFor, 要再去執行 Info。
var Tag_FirstStep  = false  // 當到FirstWakeUp()
var Tag_FinalStep  = true   // 當到FinalStep()
var Tag_isLeave    = false  // 當按下back, 觸發BLE斷線, 到didDisconnectPeripheral時 不做從新連線。
var Tag_x72state   = true   // 當機器正常狀態下，先做一次x72會切換mode，切換完成需要先再下一次x72 才能使x73正常
//var Tag_butCancel  = true   // 如果有需要多按鈕終止作業才需要用

//因應處理機器沒回傳結果
var lastflowstate = 0  // 記錄狀態 = 1:send 2:didUpdateValueFor 3:例外
var nowflowstate  = 0  // 目前狀態
var flowCount     = 0

// MARK: - Connect Device Step
var vngStatus = 0

enum UPDATE_STEP : Int{
    case _GET_STATUS    = 0
    case _GET_INFO      = 1
    case _JUMP_LOADER   = 2
    case _AUTHENTICATE  = 3
    case _WRITE_BLOCK   = 4
    case _RESET_PROCESS = 5
    case _WAIT_DONE     = 6
}

let VngMessage = [ 0 : "UPDATE_STEP_GET_STATUS",
                   1 : "UPDATE_STEP_GET_INFO",
                   2 : "UPDATE_STEP_JUMP_LOADER",
                   3 : "UPDATE_STEP_AUTHENTICATE",
                   4 : "UPDATE_STEP_WRITE_BLOCK",
                   5 : "UPDATE_STEP_RESET_PROCESS",
                   6 : "UPDATE_STEP_WAIT_DONE"]

func VNGstatus(_ i:Int){
    vngStatus = i
    //Log_("","Global_Log", "VNG State is : \(VngMessage[i] ?? "")")
}

// MARK: - String
// on iOS15 has new function NSMutableAttributedString that can create different color in the one string.
let BaseContext      = ", please contact the repair center."

let VNG_Abnormal     = "The device is abnormal\(BaseContext)"
let VNG_InfoWrongLen = "Receive device info data len is not 54\(BaseContext)"

// MARK: - Global function
func checkCBUUIB(str:String) -> Bool {
    var status = false
    for i in 0..<devicelist.count {
        if (devicelist[i].CBUUID == str){
            status = true
        }
    }
    return status
}

var LogStrFile = ""

func Log_(_ showStatus:String,_ tag:String,_ str:String) {
    // T  textView
    // L  tag  logFile
    DispatchQueue(label: "Log").sync {
        
        let time = Utility.getTime(str: "MM-dd hh:mm:ss.SSS")
        var _str = ""
        
        if showStatus == "T" {
            _str = "\(time)  T[\(tag)]  \(str)"
            
            let s = "\(str)"  //\(time)
            NotificationCenter.default.post(name: .UpdateTextView, object: nil, userInfo:  ["nLine":s])
            
            Utility.writeMore(_str + "\n", true)
        } else if showStatus == "TD" {  //作業中顯示 . ，每一點代表送一次資料
            _str += "\(time) TD[\(tag)]"
            
            NotificationCenter.default.post(name: .UpdateTextViewD, object: nil, userInfo: nil)
        } else {
            _str = "\(time)  D[\(tag)]  \(str)"
            Utility.writeMore(_str + "\n", true)
        }
        
        print(_str)
        LogStrFile += _str + "\n"
    }
    
}

// MARK: - LOG Parameter
// For Log File
let Log_times = Utility.getTime(str: "YYYY-MM-dd_hhmmss.SSS")
let Log_paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
let Log_documentsDirectory = Log_paths[0]
//let Log_fileName = "\(Log_documentsDirectory)/\(Log_times)_Log.txt"
var LogPath      =  "" //Log_fileName?.path


// targer flow status
var timer : Timer  = Timer()

// stop work
func Stop(){
    Log_("", "Global_Log", "Stop() ")
    NotificationCenter.default.post(name: .StopWrok, object: nil, userInfo: nil)
    timer.invalidate()
}


