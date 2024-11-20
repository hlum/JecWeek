//
//  NFCData.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/13/24.
//

import Foundation

struct JsonDataModel:Identifiable,Codable {
    let id :String
    let buildingNo:Int
    let images:[String]
    let buildingName:String
    let adress : String
    let date:Date
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case buildingNo = "building_no"
        case buildingName = "building_name"
        case date = "date"
        case adress = "adress"
        case images = "images"
    }
}
