//
//  SoundInstanceResponse.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 27/03/21.
//

import Foundation

// MARK: - SoundInstanceResponse

struct SoundInstanceResponse: Codable {
    let id: Int
    let url: String
    let name: String
    let tags: [String]
    let welcomeDescription: String
    let geotag: JSONNull?
    let created: String
    let license: String
    let type: String
    let channels, filesize, bitrate, bitdepth: Int
    let duration: Double
    let samplerate: Int
    let username: String
    let pack, packName: JSONNull?
    let download, bookmark: String
    let previews: Previews
    let images: Images
    let numDownloads, avgRating, numRatings: Int
    let rate, comments: String
    let numComments: Int
    let comment, similarSounds: String
    let analysis: String
    let analysisFrames: String
    let analysisStats: String
    let acAnalysis: JSONNull?

    enum CodingKeys: String, CodingKey {
        case id, url, name, tags
        case welcomeDescription = "description"
        case geotag, created, license, type, channels, filesize, bitrate, bitdepth, duration, samplerate, username, pack
        case packName = "pack_name"
        case download, bookmark, previews, images
        case numDownloads = "num_downloads"
        case avgRating = "avg_rating"
        case numRatings = "num_ratings"
        case rate, comments
        case numComments = "num_comments"
        case comment
        case similarSounds = "similar_sounds"
        case analysis
        case analysisFrames = "analysis_frames"
        case analysisStats = "analysis_stats"
        case acAnalysis = "ac_analysis"
    }
}

// MARK: - Previews
struct Previews: Codable {
    let previewLqOgg: String
    let previewLqMp3: String
    let previewHqOgg: String
    let previewHqMp3: String

    enum CodingKeys: String, CodingKey {
        case previewLqOgg = "preview-lq-ogg"
        case previewLqMp3 = "preview-lq-mp3"
        case previewHqOgg = "preview-hq-ogg"
        case previewHqMp3 = "preview-hq-mp3"
    }
}
