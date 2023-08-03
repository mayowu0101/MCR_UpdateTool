//
//  BLEController.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/6/1.
//

import Foundation
import CoreBluetooth

class BLEController: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    let TAG_C = "BLE_Cen"
    let TAG_P = "BLE_Per"
    
    public static let shared_ = BLEController()
    
    var centralManager    : CBCentralManager!
    var connectPeripheral : CBPeripheral!
    let bluetoothQueue    = DispatchQueue(label: "blecomQueue")
    var charDictionary    = [String: CBCharacteristic]()         //save edge Bluetooth Characteristic
    static let DataMTU    = 300
    
    var BLE_connect    = true
    var ACK_status_    = false
    
    let queueOnly = DispatchSemaphore(value: 1)
    let queue = DispatchQueue(label: "BLEC_send",attributes: .concurrent)
    
    public override init(){
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: bluetoothQueue)
        
        Log_("", TAG_C, "BLE MTU : \(BLEController.DataMTU)")
        // CBCentralManagerOptionShowPowerAlertKey
        // CBCentralManagerOptionRestoreIdentifierKey
    }
    
    public func startScan(){
        //Log_("",TAG_C, "Bluetooth startScan()")
        
        if centralManager.state == .poweredOn {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        } else {
            Log_("",TAG_C, "Bluetooth startScan() fail, Bluetooth manager state is: \(centralManager.state.rawValue)")
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(ACK_s), name: .ACK_status, object: nil)
    }
    
    @objc func ACK_s(notify: Notification){
        //Log_("",TAG_C, "Notification ACK_s()")
        ACK_status_ = true
    }
    
    public func stopScan(){
        Log_("",TAG_C, "Bluetooth stopScan()")
        centralManager.stopScan()
    }
    
    public func connect(peripheral: CBPeripheral){
        Log_("",TAG_C, "Bluetooth connect()")
        centralManager.connect(peripheral, options: nil)
    }
    
    public func disconnect(peripheral: CBPeripheral){
        Log_("",TAG_C, "Bluetooth disconnect()")
        centralManager.cancelPeripheralConnection(peripheral)
    }
    
    @objc func timerTarget() {
        Log_("T", TAG_C, "Device TimeOut.")
        Stop()
    }
    
    func sendData(_ data: Data, uuidString: String, writeType: CBCharacteristicWriteType) ->Bool {
        //Log_("",TAG_C, "Bluetooth sendData()")
        nowflowstate = 1
        
        let dataWith = connectPeripheral.maximumWriteValueLength(for: .withResponse)
        let dataWithout = connectPeripheral.maximumWriteValueLength(for: .withoutResponse)
        
        if (dataWith < BLEController.DataMTU && dataWithout < BLEController.DataMTU){
            Log_("",TAG_C, "Bluetooth withResponse size: \(dataWith), withoutResponse size: \(dataWithout)")
        }
        
        var status = false
        
        if let characteristic = charDictionary[uuidString] {
            
            let num : Int = data.count/BLEController.DataMTU
            
            if (!connectPeripheral.canSendWriteWithoutResponse) {
               Log_("",TAG_C, "Peripheral Send States is: \(connectPeripheral.canSendWriteWithoutResponse)")
            }
            
            var cutD = [UInt8]()
            
            queue.sync {  //async !!!
                Log_("TD",self.TAG_C, "")
                if (num>0){
                    for i in 0...num{
                        queueOnly.wait()
                        if (i == 0){
                            cutD = Utility.arrayCopy(Array(data), 0, BLEController.DataMTU)
                        } else if (i == num){
                            cutD = Utility.arrayCopy(Array(data), (i & 0xFF)*BLEController.DataMTU, data.count)
                        }
                        else{
                            cutD = Utility.arrayCopy(Array(data), (i & 0xFF)*BLEController.DataMTU, (i & 0xFF)*BLEController.DataMTU+BLEController.DataMTU)
                        }
                        
                        self.connectPeripheral.writeValue(
                            Data(cutD),
                            for: characteristic,
                            type: writeType
                        )
                        queueOnly.signal()
                    }
                    //Log_("",self.TAG_C, "file send finish.")
                }else{
                    self.connectPeripheral.writeValue(
                        data,
                        for: characteristic,
                        type: writeType
                    )
                }
            }
            status = true
        }
        return status
    }
    
    
    
    /* 當 central 端重新執行後，嘗試取回 peripheral */
