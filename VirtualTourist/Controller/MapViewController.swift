//
//  MapViewController.swift
//  VirtualTourist
//
//  Created by Brenner on 16/01/22.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var pins: [Pin] = []
    var dataManager: DataManager?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleTap))
        gestureRecognizer.delegate = self
        mapView.addGestureRecognizer(gestureRecognizer)
        
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        if let result = try? dataManager?.viewContext.fetch(fetchRequest) {
            pins = result
            mapView.removeAnnotations(mapView.annotations)
            addAnnotations()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        addAnnotations()
    }
    
    @objc private func handleTap(gestureReconizer: UIGestureRecognizer) {
        
        if let dataManager = dataManager, gestureReconizer.state == UIGestureRecognizer.State.began {
            let location = gestureReconizer.location(in: mapView)
            let coordinate = mapView.convert(location,toCoordinateFrom: mapView)
            let pin = Pin(context: dataManager.viewContext)
            
            pin.latitude = coordinate.latitude.magnitude
            pin.longitude = coordinate.longitude.magnitude
            
            do {
                try dataManager.viewContext.save()
            }catch{
                print("error")
            }
            
            pins.append(pin)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
        }
    }
    
    func addAnnotations() {
        
        mapView.removeAnnotations(mapView.annotations)
        
        var annotations = [MKPointAnnotation]()
        
        for pin in pins {
            
            let latitude = CLLocationDegrees(pin.latitude)
            let longitude = CLLocationDegrees(pin.longitude)
            
            let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinate
            
            annotations.append(annotation)
        }
        
        mapView.addAnnotations(annotations)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseIdentifier = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseIdentifier) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseIdentifier)
            pinView?.pinTintColor = .red
        } else if let pinView = pinView {
            pinView.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let controller = storyboard?.instantiateViewController(withIdentifier: "PhotoAlbumViewController") as? PhotoAlbumViewController else { return }
        
        if let coordinate = view.annotation?.coordinate {
            controller.coordinate = coordinate
        }
        
        for pin in pins {
            if pin.latitude.isEqual(to: view.annotation?.coordinate.latitude.magnitude ?? 90){
                controller.pin = pin
            }
        }
        
        controller.dataManager = dataManager
        show(controller, sender: nil)
    }
    
}

extension MapViewController: UIGestureRecognizerDelegate {}
 
