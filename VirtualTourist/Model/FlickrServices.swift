//
//  FlickrAPI.swift
//  VirtualTourist
//
//  Created by Brenner on 16/01/22.
//

import UIKit
import MapKit

class FlickrServices: NSObject {
    
    private enum Constants {
        static let APIKey = "9a7606e608ef1818afd8a28ccc942ab5"
        static let baseURL = "https://api.flickr.com/services/rest"
    }
    
    static var sharedInstance = FlickrServices()
    
    var session = URLSession.shared
    var delegate: AppDelegate = UIApplication.shared.delegate as! AppDelegate
    
    // MARK: Initializers
    override init() {
        super.init()
    }
    
    
    func displayImageFromFlickrBySearch(_ coordinate: CLLocationCoordinate2D, completionHandlerForGET: @escaping (_ result: [[String:Any]], _ error: NSError?) -> Void) -> URLSessionDataTask {
        
        var url = URL(string: Constants.baseURL)
        
        let URLParams = [
            "method": "flickr.photos.search",
            "api_key": Constants.APIKey,
            "lon": "\(coordinate.longitude)",
            "format": "json",
            "per_page": "21",
            "lat": "\(coordinate.latitude)",
            "nojsoncallback": "1",
            "extras": "url_m"
        ]
        
        url = url?.appendingQueryParameters(URLParams)
        
        let session = URLSession.shared
        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        
        let task = session.dataTask(with: request) { (data, response, error) in
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299,
                  let data = data,
                  error == nil else {
                      debugPrint("There was an error with your request: \(error?.localizedDescription ?? "")")
                      return
                  }
            
            let parsedJSON: [String:AnyObject]!
            
            do {
                parsedJSON = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String:AnyObject]
                let status = parsedJSON["stat"] as? String
                
                guard status == "ok" else {
                    debugPrint("There was an error with your request: \(error?.localizedDescription ?? "")")
                    return
                }
                
            } catch {
                debugPrint("Could not parse the data as JSON: '\(data)'")
                return
            }
            
            
            guard let photosDic = parsedJSON["photos"] as? [String: AnyObject],
                  let photos = photosDic["photo"] as? [[String: AnyObject]] else {
                      debugPrint("There was an error with your request: \(error?.localizedDescription ?? "")")
                      return
                  }
            
            completionHandlerForGET(photos, nil)
        }
        
        task.resume()
        return task
    }
}

