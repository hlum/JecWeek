//
//  NFCData.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/13/24.
//

import Foundation

import Foundation
import CoreLocation

struct JsonDataModel: Identifiable, Codable {
    let id: String
    let buildingNo: Int
    let images: [String]
    let buildingName: String
    let adress: String
    let date: Date
    let coordinates: Coordinates
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case buildingNo = "building_no"
        case buildingName = "building_name"
        case adress = "adress"
        case date = "date"
        case images = "images"
        case coordinates = "coordinates"
    }
}

struct Coordinates: Codable {
    let latitude: Double
    let longitude: Double
}
