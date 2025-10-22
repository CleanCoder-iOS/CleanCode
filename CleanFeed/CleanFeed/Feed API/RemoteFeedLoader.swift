//
//  RemoteFeedLoader.swift
//  CleanFeed
//
//  Created by Antriksh Verma on 10/20/25.
//

import Foundation

struct RemoteFeedItem: Equatable, Codable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}

struct RemoteFeed: Equatable, Codable {
    private let items: [RemoteFeedItem]
    
    func toFeedItems() -> [FeedItem] {
        items.map {
            FeedItem(
                id: $0.id,
                description: $0.description,
                location: $0.location,
                imageURL: $0.image
            )
        }
    }
}

public enum RemoteFeedLoaderError: Equatable, Error {
    case invalidData
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
    
    public func load(completion: @escaping (RemoteFeedLoaderResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let _ = self else { return }
            
            switch result {
            case let .success(data, response):
                guard response.statusCode == 200,
                      let remoteFeed = try? JSONDecoder().decode(RemoteFeed.self, from: data) else {
                    return completion(.failure(.invalidData))
                }
                completion(.success(remoteFeed.toFeedItems()))
            case .failure:
                completion(.failure(.connectivityError))
            }
        }
    }
}
