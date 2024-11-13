//
//  NFCData.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/13/24.
//

import Foundation

struct NFCData:Identifiable,Codable {
    let id = UUID()
    let buildingNo: Int
    let images:[String]
    let buildingName:String
    let adress : String
    let date:Date
    let time:Date
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case buildingNo = "building_no"
        case buildingName = "building_name"
        case date = "date"
        case time = "time"
        case adress = "adress"
        case images = "images"
    }
}
