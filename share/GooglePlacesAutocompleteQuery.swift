//
//  GooglePlacesAutocompleteQuery.swift
//  share
//
//  Created by Zhao, Xing on 11/6/14.
//  Copyright (c) 2014 Zhao, Xing. All rights reserved.
//

import Foundation

class GooglePlacesAutocompleteQuery: NSObject, NSURLConnectionDataDelegate {
    var googleConnection: NSURLConnection!
    var responseData: NSMutableData!

    typealias GooglePlacesAutocompleteResultBlock = ([autocompletePlace], NSError?) -> Void

    var resultBlock: GooglePlacesAutocompleteResultBlock!
    var input: String!
    var sensor: Bool!
    var key: String!
    
    var location: CLLocationCoordinate2D!
    var radius: CGFloat!
    var language: String!
    
    override init() {
        sensor = true
        key = "AIzaSyC7CgOO6sTQJtLFCE_ULRINl83uCeSDfaU"
    }

    struct autocompletePlace {
        var name: String
        var reference: String
        var identifier: String
        init() {
            name = String()
            reference = String()
            identifier = String()
        }
    }
    
    func fetchPlaces(block: GooglePlacesAutocompleteResultBlock) -> Void {
        
        if input.utf16Count == 0 {
            block([], nil)
            return
        }
        
//        cancelOutstandingRequests()
        resultBlock = block
        
        var request: NSURLRequest = NSURLRequest(URL: NSURL(string: googleURLString())!)
        googleConnection = NSURLConnection(request: request, delegate: self)
        responseData = NSMutableData()
    }
    
    func boolToString(boolean:Bool) ->
        String {
        return boolean ? "true" : "false"
    }
    
    func googleURLString() -> String {
        var url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=" + input.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)! + "&sensor=" + boolToString(sensor) + "&key=" + key
        
        return url
    }
    
    //MARK NSURLConnection Delegate stuff
    
    func placeFromDictionary(placeDictionary: NSDictionary) -> autocompletePlace {
        var place: autocompletePlace = autocompletePlace()
        place.name = placeDictionary["description"] as String
        place.reference = placeDictionary["reference"] as String
        place.identifier = placeDictionary["id"] as String
        return place
    }
    
    func succeedWithPlaces(places: NSArray) -> Void {
        var parsedPlaces:Array<autocompletePlace> = []
        for place in places {
            parsedPlaces.append(self.placeFromDictionary(place as NSDictionary))
        }
        resultBlock(parsedPlaces, nil)
    }
    
    func cancelOutstandingRequests() -> Void {
        googleConnection.cancel()
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
//        if connection == googleConnection {
//            responseData.appendData(<#other: NSData#>)
//        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        if connection == googleConnection {
            responseData.appendData(data)
        }
    }
    func connectionDidFinishLoading(connection: NSURLConnection) {
        if connection == googleConnection {
            var error:NSError? = nil
            var response: NSDictionary = NSJSONSerialization.JSONObjectWithData(responseData, options: NSJSONReadingOptions.MutableContainers, error: &error) as NSDictionary
            
            if error != nil {
                println("there is error")
            }
            
            if (response["status"] as String == "OK") {
                succeedWithPlaces(response["predictions"] as NSArray)
            }
        }
    }
    
}