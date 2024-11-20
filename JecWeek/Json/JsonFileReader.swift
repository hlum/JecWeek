//
//  JsonFileReader.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/14/24.
//

import Foundation

final class JsonFileReader {
    // Path to file
    private let fileName = "placeData.json"
    static let shared = JsonFileReader()
    
    func loadPlaceData() -> [JsonDataModel]? {
        guard let fileURL = Bundle.main.url(forResource: fileName, withExtension: nil) else {
            print("File not found: \(fileName)")
            return nil
        }
        
        do {
            // Read data from the file
            let data = try Data(contentsOf: fileURL)
            
            // Decode the data using JSONDecoder
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let placeData = try decoder.decode([JsonDataModel].self, from: data)
            
            return placeData
        } catch {
            print("Failed to load or decode JSON: \(error)")
            return nil
        }
    }
}
