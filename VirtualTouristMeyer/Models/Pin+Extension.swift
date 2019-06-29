//
//  Pin+Extension.swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/25/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import Foundation
import MapKit

extension Pin: MKAnnotation {
    public var coordinate: CLLocationCoordinate2D {
        let latDegrees = CLLocationDegrees(latitude)
        let longDegrees = CLLocationDegrees(longitude)
        return CLLocationCoordinate2D(latitude: latDegrees, longitude: longDegrees)
    }
}
