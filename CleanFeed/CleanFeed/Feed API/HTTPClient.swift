//
//  HTTPClient.swift
//  CleanFeed
//
//  Created by Antriksh Verma on 10/20/25.
//

import Foundation

public protocol HTTPClient {
    func get(from url: URL)
}
