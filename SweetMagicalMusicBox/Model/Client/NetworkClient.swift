//
//  NetworkClient.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 14/03/21.
//

import Foundation
import UIKit
import Alamofire

class NetworkClient {
    
    // MARK: - Constants
    
    struct Constants {
        static let NotPossibleToGetInformation = "It was not possible to get information. Try again."
        static let NotPossibleToGetModerationStatusFromFreeSounds = "It was not possible to get moderation status from FreeSounds."
        static let NotPossibleToGetSongURLToBeShared = "It was not possible to get song URL to be shared."
    }
    
    // MARK: - Declarations
    
    enum Endpoints {
        static let base = "https://freesound.org/apiv2"
        static let register = "https://freesound.org/apiv2/apply"
        static let authorize = "/oauth2/authorize"
        static let access = "/oauth2/access_token"
        static let upload = "/sounds/upload/"
        static let pendingUploads = "/sounds/pending_uploads/"
        static let soundInstance = "/sounds/"
        
        case authorization(_ clientId: String)
        case getAccessToken(_ authorizationCode: String, _ clientId: String, _ clientSecret: String)
        case getRefreshToken(_ refreshToken: String, _ clientId: String, _ clientSecret: String)
        case uploadSong
        case getPendingUploads
        case getSoundInstance(_ soundId: String)
        
        var stringValue: String {
            switch self {
            case .authorization(let clientId):
                return Endpoints.base + Endpoints.authorize + "?client_id=\(clientId)&response_type=code&state=freesoundkit"
            case .getAccessToken(let authorizationCode, let clientId, let clientSecret):
                return Endpoints.base + Endpoints.access + "?client_id=\(clientId)&client_secret=\(clientSecret)&grant_type=authorization_code&code=\(authorizationCode)"
            case .getRefreshToken(let refreshToken, let clientId, let clientSecret):
                return Endpoints.base + Endpoints.access + "?client_id=\(clientId)&client_secret=\(clientSecret)&grant_type=refresh_token&refresh_token=\(refreshToken)"
            case .uploadSong:
                return Endpoints.base + Endpoints.upload
            case .getPendingUploads:
                return Endpoints.base + Endpoints.pendingUploads
            case .getSoundInstance(let soundId):
                return Endpoints.base + Endpoints.soundInstance + "\(soundId)/"
            }
        }

        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    static public func authorize(_ clientId: String, handler: @escaping () -> ()) {       
        openURL(from: Endpoints.base + Endpoints.authorize + "?client_id=\(clientId)&response_type=code&state=freesoundkit", handler: handler)
    }

    static func openURL(from string: String,
                                    handler: @escaping () -> ()) {
        if let url = URL(string: string) {
            UIApplication.shared.open(url, options: [:], completionHandler: { _ in
                handler()
            })
        }
    }

    class func taskForGETRequest<ResponseType: Decodable>(url: URL, accessToken: String, response: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> Void {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
    }
    
    class func taskForPOSTRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorResponse = try decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorResponse)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, AppError(message: Constants.NotPossibleToGetInformation))
                    }
                }
            }
        }
        task.resume()
    }
    
    class func getAccessToken(_ authorizationCode: String, _ clientId: String, _ clientSecret: String, completion: @escaping (AuthorizeResponse?, Error?) -> Void) {
        taskForPOSTRequest(url: Endpoints.getAccessToken(authorizationCode, clientId, clientSecret).url, responseType: AuthorizeResponse.self) { (response, error) in
            if let response = response {                
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    class func getRefreshToken(_ refreshToken: String, _ clientId: String, _ clientSecret: String, completion: @escaping (AuthorizeResponse?, Error?) -> Void) {
        taskForPOSTRequest(url: Endpoints.getRefreshToken(refreshToken, clientId, clientSecret).url, responseType: AuthorizeResponse.self) { (response, error) in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
        
    class func upload(url: URL, name: String, accessToken: String, completion: @escaping (Int32?, Error?) -> Void) {
        let recordingData: Data? = try? Data(contentsOf:URL(string: "file://\(url.absoluteString)")!)
        let description = "This song \(name) is being used to validate a project from Udacity iOS Nanodegree."
        AF.upload(multipartFormData: { multipartFormData in
            multipartFormData.append(recordingData!, // the audio as Data
                                     withName: "audiofile", // need for FreeSounds
                                     fileName: name + ".wav", // name of the file
                                     mimeType: "application/octet-stream")
            multipartFormData.append(name.data(using: .utf8)!, withName: "name")
            multipartFormData.append(description.data(using: .utf8)!, withName: "description")
            multipartFormData.append("SweetMagicalMusicBox Udacity iOSNanodegree".data(using: .utf8)!, withName: "tags")
            multipartFormData.append("Creative Commons 0".data(using: .utf8)!, withName: "license")
        }, to: Endpoints.uploadSong.url, headers: ["Authorization": "Bearer \(accessToken)"]) 
            .responseDecodable(of: UploadResponse.self) { response in
                switch response.result {
                case .success:
                    completion(response.value!.id, nil)
                case let .failure(error):
                    completion(nil, error)
                }
            }
    }
    
    class func getPendingUploads(accessToken: String, completion: @escaping (PendingUploadResponse?, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getPendingUploads.url, accessToken: accessToken, response: PendingUploadResponse.self) { (response, _) in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, AppError(message: Constants.NotPossibleToGetModerationStatusFromFreeSounds))
            }
        }
    }
    
    class func getSoundInstance(soundId: String, accessToken: String, completion: @escaping (String?, Error?) -> Void) {
        taskForGETRequest(url: Endpoints.getSoundInstance(soundId).url, accessToken: accessToken, response: SoundInstanceResponse.self) { (response, _) in
            if let response = response {
                completion(response.url, nil)
            } else {
                completion(nil, AppError(message: Constants.NotPossibleToGetSongURLToBeShared))
            }
        }
    }
    
}
