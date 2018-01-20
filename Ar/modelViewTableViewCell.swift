//
//  modelViewTableViewCell.swift
//  Ar
//
//  Created by Julien Lemonde on 18-01-19.
//  Copyright © 2018 Julien Lemonde. All rights reserved.
//

import UIKit

class modelViewTableViewCell: UITableViewCell {


    @IBOutlet weak var myLabel: UILabel!
    @IBOutlet weak var myImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
