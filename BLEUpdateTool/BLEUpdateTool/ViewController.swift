//
//  ViewController.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/6/1.
//


// 1. 對應舊版本： In iOS 12 and earlier, include NSBluetoothPeripheralUsageDescription to access Bluetooth peripheral data.
// 2. 在iOS13起，有使用到藍芽通訊，要求要在 info.plist 裡加入 NSBluetoothAlwaysUsageDescription 項目說明，此內容相顯示在第一次使用AP時顯示。

// 暫定選用 iOS13 以上系統版本。

import UIKit
import CoreBluetooth


class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    let TAG = "VC_Main"
    
    @IBOutlet weak var but_SCAN      : UIButton!
    @IBOutlet weak var table_scanlist: UITableView!
    
    var table_count = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Copy assets Folder
//        let FolderPath = "\(Log_documentsDirectory)/assets/"
//        if (!Utility.directoryIsExists(path: FolderPath)){
//            Log_("",TAG,"Update OS Folder not Exist, copy default file. OS version is : Chase_MCR_FW_Release_74601900_23061201_Version.")
//            let bundleURL = Bundle.main.url(forResource: "P_assets2", withExtension: "bundle")
//            if (!Utility.copyfile(sourcePath: bundleURL!.path, targetPath: FolderPath)){
//                Log_("",TAG,"copyfile fail ...")
//            }
//        }else{
//            Log_("",TAG,"Update Folder Exist")
//        }
        
        DispatchQueue.main.async {
            // tableview setting
            let nib2 = UINib(nibName: "TableViewCell_ble_list", bundle: nil)
            self.table_scanlist.register(nib2, forCellReuseIdentifier: "TableViewCell_ble_list")
            self.table_scanlist.dataSource = self
            self.table_scanlist.separatorColor = UIColor.gray
            self.table_scanlist.backgroundColor = UIColor.gray
            self.table_count = devicelist.count
            
            if #available(iOS 13.0, *){
                Log_("",self.TAG, "OS version is \(UIDevice.current.systemVersion), do Bluetooth init.")
                
                // Bluetooth init
                _ = BLEController.shared_
                
                // If device is connect, wakeup next step.
                NotificationCenter.default.addObserver(self, selector: #selector(self.FirstWakeUp), name: .FirstWakeUp, object: nil)
                // Update tableView when new device are found.
                NotificationCenter.default.addObserver(self, selector: #selector(self.UpdateTableview), name: .UpdateTableview, object: nil)
            }else{
                Log_("",self.TAG, "OS version is not 13.0 above.")
                self.view.makeToast("OS version is not 13.0 above.", duration: 1.5, position: .bottom)
                
                DispatchQueue.main.async {
                    let alertController = UIAlertController(title: "WRONG", message: "Please update your OS version on iOS13.0 above.", preferredStyle: .alert)
                    let Action = UIAlertAction(title: "Close APP", style: .default, handler: {
                        (action: UIAlertAction!) -> Void in
                        Log_("T",self.TAG, "button Close APP")
                        UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                        
                    })
                    alertController.addAction(Action)
                    self.present(alertController, animated: true)
                }
                
            }
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        devicelist = []
        table_count = devicelist.count
        table_scanlist.reloadData()
    }
    
    @objc func FirstWakeUp(notifi: Notification){
        if (Tag_FirstStep){
            sleep(DT_WaitDeviceStatus)
            VngService.VngSer.DoCommand([],UInt32(0))
            sleep(DT_WaitDeviceStatus)
            NotificationCenter.default.addObserver(self, selector: #selector(self.GetInfo), name: .GetInfo, object: nil)
        }else{
            Log_("T", TAG, "FirstConneationError")
        }
    }
    
    @objc func GetInfo(notify: Notification){
        //Log_("",TAG,"Notification GetInfo()")
        if (notify.userInfo != nil){
            
            var FW = [UInt8]()
            var FWV = [UInt8]()
            var FWB = [UInt8]()
            var sn = [UInt8]()
            var CID = [UInt8]()
            
            let queueInfo = DispatchQueue.main
            queueInfo.sync {
                if let userInfo = notify.userInfo! as? [String : AnyObject] {
                    guard let fW = userInfo["FW"] as? [UInt8] else {
                        Log_("",TAG, "Get FW error!")
                        return
                    }
                    FW = fW
                    guard let fWV = userInfo["FWV"] as? [UInt8] else {
                        Log_("",TAG, "Get FWV error!")
                        return
                    }
                    FWV = fWV
                    guard let fWB = userInfo["FWB"] as? [UInt8] else {
                        Log_("",TAG, "Get FWB error!")
                        return
                    }
                    FWB = fWB
                    guard let sN = userInfo["sn"] as? [UInt8] else {
                        Log_("",TAG, "Get sn error!")
                        return
                    }
                    sn = sN
                    guard let cID = userInfo["CID"] as? [UInt8] else {
                        Log_("",TAG, "Get CID error!")
                        return
                    }
                    CID = cID
                }
            }
            queueInfo.sync {
                removeSpinner()
                let getVC = self.ViewController_BLE_infoC
                getVC.modalPresentationStyle = .fullScreen
                getVC.get_HN = Utility.UInt8TOUTF8((Data)(FW))
                getVC.get_FWv = Utility.UInt8TOUTF8((Data)(FWV))
                getVC.get_FWb = Utility.UInt8TOUTF8((Data)(FWB))
                getVC.get_cid = Utility.UInt8TOUTF8((Data)(CID))
                getVC.get_sn = Utility.UInt8TOUTF8((Data)(sn))
                self.present(getVC, animated: true, completion: nil)
                BLEController.shared_.stopScan()
            }
        }else{
            Log_("T",TAG,"Device Back Data is fail\(BaseContext)")
            Stop()
        }
    }
    
    // MARK: TableView Setting
    @objc func UpdateTableview(notifi: Notification){
        DispatchQueue.main.sync{
            table_count = devicelist.count
            table_scanlist.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if (table_count > 0){
            return table_count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TableViewCell_ble_list", for: indexPath) as! TableViewCell_ble_list
        cell.backgroundColor = UIColor.white
        cell.label_ble_name.text = devicelist[indexPath.row].name
        cell.label_ble_name.numberOfLines = 1
        cell.label_ble_name.textAlignment = .center
        cell.label_ble_name.adjustsFontSizeToFitWidth = true
        cell.label_ble_name.font = UIFont(name: "Avenir-Medium", size: 20.0)
        cell.label_ble_mac.text = "CBUUID: " + devicelist[indexPath.row].CBUUID  //.uppercased()
        cell.label_ble_mac.numberOfLines = 1
        cell.label_ble_mac.textAlignment = .center
        cell.label_ble_mac.adjustsFontSizeToFitWidth = true
        cell.label_ble_mac.font = UIFont(name: "Avenir-Heavy", size: 15.0)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        Device_TimeOut = true
        Tag_isLeave    = false
        
        let indexesToRedraw = [indexPath]
        tableView.reloadRows(at: indexesToRedraw, with: .fade)
        
        Log_("",TAG,"selet row : \(indexPath.row), DeviceName : \(devicelist[indexPath.row].name)")
        self.view.makeToast("selet : \(devicelist[indexPath.row].name)", duration: 1.5, position: .bottom)
        select_row = indexPath.row
        
        VNGstatus(UPDATE_STEP._GET_INFO.rawValue)
        BLEController.shared_.ConnectToDevice(indexPath.row)
        
        showSpinner(onView: self.view)
    }
    
    
    var ViewController_BLE_infoC: ViewController_BLE_info {
        let st = UIStoryboard(name: "Main", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "ViewController_BLE_info") as! ViewController_BLE_info
        vc.modalPresentationStyle = .fullScreen
        Log_("", self.TAG, "open ViewController_BLE_info page.")
        return vc
    }
    
    
    //MARK: Button Actives
    @IBAction func button_scan(_ sender: Any) {
        Log_("",TAG, "button scan again")
        
        devicelist = []
        table_count = devicelist.count
        table_scanlist.reloadData()
        BLEController.shared_.startScan()
    }
    
    
}


var vSpinner : UIView?

extension ViewController {
    func showSpinner(onView : UIView) {
        let spinnerView = UIView.init(frame: onView.bounds)
        spinnerView.backgroundColor = UIColor.init(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
        
        var activityIndicator : UIActivityIndicatorView
        if #available(iOS 13.0, *) {
            activityIndicator = UIActivityIndicatorView(style: .large)
            activityIndicator.color = .white // remember to set color

        } else {
            activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
        }
        
        let ai = activityIndicator
        ai.startAnimating()
        ai.center = spinnerView.center
        
        DispatchQueue.main.async {
            spinnerView.addSubview(ai)
            onView.addSubview(spinnerView)
        }
        
        vSpinner = spinnerView
    }
    
    func removeSpinner() {
        DispatchQueue.main.async {
            vSpinner?.removeFromSuperview()
            vSpinner = nil
        }
    }
}

