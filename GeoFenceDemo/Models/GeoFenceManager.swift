//
//  GeoFenceManager.swift
//  GeoFenceDemo
//
//  Created by Satoshi Hattori on 2016/08/08.
//  Copyright © 2016年 Satoshi Hattori. All rights reserved.
//

import UIKit
import CoreLocation
//import SVProgressHUD

let GEO_FENCE_ITEMS_KEY = "geoFenceItems"

class GeoFenceManager: NSObject, CLLocationManagerDelegate {

    var geoFenceItems = [GeoFenceItem]()
    private var locationManager: CLLocationManager
    private var stateCheckRepeatCount = 0
    
    class var sharedInstance : GeoFenceManager {
        struct Static {
            static let instance = GeoFenceManager()
        }
        return Static.instance
    }
    
    override init() {
        
        self.locationManager = CLLocationManager()
        
        super.init()
        
        self.locationManager.delegate = self
        self.locationManager.requestAlwaysAuthorization()
        self.loadAllGeoFenceItems()
    }
    
    deinit {
        
    }

    // MARK: - Methods
    
    func startMonitoringGeoFenceItem(vc: UIViewController, geoFenceItem: GeoFenceItem) {
        
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            Utilities.showSimpleAlertWithTitle("Error", message: "GeoFencing is not supported on this device", viewController: vc)
            return
        }
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            Utilities.showSimpleAlertWithTitle("Error", message: "You need to grant access the device location.", viewController: vc)
            return
        }
        
        let region = CLCircularRegion(center: geoFenceItem.coordinate, radius: geoFenceItem.radius, identifier: geoFenceItem.identifier)
        
        switch geoFenceItem.eventType {
        case .OnEntry:
            region.notifyOnEntry = true
            region.notifyOnExit = false
        case .OnExit:
            region.notifyOnEntry = false
            region.notifyOnExit = true
        }

        self.locationManager.startMonitoringForRegion(region)
        self.addGeoFenceItem(geoFenceItem)
        self.saveAllGeoFenceItems()
    }
    
    func stopMonitoringGeoFenceItem(geoFenceItem: GeoFenceItem) {
        for region in self.locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                if circularRegion.identifier == geoFenceItem.identifier {
                    self.locationManager.stopMonitoringForRegion(circularRegion)
                }
            }
        }
        
        self.removeGeoFenceItem(geoFenceItem)
        self.saveAllGeoFenceItems()
    }

    func stopMonitoringGeoFenceItemAll() {
        for region in self.locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                self.locationManager.stopMonitoringForRegion(circularRegion)
            }
        }
        
        self.clearAllGeoFenceItems()
    }

    func addGeoFenceItem(geoFenceItem: GeoFenceItem) {
        self.geoFenceItems.append(geoFenceItem)
    }
    
    func removeGeoFenceItem(geoFenceItem: GeoFenceItem) {
        if let indexInArray = geoFenceItems.indexOf(geoFenceItem) {
            self.geoFenceItems.removeAtIndex(indexInArray)
        }
    }

    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
        
        let notification = UILocalNotification()
        notification.alertBody = "登録失敗: 再登録してください"
        notification.soundName = "Default";
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Manager failed with the following error: \(error)")
        
    }

    func getGeoFenceItem(identifier: String) -> GeoFenceItem! {
        for i in 0 ..< self.geoFenceItems.count {
            if self.geoFenceItems[i].identifier == identifier {
                return self.geoFenceItems[i]
            }
        }
        return nil
    }

    // MARK: - Loading and saving functions
    
    func loadAllGeoFenceItems() {
        self.geoFenceItems = []
        
        if let savedItems = NSUserDefaults.standardUserDefaults().arrayForKey(GEO_FENCE_ITEMS_KEY) {
            for savedItem in savedItems {
                if let geoFenceItem = NSKeyedUnarchiver.unarchiveObjectWithData(savedItem as! NSData) as? GeoFenceItem {
                    self.addGeoFenceItem(geoFenceItem)
                }
            }
        }
    }
    
    func saveAllGeoFenceItems() {
        let items = NSMutableArray()
        for geoFenceItem in self.geoFenceItems {
            let item = NSKeyedArchiver.archivedDataWithRootObject(geoFenceItem)
            items.addObject(item)
        }
        
        NSUserDefaults.standardUserDefaults().setObject(items, forKey: GEO_FENCE_ITEMS_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    func clearAllGeoFenceItems() {
        
        self.geoFenceItems = []
        
        NSUserDefaults.standardUserDefaults().setObject([], forKey: GEO_FENCE_ITEMS_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // MARK: - Location
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
    }

    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {

        // 既に領域内にいる場合、即時に検知されない場合があるため一定間隔で状態確認
        self.stateCheckRepeatCount = 10

//        //SVProgressHUD.showWithMaskType(SVProgressHUDMaskType.Black)
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
            self.locationManager.requestStateForRegion(region)
//            //SVProgressHUD.dismiss()
        })
    }
    
    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {
        if region is CLCircularRegion {
            handleRegionEvent(manager, region: region, isIn: false)
        }
    }

    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        
        print("state:", state.rawValue)
        
        switch state {
        case .Inside:
            if region is CLCircularRegion {
                self.handleRegionEvent(manager, region: region, isIn: true)
            }
            break

        case .Outside:
            self.stateCheckRepeatCount = 0
            break

        default:
            if self.stateCheckRepeatCount > 0 {
                print("count:\(self.stateCheckRepeatCount)")
                self.stateCheckRepeatCount -= 1
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self.locationManager.requestStateForRegion(region)
                })
            }
            break
        }
    }

    func handleRegionEvent(manager: CLLocationManager, region: CLRegion!, isIn: Bool) {
 
        if manager.location == nil {
            return
        }
        
        self.stateCheckRepeatCount = 0;

        let geoFenceItem = self.getGeoFenceItem(region.identifier)
        
        let isInStr = isIn ? "IN" : "OUT"
        let note = geoFenceItem.note
        
        let message = "\(note) : \(isInStr)"
        
        if UIApplication.sharedApplication().applicationState == .Active {
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            
            if let viewController = appDelegate.window?.rootViewController {
                NSLog("■ showSimpleAlertWithTitle(nil, message: str, viewController: viewController)")
                Utilities.showSimpleAlertWithTitle(nil, message: message, viewController: viewController)
            }
        } else {
            
            NSLog("■ UIApplication.sharedApplication().presentLocalNotificationNow(notification)")
            
            let notification = UILocalNotification()
            notification.alertBody = message
            notification.soundName = "Default";
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }

    // MARK: - Utility

    func getRadius(radius: Double) -> CLLocationDistance {
        return (radius > self.locationManager.maximumRegionMonitoringDistance) ? self.locationManager.maximumRegionMonitoringDistance : radius
    }

}
