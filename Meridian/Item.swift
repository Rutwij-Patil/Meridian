//
//  Item.swift
//  Meridian
//
//  Created by Rutwij on 14/04/26.
//

internal import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
