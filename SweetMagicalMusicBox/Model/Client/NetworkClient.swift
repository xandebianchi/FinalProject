//
//  NetworkClient.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 14/03/21.
//

import Foundation
import UIKit
import Alamofire
import CurlDSL

class NetworkClient {
    
    // MARK: - Declarations
    
    enum Endpoints {
        static let base = "https://www.freesound.org/apiv2"
        static let register = "https://freesound.org/apiv2/apply"
        static let authorize = "/oauth2/authorize"
        static let access = "/oauth2/access_token"
        static let upload = "/sounds/upload/"
        
        case authorization(_ clientId: String)
        case getAccessToken(_ authorizationCode: String, _ clientId: String, _ clientSecret: String)
        case uploadSong
        
        var stringValue: String {
            switch self {
            case .authorization(let clientId):
                return Endpoints.base + Endpoints.authorize + "?client_id=\(clientId)&response_type=code&state=freesoundkit"
            case .getAccessToken(let authorizationCode, let clientId, let clientSecret):
                return Endpoints.base + Endpoints.access + "?client_id=\(clientId)&client_secret=\(clientSecret)&grant_type=authorization_code&code=\(authorizationCode)"
            case .uploadSong:
                return Endpoints.base + Endpoints.upload // + "?name=\(name)&description=\(name)&tags=SweetMagicalMusicBox%20Udacity%20iOSNanodegree&license=Creative%20Commons%200"
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
                        completion(nil, AppError(message: "It was not possible to get information. Try again."))
                    }
                }
            }
        }
        task.resume()
    }
    
    class func getAccessToken(_ authorizationCode: String, _ clientId: String, _ clientSecret: String, completion: @escaping (String?, Error?) -> Void) {
        taskForPOSTRequest(url: Endpoints.getAccessToken(authorizationCode, clientId, clientSecret).url, responseType: AuthorizeResponse.self) { (response, error) in
            if let response = response {                
                completion(response.accessToken, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    struct HTTPBinResponse: Decodable { let details: String? }
    
    class func upload(url: URL, name: String, accessToken: String, completion: @escaping (Bool, Error?) -> Void) {
        
        let boundary = "Boundary-\(UUID().uuidString)"
        
        // TODO USING CURL
        
        do {
            try CURL("curl -X POST -H \"Authorization: Bearer \(accessToken)\" -H \"Content-Type: multipart/form-data; boundary=\(boundary)\" -F audiofile=@\"file://\(url)\" -F \"name=\(name)\" -F \"tags=field-recording birds nature h4n\" -F \"description=This sound was recorded...<br>bla bla bla...\" -F \"license=Attribution\" \"https://freesound.org/apiv2/sounds/upload/\"").run { data, response, error in
                print(response)
            }
        } catch {
            print(error)
        }
        
        // TODO USING ALAMOFIRE
        
//        let recordingData: Data? = try? Data(contentsOf:URL(string: "file://\(url.absoluteString)")!)
//        AF.upload(multipartFormData: { multipartFormData in
//            multipartFormData.append(recordingData!, // the audio as Data
//                                     withName: name,
//                                     fileName: name + ".wav", // name of the file
//                                     mimeType: "audio/x-wav")
//            multipartFormData.append(name.data(using: .utf8)!, withName: "name")
//            multipartFormData.append(name.data(using: .utf8)!, withName: "description")
//            multipartFormData.append("SweetMagicalMusicBox Udacity iOSNanodegree".data(using: .utf8)!, withName: "tags")
//            multipartFormData.append("Creative Commons 0".data(using: .utf8)!, withName: "license")
//        }, to: Endpoints.upload(name).url, headers: ["Authorization": "Bearer \(Endpoints.Auth.accessToken)"])
//            .uploadProgress { progress in
//                print("Upload Progress: \(progress.fractionCompleted)")
//            }
//            .downloadProgress { progress in
//                print("Download Progress: \(progress.fractionCompleted)")
//            }
//            .responseDecodable(of: HTTPBinResponse.self) { response in
//                debugPrint(response)
//            }
//        .cURLDescription { description in
//            print(description)
//        }
        
          // Another try
         
//        AF.upload(url, to: Endpoints.upload(name).url, headers: ["Authorization": "Bearer \(Endpoints.Auth.accessToken)"])
//            .uploadProgress { progress in
//                print("Upload Progress: \(progress.fractionCompleted)")
//            }
//            .downloadProgress { progress in
//                print("Download Progress: \(progress.fractionCompleted)")
//            }
//            .responseDecodable(of: HTTPBinResponse.self) { response in
//                debugPrint(response)
//            }
        
            
          // Trying using URLSession
        
//        let apiURL = Endpoints.upload(name).url
//        let recordingData: Data? = try? Data(contentsOf:URL(string: "file://\(url)")!)
//        let boundary = "Boundary-\(UUID().uuidString)"
//        let startBoundary = "--\(boundary)"
//        let endingBoundary = "--\(boundary)--"
//
//        // getting the fileName
//        let urlStr = "\(url)"
//        let pathArr = urlStr.components(separatedBy: "/")
//        let fileName = pathArr.last
//
//        var body = Data()
//        var header = "Content-Disposition: form-data; name=\"\(fileName)\"; filename=\"file://\(url)\"\r\n"
//
//        body.append(("\(startBoundary)\r\n" as String).data(using:.utf8)!)
//        body.append((header as String).data(using:.utf8)!)
//        body.append(("Content-Type: audio/wav\r\n\r\n" as String).data(using:.utf8)!)
//        body.append(recordingData!)
//        body.append(("\r\n\(endingBoundary)\r\n" as String).data(using:.utf8)!)
//
//        var request = URLRequest(url: apiURL)
//        request.httpMethod = "POST"
//        request.setValue("Bearer \(Endpoints.Auth.accessToken)", forHTTPHeaderField: "Authorization")
//        request.setValue("multipart/form-data;boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
//        request.setValue("*/*",forHTTPHeaderField: "Accept")
//
//        let session = URLSession.shared
//
//        let task = session.dataTask(with: request){ (data, response,error) in
//            print("Upload complete!")
//
//            if let error = error{
//                print("error: \(error)")
//                return
//            }
//
//            guard let response = response as? HTTPURLResponse,
//                (200...299).contains(response.statusCode) else {
//                    print("Error on server side!")
//
//                    return
//            }
//
//            if let mimeType = response.mimeType,
//            mimeType == "audio/wav",
//            let data = data,
//                let dataStr = String(data: data, encoding: .utf8){
//                print("data is \(dataStr)")
//            }
//        }
//        task.resume()
//        taskForPOSTRequestAudio(url: Endpoints.upload(name).url, audio: URL, addAuthorizationHeader: true, responseType: AuthorizeResponse.self) { (response, error) in
//            if let response = response {
//                completion(true, nil)
//            } else {
//                completion(false, error)
//            }
//        }
//        let uploadUrlString = Endpoints.upload(name).url

          // Trying with AlamoFire with POST
        
//        AF.upload(url, to: uploadUrlString, headers: ["Authorization": "Bearer \(Endpoints.Auth.accessToken)"]).responseJSON { response in
//            print(response)
//            //let responseData = response.result as? [String: Any]
//            //handler(responseData)
//        }
    }
    
}
