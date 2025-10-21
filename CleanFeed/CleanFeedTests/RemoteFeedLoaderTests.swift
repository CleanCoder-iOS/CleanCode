//
//  RemoteFeedLoaderTests.swift
//  CleanFeedTests
//
//  Created by Antriksh Verma on 10/20/25.
//

/*
 Load Feed From Remote Use Case
 
 Data:
  - URL
 
 Primary course (happy path):
 1. Execute 'Load Feed' command with above data.
 2. System downloads data from the URL.
 3. System validates downloaded data.
 4. System creates feed items from valid data.
 5. System delivers feed items.
 
 Invalid Data - Error course (sad path):
 1. System delivers error (invalid data)
 
 No Connectivity - Error course (sad path):
 1. System delivers error (no connectivity error)
 
 */

import XCTest

protocol HTTPClient {}

class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
}

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let client = HTTPClientSpy()
        _ = RemoteFeedLoader(url: url, client: client)
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    // MARK: - Helpers
    
    class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] = []
    }
}
