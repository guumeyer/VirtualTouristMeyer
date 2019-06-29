//
//  TravelLocationsMapViewController.swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/20/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import UIKit
import MapKit
import CoreData

final class TravelLocationsMapViewController: UIViewController {

    // MARK: IBOutlet
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var removeTapView: UILabel!


    private let editLabel = "Edit"
    private let doneLabel = "Done"
    private var dataController: DataController!
    private var fetchedResultsController: NSFetchedResultsController<Pin>!
    private var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    private var serviceApi: PhotoLocationLoader!

    convenience init(_ dataController: DataController, _ serviceApi: PhotoLocationLoader) {
        self.init()
        self.dataController = dataController
        self.serviceApi = serviceApi
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupFetchedResultsController()

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()
        setupMapView()
        loadPins()
        let editButton = UIBarButtonItem(title: editLabel,
                                         style: .plain,
                                         target: self,
                                         action: #selector(editDidTapAction))
        navigationItem.rightBarButtonItem = editButton
        navigationController?.navigationBar.backItem?.title = "Back"
        title = "VirtualTourist"

        removeTapView.isHidden = true

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }

    @objc func mapDidLongTouchAction(gestureRecognizer:UIGestureRecognizer){
        let touchPoint = gestureRecognizer.location(in: mapView)
        let selectedCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        if coordinate.latitude != selectedCoordinate.latitude || coordinate.longitude != selectedCoordinate.longitude {
            coordinate = selectedCoordinate
            if navigationItem.rightBarButtonItem?.title == editLabel {
                createPin(for: selectedCoordinate)
            }
        }
    }

    private func setupMapView() {
        mapView.delegate = self
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(mapDidLongTouchAction))
        mapView.addGestureRecognizer(gestureRecognizer)
    }

    fileprivate func persisteContext() {
        do {
            try dataController.saveContext()

        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    @discardableResult
    private func createPin(for coordinate: CLLocationCoordinate2D) -> Pin {
        print("pin tapped")
        let pin = Pin(context: dataController.viewContext)
        pin.latitude = coordinate.latitude
        pin.longitude = coordinate.longitude
        pin.pages = 0
        pin.creationDate = Date()

        retrivePhotos(by: pin)
        return pin
    }

    private func deletePin(at pin: Pin) {
        dataController.viewContext.delete(pin)
        persisteContext()

    }

    private func loadPins() {
        if let pins = fetchedResultsController.fetchedObjects {
            pins.forEach{ mapView.addAnnotation($0) }
        }
    }

    private func retrievePin(by coordinate: CLLocationCoordinate2D) -> Pin? {
        return fetchedResultsController.fetchedObjects?
            .first(where: {$0.latitude == coordinate.latitude && $0.longitude == coordinate.longitude})
    }

    private func buildPhotoSet(_ pin: Pin, _ result: RemotePhotos) -> Set<Photo>? {
        dump(result)
        if result.photo.isEmpty {
            return nil
        }
        var photos = Set<Photo>()

        result.photo.forEach{ flickerPhoto  in
            let photo = Photo(context: self.dataController.viewContext)
            photo.id = flickerPhoto.id
            photo.url = flickerPhoto.url
            photo.title = flickerPhoto.title
            photo.pin = pin
            photos.insert(photo)
        }
        self.persisteContext()
        return photos
    }

    private func retrivePhotos(by pin: Pin) {
        serviceApi.searchPhotosByGeolocation(pin) {(result) in
            DispatchQueue.main.async {
                switch(result) {
                case .success(let result):
                    pin.photos = self.buildPhotoSet(pin, result) as NSSet?
                    pin.pages = Int32(result.pages)
                    self.persisteContext()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }

    private func setupFetchedResultsController() {
        let fetchRequest:NSFetchRequest<Pin> = Pin.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: dataController.viewContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: "pins")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

     @objc private func editDidTapAction() {
        if navigationItem.rightBarButtonItem?.title == editLabel {
            prepareUiEditAction(doneLabel, false)
        } else if navigationItem.rightBarButtonItem?.title == doneLabel {
            prepareUiEditAction(editLabel, true)
        }
    }

    private func prepareUiEditAction(_ title: String, _ isHidden: Bool) {
        navigationItem.rightBarButtonItem?.title = title
        removeTapView.isHidden = isHidden
    }
}

extension TravelLocationsMapViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {

        if let coordinate = view.annotation?.coordinate, let pin = retrievePin(by: coordinate) {
            if navigationItem.rightBarButtonItem?.title == doneLabel {
                deletePin(at: pin)

                if let annotation = mapView.annotations.first(where: { $0.coordinate.latitude == pin.latitude &&
                    $0.coordinate.longitude == pin.longitude }) {
                    mapView.removeAnnotation(annotation)
                }
            } else {
                let photoAlbumViewController = PhotoAlbumViewController(dataController, pin, serviceApi)
                navigationController?.pushViewController(photoAlbumViewController, animated: true)
            }
        }
    }
}

extension TravelLocationsMapViewController: NSFetchedResultsControllerDelegate {

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {

        guard let pin = anObject as? Pin else {
            preconditionFailure("All changes observed in the map view controller should be for Pin instances")
        }

        if type == .insert {
            mapView.addAnnotation(pin)
        } else if type == .delete {
            mapView.removeAnnotation(pin)
        }
    }
}
