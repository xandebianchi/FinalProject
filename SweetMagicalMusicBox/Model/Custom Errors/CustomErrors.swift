//
//  CustomErrors.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 19/03/21.
//

import Foundation

// MARK: - AppError

struct AppError: Error {
    let message: String

    init(message: String) {
        self.message = message
    }
}
