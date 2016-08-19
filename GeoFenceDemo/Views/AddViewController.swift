//
//  AddViewController.swift
//  GeoFenceDemo
//
//  Created by Satoshi Hattori on 2016/08/08.
//  Copyright © 2016年 Satoshi Hattori. All rights reserved.
//

import UIKit
import MapKit

protocol AddViewControllerDelegate {
    func addViewController(controller: AddViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType)
}

class AddViewController: UITableViewController, UITextFieldDelegate {
    
    @IBOutlet var addButton: UIBarButtonItem!
    
    @IBOutlet weak var eventTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var radiusTextField: UITextField!
    @IBOutlet weak var noteTextField: UITextField!
    @IBOutlet weak var mapView: MKMapView!
    
    var delegate: AddViewControllerDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.addButton.enabled = false
        
        self.tableView.tableFooterView = UIView()
        
        self.radiusTextField.delegate = self
        self.noteTextField.delegate = self
    }
    
    // MARK: - Action
    
    @IBAction func textFieldEditingChanged(sender: UITextField) {
        self.addButton.enabled = !self.radiusTextField.text!.isEmpty && !self.noteTextField.text!.isEmpty
    }
    
    @IBAction func onCancel(sender: AnyObject) {
        self.navigationController?.popViewControllerAnimated(true)
    }
    
    @IBAction private func onAdd(sender: AnyObject) {
        let coordinate = mapView.centerCoordinate
        let radius = (radiusTextField.text! as NSString).doubleValue
        let identifier = NSUUID().UUIDString
        let note = noteTextField.text!
        let eventType = (eventTypeSegmentedControl.selectedSegmentIndex == 0) ? EventType.OnEntry : EventType.OnExit
        self.delegate!.addViewController(self, didAddCoordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: eventType)
    }
    
    @IBAction private func onZoomToCurrentLocation(sender: AnyObject) {
        Utilities.zoomToUserLocationInMapView(mapView, distance: 2000)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
}
