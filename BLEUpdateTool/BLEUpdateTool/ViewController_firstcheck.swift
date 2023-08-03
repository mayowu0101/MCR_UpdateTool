//
//  ViewController_firstcheck.swift
//  BLEUpdateTool
//
//  Created by debbie_wu on 2023/7/27.
//

import UIKit

class ViewController_firstcheck: UIViewController {

    let TAG = "VC_FirstCheck"
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Create Log Folder Path
        var Log_fileName = URL(string:"")
        do {
            let documentsFolder = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
            Log_fileName = documentsFolder.appendingPathComponent("LogStore")
        } catch {
            print(error)
        }
        
        if (!Utility.directoryIsExists(path: Log_fileName!.path)){
            if (Utility.createfile(Log_fileName!.path)){
                //Log_("", TAG, "[File] Create LogStore success.")
                print("[File] Create LogStore success.")
            } else{
                //Log_("", TAG, "[File] Create LogStore fail.")
                print("[File] Create LogStore fail.")
            }
        }else{
            //Log_("", TAG, "[File] LogStore folder exist.")
            print("[File] LogStore folder exist.")
        }
        
        // ADD Log File
        LogPath = Log_fileName!.appendingPathComponent("\(Log_times)_Log.txt").path
        
        Utility.writeTofile(LogStrFile)
        
        Log_("", TAG, "iOSBLEUpdateTool v1.0.0")
        UIApplication.shared.isIdleTimerDisabled = true
    }
    

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let FolderPath = "\(Log_documentsDirectory)/assets/"
        if (!Utility.directoryIsExists(path: FolderPath)){
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "WRONG", message: "MCR OS Path is not exist.\nPlease check folder name is \"assets\".", preferredStyle: .alert)
                let Action = UIAlertAction(title: "Close APP", style: .default, handler: {
                    (action: UIAlertAction!) -> Void in
                    Log_("",self.TAG, "button Close APP")
                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                    
                })
                alertController.addAction(Action)
                self.present(alertController, animated: true)
            }
        }else{
            //Log_("",self.TAG,"Update Folder Exist")
            
            let getBundleList = VngService.VngSer.BundleList()
            if (getBundleList.count != 0){
                VngService.FileList = getBundleList
                
                DispatchQueue.main.async {
                    let getVC = self.VC
                    self.present(getVC, animated: true, completion: nil)
                }
            }else{
                Log_("", self.TAG, "Read update file is fail\(BaseContext).")
            }
            
        }
        
    }
    
    var VC: ViewController {
        let st = UIStoryboard(name: "Main", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        vc.modalPresentationStyle = .fullScreen
        Log_("", self.TAG, "open ViewController page.")
        return vc
    }

}
