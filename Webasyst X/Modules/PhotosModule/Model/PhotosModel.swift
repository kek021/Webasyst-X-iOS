//
//  PhotosModel.swift
//  Webasyst X
//
//  Created by Aleksandr Zhukov on 19.09.2022.
//

import Foundation

struct PhotosList: Decodable {
    var photos: [Photos]?
}

struct Photos: Decodable {
    var image_url: String
}
