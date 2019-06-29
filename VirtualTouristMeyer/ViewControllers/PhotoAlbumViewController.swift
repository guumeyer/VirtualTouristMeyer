//
//  PhotoAlbumViewController.swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/25/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import UIKit
import MapKit
import CoreData

final class PhotoAlbumViewController: UIViewController {

    // TODO:
    // - Delete photo
    // - Get a new random set photos
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var editButton: UIButton!
    
    private let cellSpace: CGFloat = 1
    private let numberOfCellByLine: CGFloat = 3.0
    private let newCollection = "New Collection"
    private let removeSelectedPictures = "Remove Selected Pictures"
    private let noPhotoFound = "No photos found for this location"
    private var serviceApi: PhotoLocationLoader!

    private var pin: Pin!
    private var dataController: DataController!
    private var fetchedResultsController: NSFetchedResultsController<Photo>!
    private var shouldShowAlert = true

    private var insertedIndexPaths: [IndexPath]!
    private var deletedIndexPaths: [IndexPath]!
    private var updatedIndexPaths: [IndexPath]!

    convenience init(_ dataController: DataController, _ pin: Pin, _ serviceApi: PhotoLocationLoader) {
        self.init()
        self.dataController = dataController
        self.pin = pin
        self.serviceApi = serviceApi
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        collectionView.register(UINib(nibName: String(describing: PhotoAlbumCell.self), bundle: nil),
                                forCellWithReuseIdentifier: PhotoAlbumCell.identifier)
        setupFetchedResultController(by: pin)

        editButton.isHidden = true
        statusLabel.text = ""

        if pin.photos?.count == 0 {
            retrivePhotos(by: pin)
        } else {
            statusLabel.isHidden = true
            editButton.isHidden = false
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        mapView.addAnnotation(pin)
        mapView.setCenter(pin.coordinate, animated: true)

    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }


    @IBAction func editDidTapAction(_ sender: Any) {
        if editButton.titleLabel?.text == newCollection {
            newCollectionAction()
        } else if editButton.titleLabel?.text == removeSelectedPictures {
            removeSelectedPicturesAction()
        }
    }

    func newCollectionAction() {
        //TODO GET a new collection
        if let photos = fetchedResultsController.fetchedObjects {
            photos.forEach {
                dataController.viewContext.delete($0)
            }
        }
        persisteContext()

        retrivePhotos(by: pin)
    }

    func removeSelectedPicturesAction() {
        if let indexPathsForSelectedItems = collectionView.indexPathsForSelectedItems {
            indexPathsForSelectedItems.forEach {
                let photo =  fetchedResultsController.object(at: $0)
                dataController.viewContext.delete(photo)
            }
            persisteContext()
            defineEditLagel()
        }
    }

    // MARK: - Get photos information
    private func buildPhotoSet(_ pin: Pin, _ result: RemotePhotos) -> Set<Photo>? {
        dump(result)
        if result.photo.isEmpty {
            statusLabel.text = noPhotoFound
            statusLabel.isHidden = false
            editButton.isHidden = true
            return nil
        }

        statusLabel.text = ""
        statusLabel.isHidden = true
        editButton.isHidden = false

        var photos = Set<Photo>()

        result.photo.forEach{ flickerPhoto  in
            let photo = Photo(context: self.dataController.viewContext)
            photo.id = flickerPhoto.id
            photo.url = flickerPhoto.url
            photo.title = flickerPhoto.title
            photo.pin = pin
            photos.insert(photo)
        }
        return photos
    }

    private func retrivePhotos(by pin: Pin) {
        serviceApi.searchPhotosByGeolocation(pin) {(result) in
            DispatchQueue.main.async {
                switch(result) {
                case .success(let result):
                    pin.photos = self.buildPhotoSet(pin, result) as NSSet?
                    self.persisteContext()
                case .failure(let error):
                    print(error.localizedDescription)
                }
            }
        }
    }
}

extension PhotoAlbumViewController: UICollectionViewDataSource {

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return fetchedResultsController.sections?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let sectionInfo = self.fetchedResultsController.sections?[section] {
            return sectionInfo.numberOfObjects
        }
        return 0
    }

