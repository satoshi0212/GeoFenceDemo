//
//  GeoFenceItem.swift
//  GeoFenceDemo
//
//  Created by Satoshi Hattori on 2016/08/08.
//  Copyright © 2016年 Satoshi Hattori. All rights reserved.
//

import MapKit
import CoreLocation

let GEO_FENCE_ITEM_LatitudeKey = "latitude"
let GEO_FENCE_ITEM_LongitudeKey = "longitude"
let GEO_FENCE_ITEM_RadiusKey = "radius"
let GEO_FENCE_ITEM_IdentifierKey = "identifier"
let GEO_FENCE_ITEM_NoteKey = "note"
let GEO_FENCE_ITEM_EventTypeKey = "eventType"

enum EventType: Int {
    case OnEntry = 0
    case OnExit
}

class GeoFenceItem: NSObject, NSCoding, MKAnnotation {
    
    var coordinate: CLLocationCoordinate2D
    var radius: CLLocationDistance
    var identifier: String
    var note: String
    var eventType: EventType
    
    var title: String? {
        if note.isEmpty {
            return "No Note"
        }
        return note
    }
    
    var subtitle: String? {
        let eventTypeString = eventType == .OnEntry ? "On Entry" : "On Exit"
        return "Radius: \(radius)m - \(eventTypeString)"
    }
    
    init(coordinate: CLLocationCoordinate2D, radius: CLLocationDistance, identifier: String, note: String, eventType: EventType) {
        self.coordinate = coordinate
        self.radius = radius
        self.identifier = identifier
        self.note = note
        self.eventType = eventType
    }
    
    // MARK: NSCoding
    
    required init?(coder decoder: NSCoder) {
        let latitude = decoder.decodeDoubleForKey(GEO_FENCE_ITEM_LatitudeKey)
        let longitude = decoder.decodeDoubleForKey(GEO_FENCE_ITEM_LongitudeKey)
        coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        radius = decoder.decodeDoubleForKey(GEO_FENCE_ITEM_RadiusKey)
        identifier = decoder.decodeObjectForKey(GEO_FENCE_ITEM_IdentifierKey) as! String
        note = decoder.decodeObjectForKey(GEO_FENCE_ITEM_NoteKey) as! String
        eventType = EventType(rawValue: decoder.decodeIntegerForKey(GEO_FENCE_ITEM_EventTypeKey))!
    }
    
    func encodeWithCoder(coder: NSCoder) {
        coder.encodeDouble(coordinate.latitude, forKey: GEO_FENCE_ITEM_LatitudeKey)
        coder.encodeDouble(coordinate.longitude, forKey: GEO_FENCE_ITEM_LongitudeKey)
        coder.encodeDouble(radius, forKey: GEO_FENCE_ITEM_RadiusKey)
        coder.encodeObject(identifier, forKey: GEO_FENCE_ITEM_IdentifierKey)
        coder.encodeObject(note, forKey: GEO_FENCE_ITEM_NoteKey)
        coder.encodeInt(Int32(eventType.rawValue), forKey: GEO_FENCE_ITEM_EventTypeKey)
    }
}
