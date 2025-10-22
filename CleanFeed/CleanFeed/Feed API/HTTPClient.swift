//
//  HTTPClient.swift
//  CleanFeed
//
//  Created by Antriksh Verma on 10/20/25.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
