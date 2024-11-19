//
//  FirestoreManger.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/19/24.
//

import Foundation
import FirebaseFirestore


class FirestoreManger{
    static let shared = FirestoreManger()
    let userCollection = Firestore.firestore().collection("users")
    
    private func userDocuments(userId:String) -> DocumentReference{
        userCollection.document(userId)
    }

    private let encoder:Firestore.Encoder = {
        let encoder = Firestore.Encoder()
        return encoder
    }()
    
    private let decoder : Firestore.Decoder = {
        let decoder = Firestore.Decoder()
        return decoder
    }()

    
    func storeUserDataInFirestore(userData:AuthDataResultModel)throws{
        try userDocuments(userId: userData.uid)
            .setData(from:userData,encoder:self.encoder)
    }
}
