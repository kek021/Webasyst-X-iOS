//
//  PhotosViewCell.swift
//  Webasyst X
//
//  Created by Aleksandr Zhukov on 19.09.2022.
//

import UIKit
import Webasyst

class PhotosViewCell: UITableViewCell {

    static var identifier = "photosCell"
    
    @IBOutlet weak var photoImageView: UIImageView!
    var photos: Photos?
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configure(photosData: Photos) {
        self.photos = photosData
        self.photoImageView.contentMode = .scaleAspectFill
        self.photoImageView.image = UIImage(named: "emptyImage")
        let selectDomain = UserDefaults.standard
            .string(forKey: "selectDomainUser") ?? ""
        let install = WebasystApp().getUserInstall(selectDomain)
        NetworkingManager().downloadImage(
            "\(install?.url ?? "")\(photosData.image_url)"
        ) { [weak self] image in
            self?.photoImageView.image = UIImage(data: image)
        }
    }
}
