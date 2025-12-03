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
    var id: String
    let name: String
    let relationship: String
    let phone: String
    let email: String
    let password: String
    let imageName: String
    let imageURL: String
}
