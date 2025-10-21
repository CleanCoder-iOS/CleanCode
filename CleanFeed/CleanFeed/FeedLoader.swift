//
//  FeedLoader.swift
//  CleanFeed
//
//  Created by Antriksh Verma on 10/20/25.
//

import Foundation

enum LoadFeedResult {
    case success([FeedItem])
    case failure(Error)
}

protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