//    func isPaired() -> Bool {
//        Log_("",TAG_C, "BLE isPaired()")
//        var s = false
//
//        if (BLE_connect) {
//            let uuid = UUID(uuidString: currentGBUUID)
//            let list = centralManager.retrievePeripherals(withIdentifiers: [uuid!]) //retrieveConnectedPeripherals(withServices: currentGBUUID) //
//            if list.count > 0 {
//                connectPeripheral = list.first!
//                connectPeripheral.delegate = self
//                s = true
//            }else{
//                Log_("",TAG_C, "list count 0")
//            }
//        }else{
//            Log_("",TAG_C, "not pair")
//        }
//        return s
//    }

    /* 解配對 */
    func unpair() {
        Log_("",TAG_C, "BLE unPair()")
        centralManager.cancelPeripheralConnection(connectPeripheral)
    }
    
}


extension BLEController {
    // #1 check BLE state
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        //Log_("", TAG_C, #function)
        var BLEstatus = false
        
        switch central.state {
        case .unknown:
            Log_("",TAG_C, "Bluetooth status is UNKNOWN")
        case .resetting:
            Log_("",TAG_C, "Bluetooth status is RESETTING")
        case .unsupported:
            Log_("",TAG_C, "Bluetooth status is UNSUPPORTED")
        case .unauthorized:
            Log_("",TAG_C, "Bluetooth status is UNAUTHORIZED")
        case .poweredOff:
            Log_("",TAG_C, "Bluetooth status is POWERED OFF")
        case .poweredOn:
            Log_("",TAG_C, "Bluetooth status is POWERED ON")
            BLEstatus = true
            
        @unknown default:
            Log_("",TAG_C, "Bluetooth status is not exist")
        }
        
