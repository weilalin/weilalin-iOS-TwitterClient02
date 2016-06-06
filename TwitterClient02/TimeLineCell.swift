//
//  TimeLineCell.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/02.
//  Copyright © 2016年 mycompany. All rights reserved.
//

import UIKit

class TimeLineCell: UITableViewCell {

    @IBOutlet weak var profileImageView : UIImageView!
    @IBOutlet weak var nameLabel : UILabel!
    @IBOutlet weak var tweetTextLabel : UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
