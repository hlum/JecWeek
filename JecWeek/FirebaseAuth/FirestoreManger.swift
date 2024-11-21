//
//  FirestoreManger.swift
//  JecWeek
//
//  Created by Hlwan Aung Phyo on 11/19/24.
//

import Foundation
import FirebaseFirestore

struct DBUser:Codable{
    let uid: String
    let photoUrl:String?
    let email:String?
    let cardPossessed:[String]?
    
    
    init(uid:String,photoUrl:String?,email:String?,cardPossessed:[String]?){
        self.uid = uid
        self.photoUrl = photoUrl
        self.email = email
        self.cardPossessed = cardPossessed
    }
    
    //For the first time user
    init(for user:AuthDataResultModel){
        self.uid = user.uid
        self.photoUrl = user.photoURL
        self.email = user.email
        self.cardPossessed = nil
    }
}


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

    
    func storeUserDataInFirestoreFirstTime(userData:DBUser)throws{
        //check if the user data is already exist
        userDocuments(userId: userData.uid).getDocument { snapshot, error in
            if let snapshot = snapshot{
                print(snapshot.exists)
                return
            }
        }
        
        try userDocuments(userId: userData.uid)
            .setData(from:userData,merge:true, encoder:self.encoder)
    }
    
    
    func updateUserCardPossession(userId:String,cardId:String){
        userDocuments(userId: userId)
            .updateData(["cardPossessed":FieldValue.arrayUnion([cardId])])
    }
    
    
    func getDBUser(userId:String,completion:@escaping (DBUser?,Error?)->()){
        userDocuments(userId: userId).getDocument {
            snapShot,
            error in
            if let snapShot = snapShot{
                let data = snapShot.data()
                if let data = data{
                    do{
                        let userData = try self.decoder.decode(
                            DBUser.self,
                            from: data
                        )
                        completion(userData,nil)
                        print(userData)
                    }catch{
                        completion(nil,error)
                    }
                }
            }
        }
    }
    

    
    
}
