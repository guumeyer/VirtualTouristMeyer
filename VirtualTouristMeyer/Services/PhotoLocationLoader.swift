//
//  PhotoLocationLoader.swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/24/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import Foundation

enum PhotoLocationResult<T> {
    case success(result: T)
    case failure(error: Error)
}

/// The PhotoService is a HTTP client protocol
protocol PhotoLocationLoader {

    /// Searches photos by geolocation
    ///
    /// - Parameters:
    ///   - pin: the
    ///   - completion: The completion will perform PhotoServiceSearchResult(.sucess or failure).
    func searchPhotosByGeolocation(_ pin: Pin,
                                   completion: @escaping (PhotoLocationResult<RemotePhotos>) -> Void)
//    func searchPhotosByGeolocation(pin: Pin,
//                                   completion: @escaping (PhotoLocationResult<RemotePhotos>) -> Void)

    /// Downloads photo data
    ///
    /// - Parameters:
    ///   - photo: The `Photo`
    ///   - completion: The completion will perform PhotoServiceDownloadResult(.sucess or failure).
    func dowloadPhoto(for photo: Photo, completion: @escaping (PhotoLocationResult<Data>) -> Void)
}

// MARK: - RemotePhoto
struct RemotePhoto: Decodable {
    let id: String
    let url: String?
    let title: String

    enum CodingKeys: String, CodingKey {
        case id
        case url = "url_n"
        case title
    }
}

// MARK: - RemotePhotos
struct RemotePhotos: Decodable {
    let pages: Int
    let photo: [RemotePhoto]
}

