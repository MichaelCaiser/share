//
//  GooglePlacesSearchViewController.swift
//  share
//
//  Created by Zhao, Xing on 11/5/14.
//  Copyright (c) 2014 Zhao, Xing. All rights reserved.
//

import UIKit

class GSViewController: UITableViewController, CLLocationManagerDelegate, UISearchBarDelegate, UISearchControllerDelegate, UISearchResultsUpdating {
    
    var searchQuery: GooglePlacesAutocompleteQuery!
    var searchResultPlaces: [GooglePlacesAutocompleteQuery.autocompletePlace]!
    
    let viewController = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle()).instantiateViewControllerWithIdentifier("ViewController") as ViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "cell")
        searchQuery = GooglePlacesAutocompleteQuery()
        searchQuery.radius = 100.0
        searchResultPlaces = []
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResultPlaces.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell = self.tableView.dequeueReusableCellWithIdentifier("cell") as UITableViewCell

        cell.textLabel.text = searchResultPlaces[indexPath.row].name
        
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        println("did select")
        
        var place: GooglePlacesAutocompleteQuery.autocompletePlace = self.searchResultPlaces[indexPath.row]
        
        dismissSearchControllerWhileStayingActive()
        
    }
    
    //MARK Search Delegate
    func dismissSearchControllerWhileStayingActive() -> Void {
//        NSTimeInterval animationDuration = 0.3;
//        [UIView beginAnimations:nil context:NULL];
//        [UIView setAnimationDuration:animationDuration];
//        self.searchDisplayController.searchResultsTableView.alpha = 0.0;
//        [UIView commitAnimations];
//        
//        [self.searchDisplayController.searchBar setShowsCancelButton:NO animated:YES];
//        [self.searchDisplayController.searchBar resignFirstResponder];
        
        var animationDuration:NSTimeInterval = 0.3
        UIView.beginAnimations(nil, context: nil)
        
        UIView.setAnimationDuration(animationDuration)
        
        UIView.commitAnimations()
        

        
    }
    
    
    func handleSearchForSearchString(searchString: String) -> Void {
        searchQuery.input = searchString
        
        searchQuery.fetchPlaces({(places:[GooglePlacesAutocompleteQuery.autocompletePlace], error:NSError?) -> Void in
            if (error != nil) {
                println("error exists")
            } else {
                self.searchResultPlaces = places
                self.tableView.reloadData()
            }
        })

    }
    
    func updateSearchResultsForSearchController(searchController: UISearchController)
    {
        handleSearchForSearchString(searchController.searchBar.text)
    }
}

