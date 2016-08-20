//
//  MapViewController.swift
//  GeoFenceDemo
//
//  Created by Satoshi Hattori on 2016/08/08.
//  Copyright © 2016年 Satoshi Hattori. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, AddViewControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var addBtn: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.refresh()
    }

    // MARK: - Action
    
    @IBAction func addBtn_action(sender: AnyObject) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let vc = storyboard.instantiateViewControllerWithIdentifier("AddViewController") as! AddViewController
        vc.delegate = self
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func currentLocationBtn_action(sender: AnyObject) {
        Utilities.zoomToUserLocationInMapView(mapView, distance: 2000)
    }
    
    @IBAction func refreshBtn_action(sender: AnyObject) {
        if self.mapView.mapType == MKMapType.HybridFlyover {
            self.mapView.mapType = MKMapType.Standard
        } else if self.mapView.mapType == MKMapType.Standard {
            self.mapView.mapType = MKMapType.HybridFlyover
        }
    }
    
    // MARK: - Refresh

    func refresh() {
        
        self.mapView.removeAnnotations(self.mapView.annotations)
        self.removeAllRadiusOverlayForGeoFenceItem()
        
        for geoFenceItem in GeoFenceManager.sharedInstance.geoFenceItems {
            self.mapView.addAnnotation(geoFenceItem)
            self.addRadiusOverlayForGeoFenceItem(geoFenceItem)
        }
        
        self.updateGeoFenceItemsCount()
    }

    func updateGeoFenceItemsCount() {
        title = "GeoFence Demo (\(GeoFenceManager.sharedInstance.geoFenceItems.count))"
        self.addBtn.enabled = (GeoFenceManager.sharedInstance.geoFenceItems.count < 20)
    }

    // MARK: - AddViewControllerDelegate
    
    func addViewController(controller: AddViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        
        self.navigationController?.popViewControllerAnimated(true)
        
        let clampedRadius = GeoFenceManager.sharedInstance.getRadius(radius)
        let geoFenceItem = GeoFenceItem(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
        
        GeoFenceManager.sharedInstance.startMonitoringGeoFenceItem(geoFenceItem)
        
        self.mapView.addAnnotation(geoFenceItem)
        self.addRadiusOverlayForGeoFenceItem(geoFenceItem)
        self.updateGeoFenceItemsCount()
    }

    // MARK: - MKMapViewDelegate
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let identifier = "geoFenceItem"
        if annotation is GeoFenceItem {
            var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView
            if annotationView == nil {
                annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
                let removeButton = UIButton(type: .Custom)
                removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
                removeButton.setImage(UIImage(named: "DeleteGeoFenceItem")!, forState: .Normal)
                annotationView?.leftCalloutAccessoryView = removeButton
            } else {
                annotationView?.annotation = annotation
            }
            return annotationView
        }
        return nil
    }
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        circleRenderer.lineWidth = 1.0
        circleRenderer.strokeColor = UIColor.purpleColor()
        circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
        return circleRenderer
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        
        let geoFenceItem = view.annotation as! GeoFenceItem
        GeoFenceManager.sharedInstance.stopMonitoringGeoFenceItem(geoFenceItem)
        
        self.mapView.removeAnnotation(geoFenceItem)
        self.removeRadiusOverlayForGeoFenceItem(geoFenceItem)
        self.updateGeoFenceItemsCount()
    }
    
    // MARK: - Map methods
    
    func addRadiusOverlayForGeoFenceItem(geoFenceItem: GeoFenceItem) {
        self.mapView?.addOverlay(MKCircle(centerCoordinate: geoFenceItem.coordinate, radius: geoFenceItem.radius))
    }
    
    func removeRadiusOverlayForGeoFenceItem(geoFenceItem: GeoFenceItem) {
        
        if let overlays = mapView?.overlays {
            for overlay in overlays {
                if let circleOverlay = overlay as? MKCircle {
                    let coord = circleOverlay.coordinate
                    if coord.latitude == geoFenceItem.coordinate.latitude && coord.longitude == geoFenceItem.coordinate.longitude && circleOverlay.radius == geoFenceItem.radius {
                        mapView?.removeOverlay(circleOverlay)
                        break
                    }
                }
            }
        }
    }

    func removeAllRadiusOverlayForGeoFenceItem() {
        if let overlays = mapView?.overlays {
            for overlay in overlays {
                if let circleOverlay = overlay as? MKCircle {
                    mapView?.removeOverlay(circleOverlay)
                }
            }
        }
    }

}
