//
//  URLSessionHTTPClient.swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/24/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import Foundation

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    private struct UnexpectedRepresentation: Error {}

    func makeRequest(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        print(url)
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                print(error)
                completion(.failure(error))
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedRepresentation()))
            }
        }.resume()
    }
}
