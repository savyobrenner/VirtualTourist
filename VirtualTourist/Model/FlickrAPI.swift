//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Brenner on 16/01/22.
//

import Foundation
import UIKit
import MapKit

class FlickrAPI: NSObject {
    
    // MARK:- Properties
    
    // shared session
    var session = URLSession.shared
    var delegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // MARK: Initializers
    override init() {
        super.init()
    }
    
    // MARK:- GET
    //MERK:- GETing
    func displayImageFromFlickrBySearch(_ coordinate: CLLocationCoordinate2D, completionHandlerForGET: @escaping (_ result: [[String:Any]], _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        let methodParameters = getParameters(coordinate: coordinate)
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParameters))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET([[:]], NSError(domain: "displayImageFromFlickrBySearch", code: 1, userInfo: userInfo as [String : Any]))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error?.localizedDescription ?? "")")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[FlickrAPI.FlickrResponseKeys.Status] as? String, stat == FlickrAPI.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(String(describing: parsedResult))")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = parsedResult[FlickrAPI.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find keys '\(FlickrAPI.FlickrResponseKeys.Photos)' in \(String(describing: parsedResult))")
                return
            }
            
            /* GUARD: Is "pages" key in the photosDictionary? */
            guard let totalPages = photosDictionary[FlickrAPI.FlickrResponseKeys.Pages] as? Int else {
                displayError("Cannot find key '\(FlickrAPI.FlickrResponseKeys.Pages)' in \(photosDictionary)")
                return
            }
            
            // pick a random page!
            let pageLimit = min(totalPages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
            let _ = self.displayImageFromFlickrBySearch(methodParameters, withPageNumber: randomPage, completionHandlerForGET: { (results, error) in
                completionHandlerForGET(results, error)
            })
        }
        
        // start the task!
        task.resume()
        return task
    }
    
    // FIX: For Swift 3, variable parameters are being depreciated. Instead, create a copy of the parameter inside the function.
    
    private func displayImageFromFlickrBySearch(_ methodParameters: [String: AnyObject], withPageNumber: Int, completionHandlerForGET: @escaping (_ result: [[String:Any]], _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        // add the page to the method's parameters
        var methodParametersWithPageNumber = methodParameters
        methodParametersWithPageNumber[FlickrAPI.FlickrParameterKeys.Page] = withPageNumber as AnyObject?
        
        // create session and request
        let session = URLSession.shared
        let request = URLRequest(url: flickrURLFromParameters(methodParametersWithPageNumber))
        
        // create network request
        let task = session.dataTask(with: request) { (data, response, error) in
            
            // if an error occurs, print it and re-enable the UI
            func displayError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET([[:]], NSError(domain: "displayImageFromFlickrBySearchWithPageNumber", code: 1, userInfo: userInfo as [String : Any]))
            }
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                displayError("There was an error with your request: \(error?.localizedDescription ?? "")")
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                displayError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                displayError("No data was returned by the request!")
                return
            }
            
            // parse the data
            let parsedResult: [String:AnyObject]!
            do {
                parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
            } catch {
                displayError("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = parsedResult[FlickrAPI.FlickrResponseKeys.Status] as? String, stat == FlickrAPI.FlickrResponseValues.OKStatus else {
                displayError("Flickr API returned an error. See error code and message in \(String(describing: parsedResult))")
                return
            }
            
            /* GUARD: Is the "photos" key in our result? */
            guard let photosDictionary = parsedResult[FlickrAPI.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                displayError("Cannot find key '\(FlickrAPI.FlickrResponseKeys.Photos)' in \(String(describing: parsedResult))")
                return
            }
            
            /* GUARD: Is the "photo" key in photosDictionary? */
            guard let photosArray = photosDictionary[FlickrAPI.FlickrResponseKeys.Photo] as? [[String: AnyObject]] else {
                displayError("Cannot find key '\(FlickrAPI.FlickrResponseKeys.Photo)' in \(photosDictionary)")
                return
            }
            
            completionHandlerForGET(photosArray, nil)
            
        }
        // start the task!
        task.resume()
        return task
    }
    
    private func getParameters(coordinate: CLLocationCoordinate2D) -> [String:AnyObject]  {
        
        let methodParameters = [
            FlickrAPI.FlickrParameterKeys.Method: FlickrAPI.FlickrParameterValues.SearchMethod,
            FlickrAPI.FlickrParameterKeys.APIKey: FlickrAPI.FlickrParameterValues.APIKey,
            FlickrAPI.FlickrParameterKeys.Lat: coordinate.latitude,
            FlickrAPI.FlickrParameterKeys.Lon: coordinate.longitude,
            FlickrAPI.FlickrParameterKeys.SafeSearch: FlickrAPI.FlickrParameterValues.UseSafeSearch,
            FlickrAPI.FlickrParameterKeys.Extras: FlickrAPI.FlickrParameterValues.MediumURL,
            FlickrAPI.FlickrParameterKeys.Format: FlickrAPI.FlickrParameterValues.ResponseFormat,
            FlickrAPI.FlickrParameterKeys.PerPage: FlickrAPI.FlickrParameterValues.PerPageValue,
            FlickrAPI.FlickrParameterKeys.NoJSONCallback: FlickrAPI.FlickrParameterValues.DisableJSONCallback
            ] as [String:AnyObject]
        return methodParameters
    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = FlickrAPI.Constants.APIScheme
        components.host = FlickrAPI.Constants.APIHost
        components.path = FlickrAPI.Constants.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
    
    // MARK: Shared Instance
    class func sharedInstance() -> FlickrAPI {
        struct Singleton {
            static var sharedInstance = FlickrAPI()
        }
        return Singleton.sharedInstance
    }
    
    
}

