//
//  ViewController_BLE_info.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/3/30.
//

import UIKit

class ViewController_BLE_info: UIViewController {

    let TAG = "VC_BLE"
    
    public static let share_vc_ = ViewController_BLE_info()
    
    @IBOutlet weak var label_HN         : UILabel!
    @IBOutlet weak var label_FW_version : UILabel!
    @IBOutlet weak var label_FW_Build   : UILabel!
    @IBOutlet weak var label_CID        : UILabel!
    @IBOutlet weak var label_serial     : UILabel!
    
    @IBOutlet weak var but_start     : UIButton!
    @IBOutlet weak var but_back      : UIButton!
    //@IBOutlet weak var but_log       : UIButton!
    
    @IBOutlet weak var progressline  : UIProgressView!
    @IBOutlet weak var progressState : UILabel!
    @IBOutlet weak var Log_show      : UITextView!
    var Log_Word = ""

    var get_HN  = ""
    var get_FWv = ""
    var get_FWb = ""
    var get_cid = ""
    var get_sn  = ""
    
    // on UIProgressView
    var _FileAllSize     = 0
    var _FileProcessSize = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        
        label_HN.text         = get_HN
        label_FW_version.text = get_FWv
        label_FW_Build.text   = get_FWb
        label_CID.text        = get_cid
        label_serial.text     = get_sn
        
        progressline.transform   = CGAffineTransformMakeScale(1, 5)  //注意看之後會不會有問題!
        
