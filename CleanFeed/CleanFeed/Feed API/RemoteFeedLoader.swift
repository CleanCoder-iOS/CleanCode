//
//  RemoteFeedLoader.swift
//  CleanFeed
//
//  Created by Antriksh Verma on 10/20/25.
//

import Foundation

public class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load() {
        client.get(from: url)
    }
}
