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
