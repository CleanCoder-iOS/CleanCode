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
import CleanFeed

final class RemoteFeedLoaderTests: XCTestCase {

    func test_init_doesNotRequestDataFromURL() {
        let (_, client) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(with: url)
        
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(with: url)
        
        sut.load { _ in }
        sut.load { _ in }
        
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_load_deliversErrorOnClientError() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(with: url)
        var capturedResults = [RemoteFeedLoaderResult]()
        
        sut.load { capturedResults.append($0) }
        client.completeWith(error: clientError())
        
        XCTAssertEqual(capturedResults, [.failure(.connectivityError)])
    }
    
    func test_load_deliversErrorOnNon200HTTPStatusCode() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(with: url)
        let samples = [199, 200, 201, 300, 400, 500]
        
        samples.enumerated().forEach { index, code in
            var capturedResults = [RemoteFeedLoaderResult]()
            sut.load { capturedResults.append($0) }
            client.completeWith(statusCode: code, at: index)
            XCTAssertEqual(capturedResults, [.failure(.invalidData)])
        }
    }
    
    func test_load_deliversErrorOn200HTTPStatusCodeWithInvalidJSON() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(with: url)
        var capturedResults = [RemoteFeedLoaderResult]()
        
        sut.load { capturedResults.append($0) }
        client.completeWith(statusCode: 200, data: invalidJSONData())
        
        XCTAssertEqual(capturedResults, [.failure(.invalidData)])
    }
    
    func test_load_deliversEmptyFeedOn200HTTPStatusCodeWithEmptyJSONList() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(with: url)
        var capturedResults = [RemoteFeedLoaderResult]()
        
        sut.load { capturedResults.append($0) }
        client.completeWith(statusCode: 200, data: emptyJSONListData())
        
        XCTAssertEqual(capturedResults, [.success([])])
    }
    
    func test_load_deliversFeedOn200HTTPStatusCodeWithNonEmptyJSONList() {
        let url = URL(string: "https://a-given-url.com")!
        let (sut, client) = makeSUT(with: url)
        var capturedResults = [RemoteFeedLoaderResult]()
        
        sut.load { capturedResults.append($0) }
        
        let feedItem1 = makeFeedItem(id: UUID(), description: nil, location: nil, imageURL: URL(string: "https://image-1-url.com")!)
        let feedItem2 = makeFeedItem(id: UUID(), description: "second description", location: nil, imageURL: URL(string: "https://image-2-url.com")!)
        let feedItem3 = makeFeedItem(id: UUID(), description: nil, location: "third location", imageURL: URL(string: "https://image-3-url.com")!)
        let feedItem4 = makeFeedItem(id: UUID(), description: "fourth description", location: "fourth location", imageURL: URL(string: "https://image-4-url.com")!)
        
        let jsonList = ["items" : [feedItem1.json, feedItem2.json, feedItem3.json, feedItem4.json]]
        let feed = [feedItem1.model, feedItem2.model, feedItem3.model, feedItem4.model]
        
        let data = try! JSONSerialization.data(withJSONObject: jsonList)
        client.completeWith(statusCode: 200, data: data)
        
        XCTAssertEqual(capturedResults, [.success(feed)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(with url: URL = URL(string: "https://any-url.com")!) -> (sut: RemoteFeedLoader, client: HTTPClientSpy) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        return (sut, client)
    }
    
    private func clientError() -> Error {
        NSError(domain: "HTTPClient error", code: 0)
    }
    
    private func invalidJSONData() -> Data {
        Data(bytes: "invalid json", count: 0)
    }
    
    private func emptyJSONListData() -> Data {
        "{ \"items\" : [] }".data(using: .utf8)!
    }
    
    private func makeFeedItem(id: UUID, description: String?, location: String?, imageURL: URL) -> (model: FeedItem, json: [String: String]) {
        let model = FeedItem(id: id, description: description, location: location, imageURL: imageURL)
        let json : [String: String] = [ "id" : id.uuidString,
                                     "description" : description,
                                     "location" : location,
                                     "image" : imageURL.absoluteString].compactMapValues { $0 }
        return (model, json)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs = [URL]()
        var completions = [(HTTPClientResult) -> Void]()
 
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            requestedURLs.append(url)
            completions.append(completion)
        }
        
        func completeWith(error: Error, at index: Int = 0) {
            completions[index](.failure(error))
        }
        
        func completeWith(statusCode: Int, data: Data = Data(), at index: Int = 0, file: StaticString = #file, line: UInt = #line) {
            guard let httpURLResponse = HTTPURLResponse(url: requestedURLs[index],
                                                        statusCode: statusCode,
                                                        httpVersion: nil,
                                                        headerFields: nil) else {
                return XCTFail("Invalid HTTPURLResponse", file: file, line: line)
            }
            
            completions[index](.success(data, httpURLResponse))
        }
    }
}
