//
//  TableViewCell_ble_list.swift
//  BLEupdataTool
//
//  Created by debbie_wu on 2023/3/29.
//

import UIKit

class TableViewCell_ble_list: UITableViewCell {
    
    
    @IBOutlet weak var label_ble_name: UILabel!
    @IBOutlet weak var label_ble_mac: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
