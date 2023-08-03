//
//  ViewController_Log.swift
//  BLEUpdateTool
//
//  Created by debbie_wu on 2023/7/5.
//

import UIKit

class ViewController_Log: UIViewController {

    @IBOutlet weak var Text_Log: UITextView!

    var Log = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true

        Text_Log.text = ""
        Text_Log.isScrollEnabled = true
        Text_Log.isEditable      = false
        Text_Log.isSelectable    = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        Text_Log.text = Log
    }
    
    @IBAction func but_backpage(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func but_copy(_ sender: Any) {
        UIPasteboard.general.string = Text_Log.text
        
    }
    
}
