//
//  ErrorResponse.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 19/03/21.
//

import Foundation

struct ErrorResponse: Codable {
    let details: String
}

extension ErrorResponse: LocalizedError {
    var errorDescription: String? {
        return details
    }
}
