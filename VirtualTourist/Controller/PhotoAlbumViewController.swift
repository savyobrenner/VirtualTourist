//
//  PhotoAlbumViewController.swift
//  VirtualTourist
//
//  Created by Brenner on 16/01/22.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var newCollectionButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private var predicate: NSPredicate?
    var coordinate = CLLocationCoordinate2D()
    var dataManager: DataManager?
    var photos = [Photo]()
    var pin: Pin?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let pin = pin {
            predicate = NSPredicate(format: "pin == %@", pin)
        }
        
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        
        fetchRequest.predicate = predicate
        
        if let result = try? dataManager?.viewContext.fetch(fetchRequest) {
            photos = result
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let annotation = MKPointAnnotation()
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        if photos.isEmpty {
            getPhotos()
        }
    }
    
    @IBAction func newCollectionBtnPressed(_ sender: Any) {
        pin?.photos = nil
        try? dataManager?.viewContext.save()
        collectionView.reloadData()
        photos.removeAll()
        getPhotos()
    }
    
    private func getPhotos() {
        setUIEnabled(false)
        let _ = FlickrServices.sharedInstance.displayImageFromFlickrBySearch(coordinate) { (imagesArray, error) in
            
            if let error = error {
                let controller = UIAlertController(title: "", message: "\(error.localizedDescription)", preferredStyle: .alert)
                
                controller.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                
                self.present(controller, animated: true, completion: nil)
                self.setUIEnabled(true)
            }
            
            for image in imagesArray {
                
                guard let imageUrlString = image["url_m"] as? String,
                      let imageURL = URL(string: imageUrlString),
                      let imageData = try? Data(contentsOf: imageURL),
                      let dataManager = self.dataManager else {
                          debugPrint("Cannot find key in \(image)")
                          self.setUIEnabled(true)
                          return
                      }
                
                let photo: Photo = Photo(context: dataManager.viewContext)
                photo.url = imageURL
                photo.rawImage = imageData
                photo.pin = self.pin
                try? dataManager.viewContext.save()
                self.photos.append(photo)
                
                DispatchQueue.main.async {
                    self.collectionView.reloadData()
                }
            }
            
            self.setUIEnabled(true)
            
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
            
        }
        
    }
    
    private func setUIEnabled(_ enabled: Bool) {
        DispatchQueue.main.async {
            self.newCollectionButton.isEnabled = enabled
            
            if enabled {
                self.newCollectionButton.alpha = 1.0
                self.activityIndicator.alpha = 0.0
                self.activityIndicator.stopAnimating()
            } else {
                self.newCollectionButton.alpha = 0.5
                self.activityIndicator.alpha = 1.0
                self.activityIndicator.startAnimating()
            }
        }
    }
    
}

extension PhotoAlbumViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.pinTintColor = .red
        } else if let pinView = pinView{
            pinView.annotation = annotation
        }
        
        return pinView
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as? PhotoCollectionViewCell else { return UICollectionViewCell() }
        
        if let rawPhoto = photos[indexPath.row].rawImage {
            cell.photo.image = UIImage(data: rawPhoto)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        dataManager?.viewContext.delete(photos[indexPath.row])
        try? dataManager?.viewContext.save()
        photos.remove(at: indexPath.row)
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let bounds = collectionView.bounds
        
        return CGSize(width: (bounds.width/2)-4, height: bounds.height/2)
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        .init(top:2, left:2, bottom:2, right:2)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        0
    }
    
}
