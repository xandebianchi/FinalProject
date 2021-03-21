//
//  AuthorizeResponse.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 19/03/21.
//

import Foundation

struct AuthorizeResponse: Codable {
    let accessToken: String
    let scope: String
    let expiresIn: Int
    let refreshToken: String

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case scope = "scope"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
    }
}
