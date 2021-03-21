//
//  MagicalSoundsStoryBoard.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 14/03/21.
//

import UIKit
import CoreData
import AVFoundation

// MARK: - Music Custom Cell

class MusicCellTableViewCell: UITableViewCell {
    @IBOutlet weak var labelSongName: UILabel!
    @IBOutlet weak var buttonPlay: UIButton!
    @IBOutlet weak var buttonUpload: UIButton!
    @IBOutlet weak var buttonShare: UIButton!
}

class MagicalSongsViewController: UITableViewController, AVAudioRecorderDelegate, NSFetchedResultsControllerDelegate, UITextFieldDelegate {
    
    var audioHandler: AudioHandler!
    var currentSongName: String = ""
    var stopTimer: Timer!
    var dataController: DataController!
    var fetchResultsController: NSFetchedResultsController<Song>!
    var playingSound = false
    
    @IBOutlet weak var registerLoginButton: UIBarButtonItem!
       
    override func viewDidLoad() {
        audioHandler = AudioHandler()
        setupFetchedResultsController()
        tableView.allowsSelection = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setupRegisterLoginButton()
    }
    
    fileprivate func setupRegisterLoginButton() {
        let userDefaults = UserDefaults.standard
        if (userDefaults.string(forKey: "clientId") ?? "").isEmpty {
            registerLoginButton.title = "Register"
            registerLoginButton.tintColor = UIColor.systemRed
        } else {
            if !(userDefaults.string(forKey: "accessToken") ?? "").isEmpty {
                registerLoginButton.title = "Logged In"
                registerLoginButton.tintColor = UIColor.systemGreen
            } else {
                registerLoginButton.title = "Login"
                registerLoginButton.tintColor = UIColor.systemBlue
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
    
    // TODO ALREADY HAVE getFileName, make generic
    // IT IS FAILING TO GET THE NAME when EMPTY
    func getAuthorizationCode(completion: @escaping(String?) -> Void) {
        let alert = UIAlertController(title: "Code", message: "Copy the authorization code from FreeSound", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.delegate = self
            textField.text = ""
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak alert] (_) in
            let textField = alert!.textFields![0] // Force unwrapping because we know it exists.
            var finished = false
            var times = 2
            repeat {
                if textField.text!.isEmpty {
                    self.showAlert(title: "Empty code", message: "The code")
                    times -= 1
                    if times == 0 {
                        completion(nil)
                    }
                } else {
                    finished = true
                    completion(textField.text!)
                }
            } while !finished || times == 0
        }))
        self.present(alert, animated: true, completion: nil)
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let isBackSpace = strcmp(string.cString(using: String.Encoding.utf8)!, "\\b") == -92
        return string.isAlphanumeric || isBackSpace
    }
    
    // MARK: - TableView methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchResultsController.fetchedObjects?.count ?? 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicCell") as! MusicCellTableViewCell
        let resultObject = fetchResultsController.object(at: indexPath)
        cell.labelSongName?.text = resultObject.filename
        if resultObject.soundId == nil {
            cell.buttonUpload.setBackgroundImage(UIImage(named: "upload"), for: .normal)
            cell.buttonUpload.isEnabled = true
            cell.buttonShare.isEnabled = true
        } else {
            cell.buttonUpload.setBackgroundImage(UIImage(named: "upload-disabled"), for: .disabled)
            cell.buttonUpload.isEnabled = false
            cell.buttonShare.isEnabled = false
        }
        cell.buttonPlay?.tag = indexPath.row
        return cell
    }
    
    @IBAction func playSongButtonAction(_ sender: Any) {
        if playingSound {
            showAlert(title: "Playing sound", message: "Wait until finish or stop current sound")
        } else {
            currentSongName = fetchResultsController.fetchedObjects![(sender as! UIButton).tag].filename!
                    
            // TODO CREATE SEPARATE HANDLERS
            // TODO FIX LAYOUT MAGICALSOUNDS FOR HORIZONTAL VISUALIZATION, IT LEFT PLACES AFTER CHANGE SIZE OF BUTTONS
            audioHandler.setupAudio(currentSongName) { error in
                if error != nil {
                    self.showAlert(title: "Alerts.AudioFileError", message: String(describing: error))
                } else {
                    playingSound = true
                    audioHandler.playSound { delayInSeconds, error in
                        if error != nil {
                            self.showAlert(title: "Alerts.AudioFileError", message: String(describing: error))
                            self.playingSound = false
                        } else {
                            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(self.stopAudio), userInfo: nil, repeats: false)
                            RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
                        }
                    }
                }
            }
        }
    }
    
    @objc func stopAudio() {
        if let audioPlayerNode = audioHandler.audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        //changePlayStopButtonStatus(showPlayButton: true)
                        
        if let audioEngine = audioHandler.audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
        playingSound = false
    }
        
    func getFilePath(recordingName: String) -> URL {
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] as String
        let pathArray = [dirPath, recordingName]
        return URL(string: pathArray.joined(separator: "/") + ".wav")!
    }
    
    @IBAction func uploadSongButtonAction(_ sender: Any) {
        let currentSong = fetchResultsController.fetchedObjects![(sender as! UIButton).tag]
        
        if !(currentSong.soundId ?? "").isEmpty {
            showAlert(title: "Already uploaded", message: "This sound was already upload to FreeSounds.")
        } else {
            currentSongName = currentSong.filename!
            
            NetworkClient.upload(url: getFilePath(recordingName: currentSongName), name: currentSongName, accessToken: UserDefaults.standard.string(forKey: "accessToken")!) { success, error in
                print("Finalized")
            }
        }
    }
    
    @IBAction func registerLoginButtonAction(_ sender: Any) {
        if registerLoginButton.title == "Register" {
            performSegue(withIdentifier: "goToRegister", sender: nil)
        } else if registerLoginButton.title == "Login" {
            self.registerLoginButton.tintColor = UIColor.systemBlue
            self.registerLoginButton.isEnabled = false
            let userDefaults = UserDefaults.standard
            let clientId = userDefaults.string(forKey: "clientId")!
            NetworkClient.authorize(clientId) {
                let alert = UIAlertController(title: "Enter Authorization Code", message: "Please copy temporary authorization code here.", preferredStyle: .alert)
                alert.addTextField(configurationHandler: nil)
                let defaultAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
                    let authorizationCode = alert.textFields?.first?.text ?? ""
                    if authorizationCode.isEmpty {
                        self.showAlert(title: "Code empty", message: "Login and copy the code.")
                    } else {
                        let clientSecret = userDefaults.string(forKey: "clientSecret")!
                        NetworkClient.getAccessToken(authorizationCode, clientId, clientSecret) { accessToken, error in
                            if error == nil {
                                self.registerLoginButton.title = "Logged In"
                                self.registerLoginButton.tintColor = UIColor.systemGreen
                                self.registerLoginButton.isEnabled = true
                                userDefaults.set(accessToken, forKey: "accessToken")
                            } else {
                                self.showAlert(title: "Error to Login", message: "Try Login again")
                                self.registerLoginButton.tintColor = UIColor.systemBlue
                                self.registerLoginButton.isEnabled = true
                            }
                        }
                    }
                })
                alert.addAction(defaultAction)
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
}
