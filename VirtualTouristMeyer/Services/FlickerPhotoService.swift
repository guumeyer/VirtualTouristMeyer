//
//  FlickerPhotoService.swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/24/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import Foundation

final class FlickerPhotoService: PhotoLocationLoader {
    private static let serverUrl = "https://www.flickr.com"

    private let apiKey = "26aa2574c9d4b36da1f80ecde89df88e"
    private let client: HTTPClient
    private let restApiUrl = "\(serverUrl)/services/rest"
    private let photosPerPage = 21
 
    init(client: HTTPClient) {
        self.client = client
    }

    public enum Error: LocalizedError {
        case connectivity
        case invalidData
        case invalidInputData

        public var errorDescription: String? {
            switch self {
            case .connectivity:
                return "The internet connection appears to be offline."
            case .invalidData:
                return "Invalid data"
            case .invalidInputData:
                return "Invalid input data"
            }
        }
    }

    func searchPhotosByGeolocation(_ pin: Pin,
                                   completion: @escaping (PhotoLocationResult<RemotePhotos>) -> Void) {

        guard let url = buildSearchPhotosURL(pin.latitude, pin.longitude, Int(pin.pages))  else {
            completion(.failure(error: Error.invalidInputData))
            return
        }

        client.makeRequest(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .success(data, response):
                completion(FlickerPhotoService.mapToPhotoLocationResult(data, from: response))
            case .failure:
                completion(.failure(error: Error.connectivity))
            }
        }
    }

    func dowloadPhoto(for photo: Photo, completion: @escaping (PhotoLocationResult<Data>) -> Void) {

        guard let urlString = photo.url, let url = URL(string: urlString) else {
            completion(.failure(error: Error.invalidInputData))
            return
        }

        client.makeRequest(from: url) { [weak self] result in
            guard self != nil else { return }
            switch result {
            case let .success(data, response):
                completion(FlickerPhotoService.mapToData(data, from: response))
            case .failure:
                completion(.failure(error: Error.connectivity))
            }
        }
    }

    private func buildSearchPhotosURL(_ latitude: Double, _ longitude: Double, _ totalPages: Int) -> URL? {

        var page: Int {
            if totalPages > 0 {
                let page = min(totalPages, 4000 / photosPerPage)
                return Int(arc4random_uniform(UInt32(page)) + 1)
            }
            return 1
        }

        var urlComponent = URLComponents(string: restApiUrl)!
        urlComponent.queryItems = [
            URLQueryItem(name: "method", value: "flickr.photos.search"),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "lat", value: "\(latitude)"),
            URLQueryItem(name: "lon", value: "\(longitude)"),
            URLQueryItem(name: "per_page", value: "\(photosPerPage)"),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "page", value: "\(page)"),
            URLQueryItem(name: "nojsoncallback", value: "1"),
            URLQueryItem(name: "extras", value: "url_n")
            ] as [URLQueryItem]

        return  urlComponent.url
    }

    private static func mapToPhotoLocationResult(_ data: Data,
                                    from response: HTTPURLResponse) -> PhotoLocationResult<RemotePhotos> {

        guard response.statusCode == 200,
            let result = try? JSONDecoder().decode(FlickerResult.self, from: data) else  {
                return .failure(error: Error.invalidData)
        }

        return .success(result: result.photos)
    }

    private static func mapToData(_ data: Data,
                                  from response: HTTPURLResponse) -> PhotoLocationResult<Data> {

        guard response.statusCode == 200,
            !data.isEmpty else  {
            return .failure(error: Error.invalidData)
        }

        return .success(result: data)
    }

}

