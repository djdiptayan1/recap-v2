//
//  AppState.swift
//  recap
//
//  Created by Diptayan Jash on 04/12/25.
//

import Foundation
import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var isLoggedIn: Bool = false
}
