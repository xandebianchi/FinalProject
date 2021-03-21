//
//  ViewController.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 02/03/21.
//

import UIKit
import AVFoundation
import CoreData

class MainViewController: UIViewController, AVAudioRecorderDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate {
    
    struct Constants {
        static let RecordingNotSuccessFull = "Recording was not successful"
    }
    
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
    
    var audioHandler: AudioHandler!
    var currentSongName: String = ""
    var stopTimer: Timer!
    var colorArray = [UIColor.red, UIColor.green, UIColor.blue, UIColor.orange, UIColor.systemYellow, UIColor.cyan, UIColor.magenta].shuffled()
    var notesFileNameArray = ["do-c", "re-d", "mi-e", "fa-f", "sol-g", "la-a", "si-b"].shuffled()
    var dataController: DataController!
    var fetchResultsController: NSFetchedResultsController<Song>!

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
    
    fileprivate func displayNotesAnimated() {
        UIView.animate(withDuration: 0.9, delay: 0.0, options: [], animations: {
            self.buttonNote1.tintColor = self.colorArray[0]
        }, completion: nil)
        UIView.animate(withDuration: 1.2, delay: 0.0, options: [], animations: {
            self.buttonNote2.tintColor = self.colorArray[1]
        }, completion: nil)
        UIView.animate(withDuration: 1.1, delay: 0.0, options: [], animations: {
            self.buttonNote3.tintColor = self.colorArray[2]
        }, completion: nil)
        UIView.animate(withDuration: 1.0, delay: 0.0, options: [], animations: {
            self.buttonNote4.tintColor = self.colorArray[3]
        }, completion: nil)
        UIView.animate(withDuration: 1.4, delay: 0.0, options: [], animations: {
            self.buttonNote5.tintColor = self.colorArray[4]
        }, completion: nil)
        UIView.animate(withDuration: 1.5, delay: 0.0, options: [], animations: {
            self.buttonNote6.tintColor = self.colorArray[5]
        }, completion: nil)
        UIView.animate(withDuration: 1.3, delay: 0.0, options: [], animations: {
            self.buttonNote7.tintColor = self.colorArray[6]
        }, completion: nil)
    }
    
