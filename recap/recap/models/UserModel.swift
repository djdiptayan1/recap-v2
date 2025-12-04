//
//  UserModel.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation

struct UserModel: Identifiable, Codable {
    var id: String { patientUID }
    let patientUID: String
    let firstName: String
    let lastName: String
    let email: String
    let dateOfBirth: String
    let bloodGroup: String
    let sex: String
    let stage: String
    let type: String
    let profileImageURL: String
    let familyMembers: [String]?
    
    var fullName: String {
        "\(firstName) \(lastName)".trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
