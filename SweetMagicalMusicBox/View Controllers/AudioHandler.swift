//
//  AudioHandler.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 19/03/21.
//

import UIKit
import AVFoundation

class AudioHandler {
    
    // MARK: - Constants
    
    struct Constants {
        static let NoMicrophonePermission = "No Microphone Permission"
        static let MicrophoneNecessaryGoToSettingsQuestion = "Microphone is necessary for the app to work. Go to settings to enable this permission for the app?"
        static let RecordingNotSuccessFull = "It was not possible to recording. Try again."
        static let RecordingError = "Recording Error"
        static let ErrorPlaySong = "Error to Play Song"
        static let ErrorRecordSong = "Error to Record Song"
        static let SongName = "Song Name"
        static let SongNameQuestion = "What is the name of your song?"
        static let SongNameEmpty = "Song Name Empty"
        static let SongNameMustNotBeEmpty = "The song name must not be empty."
        static let SongNameExists = "Song Name Already Exists"
        static let ChooseAnotherName = "Choose another name for the song."
        static let SongUnderRecording = "Song Under Recording"
        static let StopTheSongRecording = "Stop the song recording to save it."
        static let UseSpeaker = "Use Speaker"
        static let ReminderUseSpeaker = "This app use the speaker to play sounds. Remove any headphone to play here."
        static let Error = "Error"
        static let CouldNotGetListSongs = "Couldn't get the list of songs. Try again."
        static let GetAuthorizationCode = "Get Authorization Code"
        static let AuthorizeAndCopyCode = "Click to go to FreeSound authorization screen. Authorize FreeSound and copy Authorization Code to clipboard!"
        static let EnterAuthorizationCode = "Enter Authorization Code"
        static let CopyAuthorizationCodeHere = "Please copy Authorization Code here."
        static let ErrorGetCodeQuestion = "Error to Get Code?"
        static let CodeEmpty = "Code Empty"
        static let LoginCopyAuthorizationCode = "Login and copy the Authorization Code."
        static let ErrorLogin = "Error to Login"
        static let TryLoginAgainAuthorizationCodeWrong = "Try Login again. It's possible that the Authorization Code was copied wrong."
        static let LoginExpiration = "Login Expiration"
        static let NeedToLoginAgain = "Need to login again."
        static let PlayingSong = "Playing Song"
        static let WaitUntilSongFinishesOrStopCurrentSong = "Wait until the song finishes or stop current song."
        static let AlreadyUploaded = "Already Uploaded"
        static let AlreadyUploadedToFreeSounds = "This song was already upload to FreeSounds."
        static let SongUploaded = "Song Uploaded"
        static let Song = "Song"
        static let SongWillBeModerated = "was upload to FreeSounds. Now it will be moderated by their team and after this you can share it."
        static let ErrorUpload = "Error to Upload"
        static let ErrorUploadTryLater = "There was an error to upload the song. Try later."
        static let NotShared = "Not Shared"
        static let FirstUploadToShareIt = "You must first upload the song to share it."
        static let MyNewSongCreateWithSweetMagicalMusicBox = "This is my new song create with SweetMagicalMusicBox."
        static let ErrorShare = "Error to Share"
        static let CantExitNow = "Can't Exit Now"
        static let WaitUntilFileUploaded = "Wait until the file is uploaded."
        static let WaitUntilFileShared = "Wait until the file is shared."
        static let SongProcessing = "Song Processing"
        static let SongProcessingNecessaryWait = "The song is being processed by FreeSounds, it's necessary to wait."
        static let SongModerating = "Song Being Moderated"
        static let SongModeratingNecessaryWait = "The song is in moderation by FreeSounds, it's necessary to wait."
        static let Register = "Register"
        static let Login = "Login"
        static let LoggedIn = "Logged In"
        static let CopyAllFields = "Copy All Fields"
        static let StepsToRegister = "You must copy the both fields from FreeSounds. Follow step below to register a new API to use FreeSounds and copy the codes in the fields below."
        static let NeedRegister = "Need to Register"
        static let NeedRegisterFreeSounds = "Click above the screen to Register in FreeSounds. After register, request access credentials."
        static let NeedLogin = "Need to Login"
        static let NeedLoginFreeSounds = "Click above the screen to Login into FreeSounds."
        static let notesFileNameArray = ["do-c", "re-d", "mi-e", "fa-f", "sol-g", "la-a", "si-b"]
        static let notesColorArray = [UIColor.red, UIColor.green, UIColor.blue, UIColor.orange, UIColor.systemYellow, UIColor.cyan, UIColor.magenta]
        static let notesAnimationDuration = [0.9, 1.2, 1.1, 1.0, 1.4, 1.5, 1.3]
    }
    
    // MARK: - RecordingState (raw values correspond to sender tags)
    
    enum RecordingState: Int { case isRecording = 1, isNotRecording = 2 }
    
    // MARK: - PlayingState (raw values correspond to sender tags)
    
    enum PlayingState: Int { case isPlaying = 1, isNotPlaying = 2 }
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer!
    var audioFile: AVAudioFile!
    var audioEngine: AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    
    // MARK: - Get file path
    
    static func getFilePath(recordingName: String) -> URL {
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let pathArray = [dirPath, recordingName]
        return URL(string: pathArray.joined(separator: "/") + ".wav")!
    }
    
    // MARK: - Audio Functions
    
    func setupAudio(_ songName: String, completionHandler: (Error?) -> Void) {
        do {
            audioFile = try AVAudioFile(forReading: AudioHandler.getFilePath(recordingName: songName) as URL)
            completionHandler(nil)
        } catch {
            completionHandler(error)
        }
    }
    
    func playSong(completionHandler: @escaping (Double, Error?) -> Void) {
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

    // MARK: - Connect List of Audio Nodes
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    // MARK: - Play individual notes
    
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
    
    // MARK: - Auxiliar methods
    
    static public func isAuthorized() -> Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }
    
    static func hasMicrophonePermission(completion: @escaping (UIAlertController?) -> Void) {
        if !AudioHandler.isAuthorized() {
            let alert = UIAlertController(title: "\(Constants.NoMicrophonePermission)", message: Constants.MicrophoneNecessaryGoToSettingsQuestion, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                UIAlertAction in
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel)
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            completion(alert)
        } else {
            completion(nil)
        }
    }
        
}
