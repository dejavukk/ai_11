//
//  MainFeatureCell.swift
//  ai_11
//
//  Created by JunHyuk on 2017. 12. 7..
//  Copyright © 2017년 com.JunHyuk. All rights reserved.
//

import UIKit

class MainFeatureCell: UITableViewCell {

    @IBOutlet weak var featureImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