    func showLastRecordedSong() {
        if let songs = fetchResultsController.fetchedObjects, songs.count > 0 {
            currentSongName = songs[0].filename!
            buttonSong.title = currentSongName
            audioHandler.setupAudio(currentSongName) { error in
                if (error != nil) {
                    currentSongName = ""
                }
            }
        }
    }
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "songs")
        fetchResultsController.delegate = self
        do {
            try fetchResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - IBActions
    
    @IBAction func playNoteButton(_ sender: UIButton) {
        audioHandler.playAudioAsset(notesFileNameArray[sender.tag])
    }

    @IBAction func recordStopAudioButton(_ sender: Any) {
        if buttonRecordStopSong.tag == AudioHandler.RecordingState.mustNotRecord.rawValue {
            changeRecordStopButtonStatus(showRecordButton: false)
            getFileName { fileName in
                self.currentSongName = fileName!
                self.recordAudio(recordingName: fileName!)
            }
        } else {
            audioHandler.audioRecorder.stop()
            try? AVAudioSession.sharedInstance().setActive(false)
//            } catch {
  //              showAlert(title: "Error", message: error.localizedDescription)
    //        }
            changeRecordStopButtonStatus(showRecordButton: true)
        }
    }
        
    @IBAction func playStopAudioButton(_ sender: Any) {
        if buttonPlayStopSong.tag == AudioHandler.PlayingState.mustNotPlay.rawValue {
            self.changePlayStopButtonStatus(showPlayButton: false)
            audioHandler.playSound { delayInSeconds, error in
                if error != nil {
                    self.showAlert(title: "Alerts.AudioFileError", message: String(describing: error))
                    self.changePlayStopButtonStatus(showPlayButton: true)
                } else {
                    self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(self.stopAudio), userInfo: nil, repeats: false)
                    RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
                }
            }
        } else {
            stopAudio()
            changePlayStopButtonStatus(showPlayButton: true)
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
    
    // MARK: Change button and label status
    
    func changeRecordStopButtonStatus(showRecordButton: Bool) {
        if showRecordButton {
            buttonRecordStopSong.tag = AudioHandler.RecordingState.mustNotRecord.rawValue
            buttonRecordStopSong.image = UIImage(systemName: "mic.fill")
            buttonPlayStopSong.isEnabled = !currentSongName.isEmpty
        } else {
            buttonRecordStopSong.tag = AudioHandler.RecordingState.mustRecord.rawValue
            buttonRecordStopSong.image = UIImage(systemName: "stop.circle.fill")
            buttonPlayStopSong.isEnabled = false
        }
        buttonRecordStopSong.isEnabled = true
    }
    
    func changePlayStopButtonStatus(showPlayButton: Bool) {
        if showPlayButton {
            buttonPlayStopSong.tag = AudioHandler.PlayingState.mustNotPlay.rawValue
            buttonPlayStopSong.image = UIImage(systemName: "play.circle.fill")
            buttonRecordStopSong.isEnabled = true
        } else {
            buttonPlayStopSong.tag = AudioHandler.PlayingState.mustPlay.rawValue
            buttonPlayStopSong.image = UIImage(systemName: "stop.circle.fill")
            buttonRecordStopSong.isEnabled = false
        }
        buttonPlayStopSong.isEnabled = true
    }
    
    // MARK: Audio delegate
    
    func recordAudio(recordingName: String) {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)
            try audioSession.overrideOutputAudioPort(AVAudioSession.PortOverride.speaker)
            try audioSession.setActive(true)
        } catch {
            print("Couldn't override output audio port")
        }
        try! audioHandler.audioRecorder = AVAudioRecorder(url: audioHandler.getFilePath(recordingName: recordingName), settings: [:])
        audioHandler.audioRecorder.delegate = self
        audioHandler.audioRecorder.isMeteringEnabled = true
        audioHandler.audioRecorder.prepareToRecord()
        audioHandler.audioRecorder.record()
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            saveCurrentSong()
            buttonSong.title = currentSongName
            audioHandler.setupAudio(currentSongName) { error in
                if error != nil {
                    self.showAlert(title: "Alerts.AudioFileError", message: String(describing: error))
                }
            }
            changePlayStopButtonStatus(showPlayButton: true)
            //performSegue(withIdentifier: Constants.StopRecordingSegueId, sender: audioRecorder.url)
        } else {
            showAlert(title: AudioHandler.Alerts.AudioFileError, message: String(describing: Constants.RecordingNotSuccessFull))
            //print(Constants.RecordingNotSuccessFull)
        }
    }
    
    // MARK: Get file name and path methods
    
    // IT IS FAILING TO GET THE NAME when EMPTY
    func getFileName(completion: @escaping(String?) -> Void) {
        let alert = UIAlertController(title: "Name of file", message: "What is the name of the song?", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.delegate = self
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let savedSongs = self.fetchResultsController.fetchedObjects! as [Song]
            let textField = alert!.textFields![0] // Force unwrapping because we know it exists.
            var finished = false
            repeat {
                if textField.text!.isEmpty {
                    self.showAlert(title: "Empty name", message: "Choose a name")
                } else if savedSongs.filter({$0.filename == textField.text}).count > 0 {
                    self.showAlert(title: "This song already exists", message: "Choose another name")
                } else {
                    finished = true
                    completion(textField.text!)
                }
            } while !finished
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let isBackSpace = strcmp(string.cString(using: String.Encoding.utf8)!, "\\b") == -92
        return string.isAlphanumeric || isBackSpace
    }
    
    // MARK: Core Data
    
    fileprivate func saveCurrentSong() {
        let savedSong = Song(context: dataController.viewContext)
        savedSong.filename = currentSongName
        do {
            try dataController.viewContext.save()
        } catch {
            showAlert(title: "Error", message: error.localizedDescription)
        }
        try? fetchResultsController.performFetch()
    }
    
    @IBAction func goToMagicalSoundsButtonAction(_ sender: Any) {
        self.performSegue(withIdentifier: "goToMagicalSongs", sender: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToMagicalSongs" {
            let magicalSoungsViewController = segue.destination as! MagicalSongsViewController
            magicalSoungsViewController.dataController = dataController
        }
    }
    
    func setupRecordPlayButtons() {
        buttonRecordStopSong.tag = AudioHandler.RecordingState.mustNotRecord.rawValue
        buttonPlayStopSong.tag = AudioHandler.PlayingState.mustNotPlay.rawValue
        buttonRecordStopSong.image = UIImage(systemName: "mic.fill")
        buttonRecordStopSong.isEnabled = true
        buttonPlayStopSong.image = UIImage(systemName: "play.circle.fill")
        buttonPlayStopSong.isEnabled = !currentSongName.isEmpty
    }
    
}
