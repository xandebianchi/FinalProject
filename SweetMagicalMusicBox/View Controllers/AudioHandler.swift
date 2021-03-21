//
//  AudioHandler.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 19/03/21.
//

import UIKit
import AVFoundation

class AudioHandler {
    
    // MARK: Alerts
    
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    
    // MARK: RecordingState (raw values correspond to sender tags)
    
    enum RecordingState: Int { case mustRecord = 1, mustNotRecord = 2 }
    
    // MARK: PlayingState (raw values correspond to sender tags)
    
    enum PlayingState: Int { case mustPlay = 1, mustNotPlay = 2 }
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var audioFile: AVAudioFile!
    var audioEngine: AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    
    // MARK: Get file path
    
    func getFilePath(recordingName: String) -> URL {
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let pathArray = [dirPath, recordingName]
        return URL(string: pathArray.joined(separator: "/") + ".wav")!
    }
    
    // MARK: Audio Functions
    
    func setupAudio(_ songName: String, completionHandler: (Error?) -> Void) {
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: getFilePath(recordingName: songName) as URL)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
    
    func playSound(completionHandler: @escaping (Double, Error?) -> Void) {
        
        // initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        audioEngine.attach(changeRatePitchNode)
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        
        // schedule to play and start the engine!
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            var delayInSeconds: Double = 0

            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
            }
            
            completionHandler(delayInSeconds, nil)
        }
        
        do {
            try audioEngine.start()
            audioPlayerNode.play()
        } catch {
            completionHandler(0.0, error)
            return
        }
    }

    // MARK: Connect List of Audio Nodes
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    // - MARK: Play individual notes
    
    func playAudioAsset(_ assetName: String) {
        guard let audioData = NSDataAsset(name: assetName)?.data else {
            fatalError("Unable to find asset \(assetName)")
        }

        do {
            audioPlayer = try AVAudioPlayer(data: audioData)
            audioPlayer.play()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
        
}
