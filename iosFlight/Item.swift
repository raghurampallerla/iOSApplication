//
//  Item.swift
//  iosFlight
//
//  Created by RAGHURAM PALLERLA on 08/01/2026.
//

import Foundation
import SwiftData

@available(iOS 17, *)
@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
