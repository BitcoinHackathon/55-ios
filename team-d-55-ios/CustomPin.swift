//
//  CustomPin.swift
//  team-d-55-ios
//
//  Created by zizi4n5 on 2018/09/23.
//  Copyright © 2018年 Yenom. All rights reserved.
//

import UIKit
import MapKit

class CustomPin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    
    init(pinTitle:String, pinSubTitle:String, location:CLLocationCoordinate2D) {
        self.title = pinTitle
        self.subtitle = pinSubTitle
        self.coordinate = location
    }
}