    fileprivate func dequeueReusableCell(_ collectionView: UICollectionView,
                                         _ indexPath: IndexPath) -> UICollectionViewCell {
        return collectionView.dequeueReusableCell(withReuseIdentifier: PhotoAlbumCell.identifier, for: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = dequeueReusableCell(collectionView, indexPath)

        if let photoCell = cell as? PhotoAlbumCell {
            if let selectedItems = collectionView.indexPathsForSelectedItems {
                photoCell.isSelected = selectedItems.contains(where: {
                    $0.row == indexPath.row
                })
            }
            photoCell.backgroundColor = .darkGray
            photoCell.configure(data: nil)
        }

        return cell
    }

    fileprivate func defineEditLagel() {
        if collectionView.indexPathsForSelectedItems?.count ?? 0 > 0 {
            editButton.setTitle(removeSelectedPictures, for: .normal)
        } else {
            editButton.setTitle(newCollection, for: .normal)
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        defineEditLagel()
    }

    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
       defineEditLagel()
    }

    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        let photo = fetchedResultsController.object(at: indexPath)

        guard let photoCell = cell as? PhotoAlbumCell else { return }
        guard let imageData = photo.data else {
            downloadImage(photo, photoCell)
            return
        }
        photoCell.configure(data: imageData)
    }

    private func downloadImage(_ photo: Photo,_ photoCell: PhotoAlbumCell) {
        guard photo.url != nil else {
            print("Photo \(String(describing: photo.id)) URL is nil")
            photoCell.noImageAvailable() 
            return
        }
        serviceApi.dowloadPhoto(for: photo) { [weak self] result in
            guard let strongSelf = self else { return }

            switch result {
            case .failure( let error) :
                DispatchQueue.main.async {
                    photoCell.activeIndicator.stopAnimating()
                    photoCell.activeIndicator.isHidden = true
                    strongSelf.editButton.isHidden = true
                    dump(error)
                    strongSelf.showErrorFromImageUrl(photo.url!)
                }
            case .success(let imageData):
                DispatchQueue.main.async {
                    strongSelf.editButton.isHidden = false
                    photo.data = imageData
                    try? strongSelf.dataController.viewContext.save()
                }


            }
        }
    }


    fileprivate func persisteContext() {
        do {
            try dataController.saveContext()

        } catch {
            let nserror = error as NSError
            fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
        }
    }

    private func setupFetchedResultController(by pin: Pin) {
        let fetchRequest:NSFetchRequest<Photo> = Photo.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "id", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchRequest.predicate = NSPredicate(format: "pin == %@", pin)

        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest,
                                                              managedObjectContext: dataController.viewContext,
                                                              sectionNameKeyPath: nil,
                                                              cacheName: nil)
        fetchedResultsController.delegate = self

        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }

    private func showErrorFromImageUrl(_ imageUrl: String) {
        if self.shouldShowAlert {
            self.showAlert(withTitle: "Error", withMessage: "Error while fetching image for URL: \(imageUrl)", action: {
                self.shouldShowAlert = true
            })
        }
        self.shouldShowAlert = false
    }
}

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        var collectionViewSize = collectionView.frame.size
        let width = collectionViewSize.width / numberOfCellByLine - cellSpace
        collectionViewSize.width = width
        collectionViewSize.height = width
        return collectionViewSize
    }
}

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {

    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        insertedIndexPaths = [IndexPath]()
        deletedIndexPaths = [IndexPath]()
        updatedIndexPaths = [IndexPath]()
    }

    func controller(
        _ controller: NSFetchedResultsController<NSFetchRequestResult>,
        didChange anObject: Any,
        at indexPath: IndexPath?,
        for type: NSFetchedResultsChangeType,
        newIndexPath: IndexPath?) {

        switch (type) {
        case .insert:
            insertedIndexPaths.append(newIndexPath!)
        case .delete:
            deletedIndexPaths.append(indexPath!)
        case .update:
            updatedIndexPaths.append(indexPath!)
        default:
            break
        }
    }

    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {

        collectionView.performBatchUpdates({() -> Void in

            for indexPath in self.insertedIndexPaths {
                self.collectionView.insertItems(at: [indexPath])
            }

            for indexPath in self.deletedIndexPaths {
                self.collectionView.deleteItems(at: [indexPath])
            }

            for indexPath in self.updatedIndexPaths {
                self.collectionView.reloadItems(at: [indexPath])
            }

        }, completion: nil)
    }
}
