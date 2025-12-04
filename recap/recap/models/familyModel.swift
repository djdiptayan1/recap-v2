//
//  FamilyDataModel.swift
//  recap
//
//  Created by Diptayan Jash on 05/11/24.
//

import Foundation
import SwiftUI

enum RelationshipCategory: String, Codable, CaseIterable {
    case Son, Daughter, Husband, Wife, Father, Mother, Brother, Sister
}

struct FamilyMember: Codable, Identifiable, Equatable {
    let id: String
    let name: String
    let relation: String
    let phone: String
    let email: String
    let imageURL: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case relation
        case phone
        case email
        case imageURL
    }
}

struct FamilyMemberResponse: Codable {
    let success: Bool
    let data: [FamilyMember]
    let count: Int
}
