
//
//  ViewController.swift
//  share
//
//  Created by Zhao, Xing on 11/3/14.
//  Copyright (c) 2014 Zhao, Xing. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating{
    
    var tableView: UITableView = UITableView()
    
    var searchQuery: GooglePlacesAutocompleteQuery = GooglePlacesAutocompleteQuery()
    var searchResultPlaces = Array<GooglePlacesAutocompleteQuery.autocompletePlace>()
    
    var directionQuery: GoogleDirection = GoogleDirection()
    var directionResult = Array<GoogleDirection.directionStruct>()
    
    var table: UITableView = UITableView()
    var restoredState = SearchControllerRestorableState()
    struct SearchControllerRestorableState {
        var wasActive = false
        var wasFirstResponder = false
    }
//    @IBOutlet var _mainView:UIView!
    @IBOutlet var _mapView: UIView!
    var searchController: UISearchController = UISearchController()
    var searchBar: UISearchBar = UISearchBar()
    var locationManager: CLLocationManager!
    var mapView: GMSMapView?
    var firstLocationUpdate = false
    
    var _searchTableViewRect: CGRect = CGRect()
    
    // viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.edgesForExtendedLayout = UIRectEdge.Left | UIRectEdge.Bottom | UIRectEdge.Right
        self.navigationController?.navigationBar.barTintColor = UIColor.whiteColor()
        
        // locationManager
        locationManager = CLLocationManager()
        locationManager.requestAlwaysAuthorization()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()

        // google Map View
        var camera = GMSCameraPosition.cameraWithLatitude(-33.868, longitude: 151.2086, zoom: 12)
        mapView = GMSMapView.mapWithFrame(self.view.bounds, camera: camera)
        mapView?.settings.compassButton = true
        mapView?.settings.myLocationButton = true
        mapView?.addObserver(self, forKeyPath: "myLocation", options: NSKeyValueObservingOptions.New, context: nil)
        self._mapView.addSubview(mapView!)

        // The TableViewController used to display the results of a search
        var searchResultsController:UITableViewController = UITableViewController(style: UITableViewStyle.Plain)
        searchResultsController.automaticallyAdjustsScrollViewInsets = false
        searchResultsController.tableView.dataSource = self
        searchResultsController.tableView.delegate = self
        
        // searchController
        searchController = UISearchController(searchResultsController: searchResultsController)
        searchController.delegate = self
        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        
        var searchBarFrame:CGRect = self.searchController.searchBar.frame
        var viewFrame = self.view.frame
        self.searchController.searchBar.frame = CGRectMake(searchBarFrame.origin.x, searchBarFrame.origin.y, viewFrame.size.width, 44)
        self.view.addSubview(self.searchController.searchBar)
        self.view.bringSubviewToFront(self.searchController.searchBar)
        
        // dispatch stuff
        dispatch_async(dispatch_get_main_queue(), {
            self.mapView!.myLocationEnabled = true
            }
        )
        
        var button: UIButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
        
        button.setTitle("X", forState: UIControlState.Normal)
        
        button.addTarget(self, action:Selector("wasDragged:withEvent:"), forControlEvents: UIControlEvents.TouchDragInside)

        button.frame = CGRectMake(135.0, 180.0, 40.0, 40.0)
        
        button.clipsToBounds = true
        
        button.backgroundColor = UIColor.whiteColor()
        
        button.layer.cornerRadius = 20
        
        button.layer.borderWidth = 2
        
        self.view.addSubview(button)
        
    }
    
    func wasDragged( button: UIButton!, withEvent event: UIEvent) -> Void {
        var touch: UITouch = event.touchesForView(button)?.anyObject()! as UITouch
        
        var previousLocation: CGPoint = touch.previousLocationInView(button)
        var location: CGPoint = touch.locationInView(button)
        var delta_x: CGFloat = location.x - previousLocation.x
        var delta_y: CGFloat = location.y - previousLocation.y
        
        button.center = CGPointMake(button.center.x+delta_x, button.center.y+delta_y)
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>){
        if !firstLocationUpdate {
            firstLocationUpdate = true
            var location: CLLocation = change[NSKeyValueChangeNewKey]! as CLLocation
            mapView?.camera = GMSCameraPosition.cameraWithTarget(location.coordinate, zoom: 14)
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }

    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultPlaces.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCellWithIdentifier("CELL") as? UITableViewCell
        
        if cell == nil {
            cell = UITableViewCell(style: UITableViewCellStyle.Value1, reuseIdentifier: "CELL")
        }
        
        cell?.textLabel.text = searchResultPlaces[indexPath.row].name
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        println("did select")
        
        var place: GooglePlacesAutocompleteQuery.autocompletePlace = self.searchResultPlaces[indexPath.row]
        
        var geocoder:CLGeocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(place.name, {(placemarks:[AnyObject]!, error:NSError?) -> Void in
            var placemark:CLPlacemark = placemarks[0] as CLPlacemark

            self.addPlaceMark(placemark)
            self.searchController.active = false
        })
        
    }

    func addPlaceMark(placemark: CLPlacemark) -> Void {
        var position:CLLocationCoordinate2D = CLLocationCoordinate2DMake(placemark.location.coordinate.latitude, placemark.location.coordinate.longitude)
        
        var marker:GMSMarker = GMSMarker(position: position)
        
        marker.title = "WORLD!"
        
        println("latitude: \(self.mapView?.myLocation.coordinate.latitude), longtitude: \(self.mapView?.myLocation.coordinate.longitude)")
        
        marker.map = self.mapView
        
        directionQuery.currentLocation = self.mapView?.myLocation
        directionQuery.input = placemark.location
        
        directionQuery.fetchDirections({(direction: [GoogleDirection.directionStruct], error: NSError?) -> Void in
            if (error != nil) {
                println("error exists")
            } else {
                self.directionResult = direction

                var polyline: GMSPolyline = GMSPolyline()
                var path: GMSPath = GMSPath()
                
                for var i = 0; i < self.directionResult.count; i++ {
                    path = GMSPath(fromEncodedPath: self.directionResult[i].polyline)
                    polyline = GMSPolyline(path:path)
                    polyline.strokeWidth = 7
                    polyline.strokeColor = UIColor.blackColor()
                    polyline.map = self.mapView
                }
                
            }
        })
        
        
    }
    
    func handleSearchForSearchString(searchString: String) -> Void {
        searchQuery.input = searchString
        
        searchQuery.fetchPlaces({(places:[GooglePlacesAutocompleteQuery.autocompletePlace], error:NSError?) -> Void in
            if (error != nil) {
                println("error exists")
            } else {
                self.searchResultPlaces = places
                let resultsController = self.searchController.searchResultsController as UITableViewController
                resultsController.tableView.reloadData()
            }
        })
        
    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        handleSearchForSearchString(searchController.searchBar.text)
    }
    
    func willPresentSearchController(searchController: UISearchController) {

    }
    
    
    
}

