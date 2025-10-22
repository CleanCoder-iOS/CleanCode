//
//  FeedItem.swift
//  CleanFeed
//
//  Created by Antriksh Verma on 10/20/25.
//

import Foundation

public struct FeedItem: Equatable {
    private let id: UUID
    private let description: String?
    private let location: String?
    private let imageURL: URL
}
