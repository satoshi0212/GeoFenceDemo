//
//  Utilities.swift
//  GeoFenceDemo
//
//  Created by Satoshi Hattori on 2016/08/08.
//  Copyright © 2016年 Satoshi Hattori. All rights reserved.
//

import UIKit
import MapKit

class Utilities: NSObject {

    class func showSimpleAlertWithTitle(title: String!, message: String, viewController: UIViewController) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Cancel, handler: nil)
        alert.addAction(action)
        viewController.presentViewController(alert, animated: true, completion: nil)
    }
    
    class func zoomToUserLocationInMapView(mapView: MKMapView, distance: Double) {
        if let coordinate = mapView.userLocation.location?.coordinate {
            let region = MKCoordinateRegionMakeWithDistance(coordinate, distance, distance)
            mapView.setRegion(region, animated: true)
        }
    }
    
}