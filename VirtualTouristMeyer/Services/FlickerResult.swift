//
//  FlickerResult.swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/25/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import Foundation

struct FlickerResult: Decodable {
    let photos: RemotePhotos
    let stat: String
}
