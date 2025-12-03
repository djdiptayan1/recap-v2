//
//  patientModel.swift
//  recap
//
//  Created by Diptayan Jash on 03/12/25.
//

import Foundation

struct patientModel: Codable {
    var firstName: String
    var lastName: String
    let patientUID: String
    var dateOfBirth: String
    var sex: String
    var bloodGroup: String
    var stage: String
    var profileImageURL: String?
    var id: String
    var email: String

    init(firstName: String = "",
         lastName: String = "",
         patientUID: String = "",
         dateOfBirth: String = "",
         sex: String = "",
         bloodGroup: String = "",
         stage: String = "",
         profileImageURL: String? = nil,
         email: String = "",
         id: String) {
        self.id = UUID().uuidString
        self.firstName = firstName
        self.lastName = lastName
        self.patientUID = patientUID
        self.dateOfBirth = dateOfBirth
        self.sex = sex
        self.bloodGroup = bloodGroup
        self.stage = stage
        self.profileImageURL = profileImageURL
        self.id = id
        self.email = email
    }

    static let userDefaultsKey = "patientProfile"
}

enum SexOptions: String, Codable, CaseIterable {
    case Male
    case Female
    case Other
}

enum BloodGroupOptions: String, Codable, CaseIterable {
    case APlus = "A+"
    case AMinus = "A-"
    case BPlus = "B+"
    case BMinus = "B-"
    case OPlus = "O+"
    case OMinus = "O-"
    case ABPlus = "AB+"
    case ABMinus = "AB-"
}

enum StageOptions: String, Codable, CaseIterable {
    case Early
    case Middle
    case Advanced
}