        if (BLEstatus){
            startScan()
        }else{
            Log_("T",TAG_C, "Get Bluetooth state is error.")
            Stop()
        }
        
    }
    
    // #2 get device
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //Log_("", TAG_C, #function)
        guard let deviceName = peripheral.name else {
            return
        }
        
        let deviceRSSI   = "\(RSSI.intValue)"
        let deviceCBUUID = "\(peripheral.identifier)"
        
        if(!checkCBUUIB(str:deviceCBUUID)){
            devicelist.append(BLEstandard(name:deviceName,CBUUID:deviceCBUUID,cbPeri:peripheral,RSSI:deviceRSSI))
            NotificationCenter.default.post(name: .UpdateTableview, object: nil)
        }
    }
    
    // #3
    public func ConnectToDevice(_ i: Int) {
        //Log_("", TAG_C, #function)
        connectPeripheral = devicelist[i].cbPeri
        currentGBUUID = devicelist[i].CBUUID
        
        connect(peripheral: connectPeripheral!)
        if (connectPeripheral.maximumWriteValueLength(for: .withoutResponse) == 20) {
            Log_("", TAG_C, "try connect again, check device write data len.")
            connect(peripheral: connectPeripheral!)
        }
    }
    
    public func reConnectToDevice(){
        Log_("", TAG_C, #function)
        connect(peripheral: connectPeripheral!)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //Log_("", TAG_C, #function)
        connectPeripheral.delegate = self
        
        //當作再次連線時會到這裡，且 withoutResponse 第一次會是 20
        let dataWith = connectPeripheral.maximumWriteValueLength(for: .withResponse)
        let dataWithout = connectPeripheral.maximumWriteValueLength(for: .withoutResponse)
        
        if (dataWith < BLEController.DataMTU && dataWithout < BLEController.DataMTU){
            Log_("",TAG_C, "Bluetooth withResponse size: \(dataWith), withoutResponse size: \(dataWithout)")
        }
        
        //charDictionary = [:]
        // #4 open peripheral
        peripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        Log_("", TAG_C, #function + " connect() fail")
        Stop()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        //Log_("", TAG_C, #function + "Peripheral Disconnect()")
        Log_("T", TAG_C, "Device Disconnect.")
        
        if (!Tag_isLeave){
            if(vngStatus != UPDATE_STEP._WAIT_DONE.rawValue){
                reConnectToDevice()
            }
        }else{
            Stop()
            BLE_connect = false
        }
    }
    
    
    
    // #1
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //Log_("", TAG_P, #function)
        guard error == nil else {
            Log_("",TAG_P, "ERROR: \(#function)")
            Log_("",TAG_P, error!.localizedDescription)
            return
        }
        
        charDictionary = [:]
        
        for motionService in peripheral.services! {
            //Log_("",TAG_P, "found UUID: \(motionService.uuid)")
            connectPeripheral!.discoverCharacteristics(nil, for: motionService)
        }
    }
    
    // #2
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            Log_("",TAG_P, "ERROR: \(#function)")
            Log_("",TAG_P, error!.localizedDescription)
            return
        }
        
        Log_("T", TAG_P, "Connect to Device.")
        
        for characteristic in service.characteristics! {
            
            let uuidString = characteristic.uuid.uuidString
            charDictionary[uuidString] = characteristic
            //Log_("",TAG_P, "found characteristic : \(uuidString)")
            
            if uuidString == "C300" {
                connectPeripheral!.setNotifyValue(true, for: charDictionary["C300"]!)
            }else if uuidString == "C301" {
                //設定 true 會訂閱 由特徵值是C301 來的訊息
                connectPeripheral!.setNotifyValue(true, for: charDictionary["C301"]!)
            }
            peripheral.discoverDescriptors(for: characteristic)
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            Log_("",TAG_P, "ERROR: \(#function)")
            Log_("",TAG_P, error!.localizedDescription.debugDescription)
            return
        }
        
        var word = ""
        
        if (characteristic.descriptors != nil){
            for descript in characteristic.description {
                word += "\(descript.description)"
            }
            Log_("",TAG_P, "DidDiscoverDescriptorsFor : \(word)")
            
            if (characteristic.uuid.uuidString == "C301"){
                
                if (!Tag_FirstStep){
                    Tag_FirstStep = true
                    NotificationCenter.default.post(name: .FirstWakeUp, object: nil, userInfo: nil)
                } else{
                    if(vngStatus == UPDATE_STEP._AUTHENTICATE.rawValue || vngStatus == UPDATE_STEP._WRITE_BLOCK.rawValue){
                        VngService.VngSer.DoCommand(VngService.FileData,UInt32(10))
                    }else {
                        if (!Tag_FinalStep){
                            Tag_FinalStep = true
                        }
                        VngService.VngSer.DoCommand([],UInt32(10))
                    }
                }
            }
        }
    }
    
    // 只能用在沒收到回應時，主動去觸發
    func openRead_character(){
        Log_("",TAG_C, "openRead_character()")
        connectPeripheral.readValue(for: charDictionary["C300"]!)
    }
    
    // #3
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (nowflowstate == 3){
            nowflowstate = 3
        }else{
            nowflowstate = 2
        }
        
        queue.sync {
            //Log_("",TAG_P, "Data from .. \(characteristic.uuid.uuidString)")
            
            guard error == nil else {
                Log_("",TAG_P, #function + "  ERROR: \(String(describing: error))")
                return
            }
            
            var RxData = [UInt8](characteristic.value! as NSData)
            let iRxLin = RxData.count
            //Log_("",TAG_P, "Data : " + Utility.BytesToHexString(RxData) )
            //Log_("",TAG_P, "Data lin : \(iRxLin)")
            
            let r = VngService.VngSer._checkACK(RxData,iRxLin)
            if (r.0){
                NotificationCenter.default.post(name: .ACK_status, object: nil)
                RxData = r.1
                if (VngService.VngSer.ACKstatus && iRxLin != 1 && iRxLin != 2){
                    //Log_("",TAG_P, "do LRC check")
                    if(Command._checkLRC(RxData)){
                        //Log_("",TAG_P, "LRC check Succ, send ACK : \(Command._ACK())")
                        if(Command._ACK()){
                            sleep(DT_WaitSendACK)
                            RxData = VngService.VngSer._cutData((RxData))
                            VngService.VngSer.Cut_MESSAGE_RX(RxData)
                            VngService.VngSer.ACKstatus = false
                        }else{
                            Log_("",TAG_P, "ACK send fail.")
                            Stop()
                        }
                    } else {
                        Log_("T",TAG_P, "LRC check fail ,data is : \(Utility.BytesToHexString(RxData))")
                        Stop()
                    }
                }
            }else{
                Log_("T",TAG_P, "ACK check fail.")
                Stop()
            }
        }
        
    }
    
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            Log_("",TAG_P, #function + " Write data error: \(error!)")
            Stop()
        }
    }
    
    
}
