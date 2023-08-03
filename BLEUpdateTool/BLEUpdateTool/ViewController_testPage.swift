//
//  ViewController_testPage.swift
//  BLEUpdateTool
//
//  Created by debbie_wu on 2023/7/25.
//

import UIKit

class ViewController_testPage: UIViewController {

    let TAG = "[test]"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let FolderPath = "\(Log_documentsDirectory)/assets/"
        if (!Utility.directoryIsExists(path: FolderPath)){
            DispatchQueue.main.async {
                let alertController = UIAlertController(title: "WRONG", message: "MCR OS Path is not exist.\nPlease check folder name is \"assets\".", preferredStyle: .alert)
                let Action = UIAlertAction(title: "Close APP", style: .default, handler: {
                    (action: UIAlertAction!) -> Void in
                    print("button Close APP")
                    //Log_("T",self.TAG, "button Close APP")
                    //exit(0)
                    UIApplication.shared.perform(#selector(NSXPCConnection.suspend))
                    
                })
                alertController.addAction(Action)
                self.present(alertController, animated: true)
            }
        }else{
            print("Update Folder Exist")
            //Log_("",self.TAG,"Update Folder Exist")
            
            if (VngService.VngSer.BundleList().count != 0){
                VngService.FileList = VngService.VngSer.BundleList()
                self.view.makeToast("OS version is not 13.0 above.", duration: 1.5, position: .bottom)
            }else{
                print("Read update file is fail\(BaseContext)")
                //Log_("T", self.TAG, "Read update file is fail\(BaseContext)")
            }
            
            DispatchQueue.main.async {
                let getVC = self.VC
                self.present(getVC, animated: true, completion: nil)
            }
        }
        
    }
    
    var VC: ViewController {
        let st = UIStoryboard(name: "Main", bundle: nil)
        let vc = st.instantiateViewController(withIdentifier: "ViewController") as! ViewController
        vc.modalPresentationStyle = .fullScreen
        return vc
    }

}
