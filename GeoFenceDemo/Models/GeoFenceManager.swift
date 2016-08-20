//
//  GeoFenceManager.swift
//  GeoFenceDemo
//
//  Created by Satoshi Hattori on 2016/08/08.
//  Copyright © 2016年 Satoshi Hattori. All rights reserved.
//

import UIKit
import CoreLocation

let GEO_FENCE_ITEMS_KEY = "geoFenceItems"
let GEO_FENCE_IN_CHECK_REPEAR_COUNT = 10

class GeoFenceManager: NSObject, CLLocationManagerDelegate {

    var geoFenceItems = [GeoFenceItem]()
    
    private let locationManager = CLLocationManager()
    private var stateCheckRepeatCount = 0
    private var stateCheckTargetGeoFenceItem: GeoFenceItem!

    // MARK: - Instance
    
    class var sharedInstance : GeoFenceManager {
        struct Static {
            static let instance = GeoFenceManager()
        }
        return Static.instance
    }
    
    override init() {
        
        super.init()
        
        self.locationManager.delegate = self
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            self.locationManager.requestAlwaysAuthorization()
        }

        self.loadAllGeoFenceItems()
    }
    
    deinit {
        
    }

    // MARK: - Methods
    
    func startMonitoringGeoFenceItem(geoFenceItem: GeoFenceItem) {
        
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            if let viewController = appDelegate.window?.rootViewController {
                Utilities.showSimpleAlertWithTitle("Error", message: "GeoFencing機能はこのデバイスでは使用できません", viewController: viewController)
            }
            return
        }
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            if let viewController = appDelegate.window?.rootViewController {
                Utilities.showSimpleAlertWithTitle("Error", message: "設定画面から位置情報を有効にしてください", viewController: viewController)
            }
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
        
        self.geoFenceItems.append(geoFenceItem)
        
        self.saveAllGeoFenceItems()
    }
    
    func stopMonitoringGeoFenceItem(geoFenceItem: GeoFenceItem) {
        
        for region in self.locationManager.monitoredRegions {
            if region.identifier == geoFenceItem.identifier {
                self.locationManager.stopMonitoringForRegion(region)
            }
        }
        
        if let indexInArray = self.geoFenceItems.indexOf(geoFenceItem) {
            self.geoFenceItems.removeAtIndex(indexInArray)
        }
        
        self.saveAllGeoFenceItems()
    }

    func getGeoFenceItem(identifier: String) -> GeoFenceItem! {
        for i in 0 ..< self.geoFenceItems.count {
            if self.geoFenceItems[i].identifier == identifier {
                return self.geoFenceItems[i]
            }
        }
        return nil
    }

    func handleRegionEvent(manager: CLLocationManager, region: CLRegion!, isIn: Bool) {
        
        if manager.location == nil {
            return
        }
        
        self.stateCheckRepeatCount = 0;
        self.stateCheckTargetGeoFenceItem = nil
        
        let geoFenceItem = self.getGeoFenceItem(region.identifier)
        let isInStr = isIn ? "IN" : "OUT"
        let message = "\(geoFenceItem.note) : \(isInStr)"
        
        if UIApplication.sharedApplication().applicationState == .Active {
            
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            if let viewController = appDelegate.window?.rootViewController {
                Utilities.showSimpleAlertWithTitle(nil, message: message, viewController: viewController)
            }
            
        } else {
            
            let notification = UILocalNotification()
            notification.alertBody = message
            notification.soundName = "Default";
            UIApplication.sharedApplication().presentLocalNotificationNow(notification)
        }
    }

    // MARK: - Loading and saving
    
    func clearAll() {
        
        for region in self.locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                self.locationManager.stopMonitoringForRegion(circularRegion)
            }
        }
        
        self.geoFenceItems = []
        
        NSUserDefaults.standardUserDefaults().setObject([], forKey: GEO_FENCE_ITEMS_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }
    
    func loadAllGeoFenceItems() {
        
        self.geoFenceItems = []
        
        if let savedItems = NSUserDefaults.standardUserDefaults().arrayForKey(GEO_FENCE_ITEMS_KEY) {
            for savedItem in savedItems {
                if let geoFenceItem = NSKeyedUnarchiver.unarchiveObjectWithData(savedItem as! NSData) as? GeoFenceItem {
                    self.geoFenceItems.append(geoFenceItem)
                }
            }
        }
    }
    
    func saveAllGeoFenceItems() {
        
        var items = [NSData]()
        for geoFenceItem in self.geoFenceItems {
            items.append(NSKeyedArchiver.archivedDataWithRootObject(geoFenceItem))
        }
        
        NSUserDefaults.standardUserDefaults().setObject(items, forKey: GEO_FENCE_ITEMS_KEY)
        NSUserDefaults.standardUserDefaults().synchronize()
    }

    // MARK: - Location
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
    }

    func locationManager(manager: CLLocationManager, didStartMonitoringForRegion region: CLRegion) {

        NSLog("%@, %d: %@", #function, #line, region.identifier)
        
        if region.notifyOnEntry == false {
            return
        }
        
        // 既に領域内にいる場合、即時に検知されない場合があるため一定間隔で状態確認: リピート回数指定
        self.stateCheckRepeatCount = GEO_FENCE_IN_CHECK_REPEAR_COUNT
        
        if let geoFenceItem = self.getGeoFenceItem(region.identifier) {
            self.stateCheckTargetGeoFenceItem = geoFenceItem
            self.locationManager.requestStateForRegion(region)
        }
    }

    func locationManager(manager: CLLocationManager, didEnterRegion region: CLRegion) {
        
        NSLog("%@, %d: %@", #function, #line, region.identifier)
        
        if region is CLCircularRegion {
            self.handleRegionEvent(manager, region: region, isIn: true)
        }
    }

    func locationManager(manager: CLLocationManager, didExitRegion region: CLRegion) {

        NSLog("%@, %d: %@", #function, #line, region.identifier)
        
        if region is CLCircularRegion {
            self.handleRegionEvent(manager, region: region, isIn: false)
        }
    }

    func locationManager(manager: CLLocationManager, didDetermineState state: CLRegionState, forRegion region: CLRegion) {
        
        NSLog("%@, %d: %@ / state:%d", #function, #line, region.identifier, state.rawValue)
        
        switch state {
        case .Inside:
            
            if region is CLCircularRegion {
                if let stateCheckGeoFenceItem = self.stateCheckTargetGeoFenceItem {
                    if stateCheckGeoFenceItem.identifier == region.identifier {
                        self.handleRegionEvent(manager, region: region, isIn: true)
                    }
                }
            }
            
            break

        case .Outside:
            
            if self.stateCheckTargetGeoFenceItem == nil {
                self.stateCheckRepeatCount = 0
            }
            
            break

        default:
            
            print("count:\(self.stateCheckRepeatCount)")
            
            if self.stateCheckRepeatCount > 0 {
                self.stateCheckRepeatCount -= 1
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    self.locationManager.requestStateForRegion(region)
                })
            } else {
                if let stateCheckTargetGeoFenceItem = self.stateCheckTargetGeoFenceItem {
                    self.stopMonitoringGeoFenceItem(stateCheckTargetGeoFenceItem)
                    self.stateCheckTargetGeoFenceItem = nil
                }
            }
            
            break
        }
    }

    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        
        NSLog("%@, %d: %@", #function, #line, region != nil ? region!.identifier : "region is nil")

        let notification = UILocalNotification()
        notification.alertBody = "登録失敗: 再登録してください"
        notification.soundName = "Default";
        UIApplication.sharedApplication().presentLocalNotificationNow(notification)
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        NSLog("%@, %d: %@", #function, #line, error)
    }
    
    // MARK: - Utility

    func getRadius(radius: Double) -> CLLocationDistance {
        return (radius > self.locationManager.maximumRegionMonitoringDistance) ? self.locationManager.maximumRegionMonitoringDistance : radius
    }

}
