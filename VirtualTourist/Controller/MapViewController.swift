//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Brenner on 16/01/22.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var pins: [Pin] = []
    var dataManager: DataManager!
    
    override func viewWillAppear(_ animated: Bool) {
        addAnnotations()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // add Gesture Recognizer to map
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        // fetch request
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataManager.viewContext.fetch(fetchRequest) {
            pins = result
            mapView.removeAnnotations(mapView.annotations)
            addAnnotations()
        }
        
    }
    
    @objc func handleTap(gestureReconizer: UIGestureRecognizer) {
        if gestureReconizer.state == UIGestureRecognizer.State.began {
            let location = gestureReconizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            
            let pin = Pin(context: dataManager.viewContext)
            pin.lat = coordinate.latitude.magnitude
            pin.lon = coordinate.longitude.magnitude
            do {
                try dataManager.viewContext.save()
            }catch{
                print("error")
            }
            pins.append(pin)
            
            // Add annotation:
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    func addAnnotations(){
        mapView.removeAnnotations(mapView.annotations)
        
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            // Notice that the float values are being used to create CLLocationDegree values.
            // This is a version of the Double type.
            
            let lat = CLLocationDegrees(pin.lat)
            let long = CLLocationDegrees(pin.lon)
            
            // The lat and long are used to create a CLLocationCoordinates2D instance.
            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: long)
            
            // Here we create the annotation and set its coordiate, title, and subtitle properties
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            // Finally we place the annotation in an array of annotations.
            annotations.append(annotation)
        }
        // When the array is complete, we add the annotations to the map.
        mapView.addAnnotations(annotations)
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // This delegate method is implemented to respond to taps. It opens the photoAlbumView
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let controller = self.storyboard!.instantiateViewController(withIdentifier: "PhotoAlbumVC") as? PhotoAlbumViewController
        controller?.coordinate = view.annotation?.coordinate
        
        for pin in pins {
            if pin.lat.isEqual(to: view.annotation?.coordinate.latitude.magnitude ?? 90){
                controller?.pin = pin
            }
        }
        controller?.dataController = dataManager
        self.show(controller!, sender: nil)
    }
    
    
}


