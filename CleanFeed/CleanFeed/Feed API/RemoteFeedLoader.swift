//
//  RemoteFeedLoader.swift
//  CleanFeed
//
//  Created by Antriksh Verma on 10/20/25.
//

import Foundation


public enum RemoteFeedLoaderError: Equatable, Error {
    case connectivityError
}

public enum RemoteFeedLoaderResult: Equatable {
    case success([FeedItem])
    case failure(RemoteFeedLoaderError)
}

public class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping (RemoteFeedLoaderResult) -> Void = { _ in }) {
        client.get(from: url) { result in
            switch result {
            case .success:
                completion(.failure(.invalidData))
            case .failure:
                completion(.failure(.connectivityError))
            }
        }
    }
}
