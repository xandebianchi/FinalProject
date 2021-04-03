//
//  MainViewController.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 02/03/21.
//

import UIKit
import AVFoundation
import CoreData

class MainViewController: UIViewController, AVAudioRecorderDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var buttonNote1: UIButton!
    @IBOutlet weak var buttonNote2: UIButton!
    @IBOutlet weak var buttonNote3: UIButton!
    @IBOutlet weak var buttonNote4: UIButton!
    @IBOutlet weak var buttonNote5: UIButton!
    @IBOutlet weak var buttonNote6: UIButton!
    @IBOutlet weak var buttonNote7: UIButton!
    @IBOutlet weak var buttonRecordStopSong: UIBarButtonItem!
    @IBOutlet weak var buttonPlayStopSong: UIBarButtonItem!
    @IBOutlet weak var buttonSong: UIBarButtonItem!
    @IBOutlet weak var navBar: UINavigationBar!
    
    // MARK: - Properties

    var audioHandler: AudioHandler!
    var currentSongName: String = ""
    var stopTimer: Timer!
    var notesColorArrayShuffled = AudioHandler.Constants.notesColorArray.shuffled()
    var notesFileNameArrayShuffled = AudioHandler.Constants.notesFileNameArray.shuffled()
    var notesAnimationDurationShuffled = AudioHandler.Constants.notesAnimationDuration.shuffled()
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Song>!

    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        audioHandler = AudioHandler()
        setupFetchedResultsController()
        showLastRecordedSong()
        setupRecordPlayButtons()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        displayNotesAnimated()
    }

    // MARK: - Setup methods
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "songs")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    func showLastRecordedSong() {
        if let songs = fetchedResultsController.fetchedObjects, songs.count > 0 {
            currentSongName = songs[0].filename!
            buttonSong.title = currentSongName
            audioHandler.setupAudio(currentSongName) { error in
                if error != nil {
                    currentSongName = ""
                }
            }
        }
    }
    
    fileprivate func setupRecordPlayButtons() {
        buttonRecordStopSong.tag = AudioHandler.RecordingState.isNotRecording.rawValue
        buttonPlayStopSong.tag = AudioHandler.PlayingState.isNotPlaying.rawValue
        buttonRecordStopSong.image = UIImage(systemName: "mic.fill")
        buttonRecordStopSong.isEnabled = true
        buttonPlayStopSong.image = UIImage(systemName: "play.circle.fill")
        buttonPlayStopSong.isEnabled = !currentSongName.isEmpty
    }
    
    fileprivate func displayNotesAnimated() {
        // Add an item to the first position since we only can reference buttons dinamically by tag from position 1
        notesColorArrayShuffled.insert(UIColor.black, at: 0)
        notesFileNameArrayShuffled.insert("", at: 0)
        notesAnimationDurationShuffled.insert(0.0, at: 0)
        for index in 1...7 {
            let button = view.viewWithTag(index) as! UIButton
            UIView.animate(withDuration: notesAnimationDurationShuffled[index], delay: 0.0, options: [], animations: {
                button.tintColor = self.notesColorArrayShuffled[index]
            }, completion: nil)
        }
    }
    
    // MARK: - Audio methods
    
    @IBAction func playNoteButton(_ sender: UIButton) {
        audioHandler.playAudioAsset(notesFileNameArrayShuffled[sender.tag])
    }
        
    @IBAction func recordStopAudioButton(_ sender: Any) {
        if self.buttonRecordStopSong.tag == AudioHandler.RecordingState.isNotRecording.rawValue {
            let userDefaults = UserDefaults.standard
            if userDefaults.bool(forKey: "firstTimeSettingMicrophonePermission") == false {
                self.recordAfterMicrophonePermissionVerified()
            } else {
                AudioHandler.hasMicrophonePermission { alert in
                    if let alert = alert {
                        self.present(alert, animated: true, completion: nil)
                    } else {
                        self.recordAfterMicrophonePermissionVerified()
                    }
                }
            }
        } else {
            self.audioHandler.audioRecorder.stop()
            try? AVAudioSession.sharedInstance().setActive(false)
            self.changeRecordStopButtonStatus(showRecordButton: true)
        }
    }
    
    fileprivate func recordAfterMicrophonePermissionVerified() {
        self.getFileName { fileName in
            if let fileName = fileName {
                UserDefaults.standard.set(true, forKey: "firstTimeSettingMicrophonePermission")
                self.changeRecordStopButtonStatus(showRecordButton: false)
                self.currentSongName = fileName
                self.recordAudio(recordingName: fileName)
            }
        }
    }
            
    @IBAction func playStopAudioButtonAction(_ sender: Any) {
        if buttonPlayStopSong.tag == AudioHandler.PlayingState.isNotPlaying.rawValue {
            self.changePlayStopButtonStatus(showPlayButton: false)
            audioHandler.playSong { delayInSeconds, error in
                if error != nil {
                    self.showAlert(title: AudioHandler.Constants.ErrorPlaySong, message: String(describing: error))
                    self.changePlayStopButtonStatus(showPlayButton: true)
                } else {
                    self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(self.stopAudio), userInfo: nil, repeats: false)
                    RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
                }
            }
        } else {
            stopAudio()
        }
    }
    
    @objc func stopAudio() {
        if let audioPlayerNode = audioHandler.audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        changePlayStopButtonStatus(showPlayButton: true)
                        
        if let audioEngine = audioHandler.audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    // MARK: - Change button and label status
    
    func changeRecordStopButtonStatus(showRecordButton: Bool) {
        if showRecordButton {
            buttonRecordStopSong.tag = AudioHandler.RecordingState.isNotRecording.rawValue
            buttonRecordStopSong.image = UIImage(systemName: "mic.fill")
            buttonPlayStopSong.isEnabled = !currentSongName.isEmpty
        } else {
            buttonRecordStopSong.tag = AudioHandler.RecordingState.isRecording.rawValue
            buttonRecordStopSong.image = UIImage(systemName: "stop.circle.fill")
            buttonPlayStopSong.isEnabled = false
        }
        buttonRecordStopSong.isEnabled = true
    }
    
    func changePlayStopButtonStatus(showPlayButton: Bool) {
        if showPlayButton {
            buttonPlayStopSong.tag = AudioHandler.PlayingState.isNotPlaying.rawValue
            buttonPlayStopSong.image = UIImage(systemName: "play.circle.fill")
            buttonRecordStopSong.isEnabled = true
        } else {
            buttonPlayStopSong.tag = AudioHandler.PlayingState.isPlaying.rawValue
            buttonPlayStopSong.image = UIImage(systemName: "stop.circle.fill")
            buttonRecordStopSong.isEnabled = false
        }
        buttonPlayStopSong.isEnabled = true
    }
        
    // MARK: - Audio delegate
    
    func recordAudio(recordingName: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try audioSession.setActive(true)
        } catch {
            showAlert(title: AudioHandler.Constants.UseSpeaker, message: AudioHandler.Constants.ReminderUseSpeaker)
        }
        try! audioHandler.audioRecorder = AVAudioRecorder(url: AudioHandler.getFilePath(recordingName: recordingName), settings: [:])
        audioHandler.audioRecorder.delegate = self
        audioHandler.audioRecorder.isMeteringEnabled = true
        audioHandler.audioRecorder.prepareToRecord()
        audioHandler.audioRecorder.record()
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag { // Record with successfull
            saveCurrentSong()
            buttonSong.title = currentSongName
            audioHandler.setupAudio(currentSongName) { error in
                if error != nil {
                    self.showAlert(title: AudioHandler.Constants.ErrorRecordSong, message: String(describing: error))
                }
            }
            changePlayStopButtonStatus(showPlayButton: true)
        } else {
            showAlert(title: AudioHandler.Constants.RecordingError, message: String(describing: AudioHandler.Constants.RecordingNotSuccessFull))
        }
    }
    
    // MARK: - Get file name and path methods with conditionals and recursively calling
    
    func getFileName(completion: @escaping(String?) -> Void) {
        let alert = UIAlertController(title: AudioHandler.Constants.SongName, message: AudioHandler.Constants.SongNameQuestion, preferredStyle: .alert)
        alert.addTextField { textField in
            textField.delegate = self
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert!.textFields![0]
            textField.delegate = self
            let fileName = textField.text!
            if fileName.isEmpty {
                let alert = UIAlertController(title: AudioHandler.Constants.SongNameEmpty, message: AudioHandler.Constants.SongNameMustNotBeEmpty, preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                    UIAlertAction in
                    self.getFileName { fileNameRecursive in
                        completion(fileNameRecursive)
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                    UIAlertAction in
                    completion(nil)
                }
                alert.addAction(okAction)
                alert.addAction(cancelAction)
                self.present(alert, animated: true, completion: nil)
            } else {
                let savedSongs = self.fetchedResultsController.fetchedObjects! as [Song]
                if savedSongs.filter({$0.filename == fileName}).count > 0 {
                    let alert = UIAlertController(title: AudioHandler.Constants.SongNameExists, message: AudioHandler.Constants.ChooseAnotherName, preferredStyle: .alert)
                    let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                        UIAlertAction in
                        self.getFileName { fileNameRecursive in
                            completion(fileNameRecursive)
                        }
                    }
                    let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                        UIAlertAction in
                        completion(nil)
                    }
                    alert.addAction(okAction)
                    alert.addAction(cancelAction)
                    self.present(alert, animated: true, completion: nil)
                } else {
                    completion(fileName)
                }
            }
        }))
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Text field delegate
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let isBackSpace = strcmp(string.cString(using: String.Encoding.utf8)!, "\\b") == -92
        return string.isAlphanumeric || isBackSpace
    }
    
    // MARK: - Core Data
    
    fileprivate func saveCurrentSong() {
        let savedSong = Song(context: dataController.viewContext)
        savedSong.filename = currentSongName
        do {
            try dataController.viewContext.save()
        } catch {
            showAlert(title: AudioHandler.Constants.Error, message: error.localizedDescription)
        }
        try? fetchedResultsController.performFetch()
    }
    
    // MARK: - Go to Magical Songs
    
    @IBAction func goToMagicalSongsButtonAction(_ sender: Any) {
        if buttonRecordStopSong.tag == AudioHandler.RecordingState.isRecording.rawValue {
            showAlert(title: AudioHandler.Constants.SongUnderRecording, message: AudioHandler.Constants.StopTheSongRecording)
        } else {
            if buttonPlayStopSong.tag == AudioHandler.PlayingState.isPlaying.rawValue {
                stopAudio()
            }
            self.performSegue(withIdentifier: "goToMagicalSongs", sender: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMagicalSongs" {
            let magicalSoungsViewController = segue.destination as! MagicalSongsViewController
            magicalSoungsViewController.dataController = dataController
            magicalSoungsViewController.isComingFromRegisterController = false
        }
    }
    
}