        Log_show.isScrollEnabled = true
        Log_show.isEditable      = false
        Log_show.isSelectable    = false
        Log_show.font = UIFont(name: "Helvetica-Blod", size: 14)
        
        
        // TextView Update
        NotificationCenter.default.addObserver(self, selector: #selector(UpdateTextView), name: .UpdateTextView, object: nil)
        // TextView Update show dot of working
        NotificationCenter.default.addObserver(self, selector: #selector(UpdateTextViewD), name: .UpdateTextViewD, object: nil)
        // Update File Number of Working
        NotificationCenter.default.addObserver(self, selector: #selector(UpdateNumber), name: .UpdateNumber, object: nil)
        // Start target send_TX/receive_RX state
        NotificationCenter.default.addObserver(self, selector: #selector(scheduledTimer), name: .scheduledTimer, object: nil)
        // Final Step
        NotificationCenter.default.addObserver(self, selector: #selector(FinalStep), name: .FinalStep, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(GetInfo_two), name: .GetInfo_two, object: nil)
        // Stop Work
        NotificationCenter.default.addObserver(self, selector: #selector(StopWrok), name: .StopWrok, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.progressState.text  = "- / \(VngService.FileList.count)"
        self.addDataOnTextView("MCR is Connected.")
//
        self._FileAllSize = VngService.VngSer.culcFile()
        Log_("", self.TAG, "The UIProgressView length is : \(self._FileAllSize)")
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
        Log_("", TAG, "viewWillDisappear, close page.")
        
        Stop()
        Utility.writeMore("", false)
        timer.invalidate()
    }
    
    @objc func scheduledTimer(notify: Notification){
        // check work status, if device not back will call BLEcontroller.openRead_character()
        timer = Timer.scheduledTimer(timeInterval: TimeOut_s, target: self, selector: #selector(timerTarget), userInfo: nil, repeats: true)
    }
    
    @objc func timerTarget(){
        //print("flowCount :\(flowCount), lastflowstate :\(lastflowstate), nowflowstate :\(nowflowstate)")   // test USE
        if(flowCount == 0){
            flowCount += 1
            lastflowstate = nowflowstate
        }else{
            // 只為了取得狀態 : 只拿到06 卻沒拿到 作業結果
            if(lastflowstate == nowflowstate && lastflowstate == 2){  // 2:等待回傳
                flowCount += 1
                if(flowCount == 2){
                    Log_("", TAG, "Device not responding, check state.")
                    BLEController.shared_.openRead_character()
                }else if(flowCount == 3){
                    Log_("T", TAG, "Device not responding, please contact the repair center.")
                    Stop()
                }
            }else{
                lastflowstate = nowflowstate
                flowCount = 1
            }
        }
    }
    
    @objc func StopWrok(notify: Notification){
        //只有在未作業前，才提供按鈕可以按，如確認作業結束了，則不提供回去前頁繼續作業。
        //DispatchQueue.main.async {
        //    self.but_back.isEnabled  = true
        //}
        Device_TimeOut = false
    }
    
    @objc func UpdateTextView(notify: Notification){
        //Log_("",TAG,"Notification UpdateTextView()")
        if (notify.userInfo != nil){
            var NewLine = ""
            
            if let userInfo = notify.userInfo! as? [String : AnyObject] {
                guard let nLine = userInfo["nLine"] as? String else {
                    Log_("",TAG, "Get nLine error!")
                    return
                }
                NewLine = nLine
            }
            addDataOnTextView(NewLine)
        }else{
            Log_("",TAG,"Notification UpdateTextView nil.")
        }
    }
    
    @objc func UpdateNumber(notify: Notification){
        //Log_("",TAG,"Notification UpdateFileList()")
        DispatchQueue.main.async {
            self.progressState.text = "\(VngService.FileCount+1) / \(VngService.FileList.count)"
            
            self._FileProcessSize += VngService.BlockCount
            self.progressline.progress = Float(Double(self._FileProcessSize)/Double(self._FileAllSize))
            //Log_("",self.TAG,"ProcessView: \(self._FileProcessSize)/\(self._FileAllSize) = \(Float(Double(self._FileProcessSize)/Double(self._FileAllSize)))")
        }
    }
    
    @objc func GetInfo_two(notify: Notification){
        //Log_("",TAG,"Notification GetInfo_two()")
        if (notify.userInfo != nil){
            let queueInfo = DispatchQueue.main
            queueInfo.sync {
                if let userInfo = notify.userInfo! as? [String : AnyObject] {
                    
                    guard let fW = userInfo["FW"] as? [UInt8] else {
                        Log_("",TAG, "Get FW error!")
                        return
                    }
                    label_HN.text = Utility.UInt8TOUTF8((Data)(fW))
                    
                    guard let fWV = userInfo["FWV"] as? [UInt8] else {
                        Log_("",TAG, "Get FWV error!")
                        return
                    }
                    label_FW_version.text = Utility.UInt8TOUTF8((Data)(fWV))
                    
                    guard let fWB = userInfo["FWB"] as? [UInt8] else {
                        Log_("",TAG, "Get FWB error!")
                        return
                    }
                    label_FW_Build.text = Utility.UInt8TOUTF8((Data)(fWB))
                    
                    guard let sN = userInfo["sn"] as? [UInt8] else {
                        Log_("",TAG, "Get sn error!")
                        return
                    }
                    label_serial.text = Utility.UInt8TOUTF8((Data)(sN))
                    
                    guard let cID = userInfo["CID"] as? [UInt8] else {
                        Log_("",TAG, "Get CID error!")
                        return
                    }
                    label_CID.text = Utility.UInt8TOUTF8((Data)(cID))
                }
                Log_("T", TAG, "Update was finished. \nPlease close the AP.")
                VngService.State_open = false
                Stop()
                
                
                // forloop test!!
                /*
                Log_("T",TAG,"button Start")
                self.addDataOnTextView("")
                LogStrFile = ""

                VngService.FileCount = 0
                VngService.FileData  = []

                Tag_x72state   = true
                process = 0

                sleep(2)
                vngStatus = UPDATE_STEP._JUMP_LOADER.rawValue
                VngService.VngSer.DoCommand([],UInt32(0))
                //sleep(1)
                //Utility.writeMore("", false)
                //timer.invalidate()
                flowCount = 0
                 */
            }
            
        }else{
            Log_("T",TAG,"Device Back Data is fail\(BaseContext)")
            Stop()
        }
    }
    
    @objc func FinalStep(notify: Notification){
        Log_("",TAG,"Notification FinalStep()")
        nowflowstate = 3
        
        DispatchQueue.global().async {
            sleep(DT_WaitReConnect)
            Tag_FinalStep = false
            Device_TimeOut = true
            DispatchQueue.main.async {
                VNGstatus(UPDATE_STEP._GET_INFO.rawValue)
                BLEController.shared_.reConnectToDevice()
                //self.but_log.isEnabled = true
            }
        }
    }
    
    var dot_count = 0
    @objc func UpdateTextViewD(notify: Notification){
        dot_count += 1
        DispatchQueue.main.async {
            if (vngStatus == UPDATE_STEP._WRITE_BLOCK.rawValue){
                if (self.dot_count != 40){
                    self.Log_Word += " ."
                    self.Log_show.text = self.Log_Word
                }else{
                    self.dot_count = 0
                    self.Log_Word += " .\n"
                    self.Log_show.text = self.Log_Word
                    let point = CGPoint(x: 0.0, y: (self.Log_show.contentSize.height - self.Log_show.bounds.height))
                    self.Log_show.setContentOffset(point, animated: false)
                }
            }else{
                self.dot_count = 0
            }
        }
    }
    
    public func addDataOnTextView(_ Str:String){
        DispatchQueue.main.async {
            self.Log_Word += Str + "\n"
            self.Log_show.text = self.Log_Word
            
            let point = CGPoint(x: 0.0, y: (self.Log_show.contentSize.height - self.Log_show.bounds.height))
            self.Log_show.setContentOffset(point, animated: false)
        }
    }
    
    // MARK: Button
    @IBAction func button_back(_ sender: Any) {
        Log_("T",TAG,"button Back")
        
        let alertController = UIAlertController(title: "Disconnected Device", message: "Do you want to disconnected device?", preferredStyle: .alert)
        let yesAction = UIAlertAction(
            title: "YES",
            style: .default,
            handler: {
            (action: UIAlertAction!) -> Void in
                Log_("T",self.TAG, "button Yes")
                self.dismiss(animated: true, completion: nil)
                
                self.addDataOnTextView("")
                VngService.FileCount = 0
                VngService.FileData  = []
                
                Tag_FirstStep  = false
                Tag_isLeave    = true
                Tag_x72state   = true
                
                //self.but_log.isEnabled = false
                self.but_start.isEnabled  = true
                LogStrFile = ""
                
                sleep(UInt32(0.2))
                BLEController.shared_.unpair()
                
                self.dismiss(animated: true, completion: nil)
        })
        alertController.addAction(yesAction)
        let cancelAction = UIAlertAction(
            title: "CANCEL",
            style: .cancel,
            handler: {
            (action: UIAlertAction!) -> Void in
                Log_("T",self.TAG, "button Cancel")
        })
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }
    
    @IBAction func button_start(_ sender: Any) {
        Log_("T",TAG,"button Start")
        
        Log_("T", TAG, "Log : ../LogStore/\(URL(string:LogPath)!.lastPathComponent)\n")
        
        but_start.isEnabled  = false
        but_back.isEnabled   = false
        
        if(vngStatus == UPDATE_STEP._JUMP_LOADER.rawValue) {
            VngService.VngSer.DoCommand([],UInt32(0))
        }else{
            Log_("", TAG, "vngStatus is not _JUMP_LOADER")
        }
        NotificationCenter.default.post(name: .scheduledTimer, object: nil, userInfo: nil)
    }
    
//    @IBAction func button_log(_ sender: Any) {
//        Log_("T",TAG,"button Log")
//
//        LogStrFile = Utility.readFile()
//
//        let getVC = self.ViewController_Log_infoC
//        getVC.modalPresentationStyle = .fullScreen
//        getVC.Log = LogStrFile
//        self.present(getVC, animated: true, completion: nil)
//    }
//
//    var ViewController_Log_infoC: ViewController_Log {
//        let st = storyboard!.instantiateViewController(withIdentifier: "ViewController_Log") as! ViewController_Log
//        st.modalPresentationStyle = .fullScreen
//        return st
//    }
}
