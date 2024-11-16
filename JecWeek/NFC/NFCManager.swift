//
//  NFCManager.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/13/24.
//

import Foundation
import CoreNFC

final class NFCManager: NSObject ,NFCNDEFReaderSessionDelegate{
    var onCardDataUpdate: ((JsonDataModel?,Error?) -> Void)?
    private var readerSession:NFCNDEFReaderSession?
    
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: any Error) {
        print("NFC READER ERROR: \(error)")
    }
    
    
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        for message in messages{
            do{
                let nfcData = try processNFCNDEFMessage(message: message)
                onCardDataUpdate?(nfcData,nil)
            }catch{
                onCardDataUpdate?(nil,error)
            }
        }
    }
    
    private func processNFCNDEFMessage(message:NFCNDEFMessage)throws -> JsonDataModel?{
        let records = message.records
        var nfcData:JsonDataModel?
        for record in records{
            guard record.typeNameFormat == .media else{
                print("Record type is not supported")
                throw customNFCError.RecordTypeNotSupported
            }
            nfcData = try decodeRecordToNFCData(from: record.payload)
        }
        return nfcData
    }
    
    func decodeRecordToNFCData(from data:Data)throws->JsonDataModel?{
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        do {
            let nfcData =  try decoder.decode(JsonDataModel.self, from: data)
            return nfcData
        } catch let DecodingError.dataCorrupted(context) {
            print(context)
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key '\(key)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.valueNotFound(value, context) {
            print("Value '\(value)' not found:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch let DecodingError.typeMismatch(type, context)  {
            print("Type '\(type)' mismatch:", context.debugDescription)
            print("codingPath:", context.codingPath)
        } catch {
            print("error: ", error)
        }
        return nil
    }
    
    func scan(){
        guard NFCNDEFReaderSession.readingAvailable else {
            print("NFC is not available on this device")
            return
        }
        
        readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
        readerSession?.alertMessage = "Scan your NFC Card"
        readerSession?.begin()
    }
    
}


enum customNFCError:Error{
    case InvalidatedSession
    case ReaderNotAvailable
    case RecordTypeNotSupported
}
