//
//  RefreshTokenResponse.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 28/03/21.
//

import Foundation

struct RefreshTokenResponse: Codable {
    let accessToken: String
    let tokenType: String
    let scope: String
    let expiresIn: Int
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope = "scope"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}
