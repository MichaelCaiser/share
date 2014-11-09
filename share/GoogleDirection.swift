//
//  GoogleDirection.swift
//  share
//
//  Created by Zhao, Xing on 11/8/14.
//  Copyright (c) 2014 Zhao, Xing. All rights reserved.
//

import Foundation

class GoogleDirection: NSObject, NSURLConnectionDataDelegate {
    
    var key: String!
    
    var googleConnection: NSURLConnection!
    
    typealias GooglePlaceDirectionResultBlock = ([directionStruct], NSError?) -> Void
    
    var resultBlock: GooglePlaceDirectionResultBlock!
    
    var input, currentLocation: CLLocation!
    
    struct directionStruct {
//        var name: String
        var polyline: String
        init() {
            polyline = String()
        }
    }
    
    var responseData: NSMutableData!
    
    override init() {
        key = "AIzaSyC7CgOO6sTQJtLFCE_ULRINl83uCeSDfaU"
    }
    
    func fetchDirections(block: GooglePlaceDirectionResultBlock) -> Void {
        resultBlock = block
        
        var request: NSURLRequest = NSURLRequest(URL: NSURL(string: googleURLString())!)
        googleConnection = NSURLConnection(request: request, delegate: self)
        responseData = NSMutableData()
    }
    
    func googleURLString() -> String {
        var url = "https://maps.googleapis.com/maps/api/directions/json?origin=\(currentLocation.coordinate.latitude),\(currentLocation.coordinate.longitude)&destination=\(input.coordinate.latitude),\(input.coordinate.longitude)&key=\(key)"
        
        return url
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        if connection == googleConnection {
            responseData.appendData(data)
        }
    }
    
    func directionFromDictionary(placeDictionary: NSDictionary) -> directionStruct {
        var place: directionStruct = directionStruct()
        
        let polyline = placeDictionary["polyline"] as NSDictionary
        
        place.polyline = polyline["points"] as String
        return place
    }
    
    func succeedWithDirection(places: NSArray) -> Void {
        var parsedDirection:Array<directionStruct> = []
        for place in places {
            parsedDirection.append(self.directionFromDictionary(place as NSDictionary))
        }
        resultBlock(parsedDirection, nil)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        if connection == googleConnection {
            var error:NSError? = nil
            var response: NSDictionary = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary
            
            if error != nil {
                println("there is error")
            }
            
            

            if (response["status"] as String == "OK") {
                let routes = response["routes"] as NSArray
                let route = routes[0] as NSDictionary
                let legs = (route["legs"] as NSArray)[0] as NSDictionary
                let steps = legs["steps"] as NSArray
                
                succeedWithDirection(steps)
                
                println()
            }
        }
    }
    
}