//
//  MagicalSongsStoryBoard.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 14/03/21.
//

import UIKit
import CoreData
import AVFoundation

class MagicalSongsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, AVAudioRecorderDelegate, NSFetchedResultsControllerDelegate {
        
    // MARK: - IBOutlets
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicatorView: UIView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Properties
    
    enum RegisterLoginButtonState: Int { case register = 1, login = 2, loggedIn = 3 }
    
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<Song>!
    var audioHandler: AudioHandler!
    var stopTimer: Timer!
    var playingSong = false
    var uploadingSong = false
    var sharingSong = false
    var buttonActionTimer: Timer?
    var cellPlayingInAction: MusicCellTableViewCell? = nil
    var cellUploadingInAction: MusicCellTableViewCell!
    var cellShareingInAction: MusicCellTableViewCell!
    var registerLoginButton: UIBarButtonItem!
    var isComingFromRegisterController = false
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        setupFetchedResultsController()
        setupInitial()
    }
        
    override func viewWillAppear(_ animated: Bool) {
        setupRegisterLoginButton()
    }
    
    // MARK: - Initial setup
    
    fileprivate func setupInitial() {
        audioHandler = AudioHandler()
        tableView.allowsSelection = false
        tableView.delegate = self
        tableView.dataSource = self
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "< Back", style: UIBarButtonItem.Style.plain, target: self, action: #selector(backButtonOverrideAction))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register", style: UIBarButtonItem.Style.plain, target: self, action: #selector(registerLoginButtonAction))
        navigationItem.rightBarButtonItem!.tintColor = UIColor.systemRed
        registerLoginButton = navigationItem.rightBarButtonItem
    }
    
    // MARK: - Core data
    
    fileprivate func setupFetchedResultsController() {
        let fetchRequest: NSFetchRequest<Song> = Song.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "songs")
        fetchedResultsController.delegate = self
        do {
            try fetchedResultsController.performFetch()
        } catch {
            let alert = UIAlertController(title: AudioHandler.Constants.Error, message: AudioHandler.Constants.CouldNotGetListSongs, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                UIAlertAction in
                self.navigationController?.popToRootViewController(animated: true)
            }
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    // MARK: - TableView methods
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.fetchedObjects?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MusicCell") as! MusicCellTableViewCell
        let resultObject = fetchedResultsController.object(at: indexPath)
        cell.labelSongName?.text = resultObject.filename
        if resultObject.soundId == 0 {
            cell.buttonUpload.setBackgroundImage(UIImage(named: "upload"), for: .normal)
            cell.buttonUpload.isEnabled = true
        } else {
            cell.buttonUpload.setBackgroundImage(UIImage(named: "upload-disabled"), for: .disabled)
            cell.buttonUpload.isEnabled = false
        }
        cell.buttonPlay?.tag = indexPath.row
        cell.buttonUpload?.tag = indexPath.row
        cell.buttonShare?.tag = indexPath.row
        return cell
    }
    
    // MARK: - Register and Login functions
        
    fileprivate func setupRegisterLoginButton() {
        let userDefaults = UserDefaults.standard
        if (userDefaults.string(forKey: "clientId") ?? "").isEmpty {
            setRegisterButtonState(state: .register)
        } else {
            registerLoginButton.isEnabled = false
            if (userDefaults.string(forKey: "accessToken") ?? "").isEmpty { // When return from Authorization Code screen, starts Login process
                setRegisterButtonState(state: .login)
                if isComingFromRegisterController {
                    registerLoginButtonAction()
                }
            } else {
                if let nextRefreshDateUserDefaults = userDefaults.string(forKey: "nextRefreshDate"), let nextRefreshDate = nextRefreshDateUserDefaults.iso8601withFractionalSeconds {
                    if Date() > nextRefreshDate { // If the token expires, refresh to a new one
                        animateActivityIndicator(true)
                        refreshToken()
                    } else {
                        setRegisterButtonState(state: .loggedIn)
                    }
                } else {
                    setRegisterButtonState(state: .login)
                }
            }
        }
    }
    
    @objc func registerLoginButtonAction() {
        if registerLoginButton.title == "Register" {
            isComingFromRegisterController = true
            performSegue(withIdentifier: "goToRegister", sender: nil)
        } else if registerLoginButton.title == "Login" {
            let alert = UIAlertController(title: AudioHandler.Constants.GetAuthorizationCode, message: AudioHandler.Constants.AuthorizeAndCopyCode, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) {
                UIAlertAction in
                self.registerAction()
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                self.registerLoginButton.isEnabled = true
            }
            alert.addAction(okAction)
            alert.addAction(cancelAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
        
    fileprivate func registerAction() {
        registerLoginButton.isEnabled = false
        let userDefaults = UserDefaults.standard
        let clientId = userDefaults.string(forKey: "clientId")!
        NetworkClient.authorize(clientId) {
            let alert = UIAlertController(title: AudioHandler.Constants.EnterAuthorizationCode, message: AudioHandler.Constants.CopyAuthorizationCodeHere, preferredStyle: .alert)
            alert.addTextField(configurationHandler: nil)
            let defaultAction = UIAlertAction(title: "OK", style: .default, handler: { _ in
                self.getAuthorizationCode(clientId: clientId, authorizationCode: alert.textFields?.first?.text ?? "")
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel) {
                UIAlertAction in
                self.registerLoginButton.isEnabled = true
            }
            let errorToGetCodeAction = UIAlertAction(title: AudioHandler.Constants.ErrorGetCodeQuestion, style: UIAlertAction.Style.destructive) {
                UIAlertAction in
                userDefaults.set("", forKey: "clientId")
                userDefaults.set("", forKey: "clientSecret")
                self.setRegisterButtonState(state: .register)
                self.registerLoginButton.isEnabled = true
            }
            alert.addAction(defaultAction)
            alert.addAction(cancelAction)
            alert.addAction(errorToGetCodeAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func getAuthorizationCode(clientId: String, authorizationCode: String) {
        let userDefaults = UserDefaults.standard
        if authorizationCode.isEmpty {
            self.showAlert(title: AudioHandler.Constants.CodeEmpty, message: AudioHandler.Constants.LoginCopyAuthorizationCode)
            self.registerLoginButton.isEnabled = true
        } else {
            self.animateActivityIndicator(true)
            let clientSecret = userDefaults.string(forKey: "clientSecret")!
            NetworkClient.getAccessToken(authorizationCode, clientId, clientSecret) { response, error in
                self.animateActivityIndicator(false)
                if error == nil {
                    self.setRegisterButtonState(state: .loggedIn)
                    userDefaults.set(response!.accessToken, forKey: "accessToken")
                    userDefaults.set(response!.refreshToken, forKey: "refreshToken")
                    let nextRefreshDate = Date().addingTimeInterval(Double(response!.expiresIn))
                    userDefaults.set(nextRefreshDate.iso8601withFractionalSeconds, forKey: "nextRefreshDate")
                } else {
                    self.setRegisterButtonState(state: .login)
                    self.showAlert(title: AudioHandler.Constants.ErrorLogin, message: AudioHandler.Constants.TryLoginAgainAuthorizationCodeWrong)
                }
            }
        }
    }
    
    fileprivate func refreshToken() {
        let userDefaults = UserDefaults.standard
        let clientId = userDefaults.string(forKey: "clientId")!
        let clientSecret = userDefaults.string(forKey: "clientSecret")!
        let refreshToken = userDefaults.string(forKey: "refreshToken")!
        NetworkClient.getRefreshToken(refreshToken, clientId, clientSecret) { response, error in
            self.animateActivityIndicator(false)
            if error == nil {
                self.setRegisterButtonState(state: .loggedIn)
                userDefaults.set(response!.accessToken, forKey: "accessToken")
                userDefaults.set(response!.refreshToken, forKey: "refreshToken")
                let nextRefreshDate = Date().addingTimeInterval(Double(response!.expiresIn))
                userDefaults.set(nextRefreshDate.iso8601withFractionalSeconds, forKey: "nextRefreshDate")
            } else {
                self.setRegisterButtonState(state: .login)
                self.showAlert(title: AudioHandler.Constants.LoginExpiration, message: AudioHandler.Constants.NeedToLoginAgain)
            }
        }
    }
    
    fileprivate func setRegisterButtonState(state: RegisterLoginButtonState) {
        switch state {
        case .register:
            registerLoginButton.title = AudioHandler.Constants.Register
            registerLoginButton.tintColor = UIColor.systemRed
            break
        case .login:
            registerLoginButton.title = AudioHandler.Constants.Login
            registerLoginButton.tintColor = UIColor.systemBlue
            break
        case .loggedIn:
            registerLoginButton.title = AudioHandler.Constants.LoggedIn
            registerLoginButton.tintColor = UIColor.systemGreen
            break
        }
        registerLoginButton.isEnabled = true
    }
            
    // MARK: - Play functions
       
    @IBAction func playStopAudioButtonAction(_ sender: Any) {
        if playingSong {
            if cellPlayingInAction?.buttonPlay != (sender as! UIButton) {
                showAlert(title: AudioHandler.Constants.PlayingSong, message: AudioHandler.Constants.WaitUntilSongFinishesOrStopCurrentSong)
            } else {
                stopAudio()
            }
        } else {
            let cellInActionTag = (sender as! UIButton).tag
            let currentSongName = fetchedResultsController.fetchedObjects![cellInActionTag].filename!
            audioHandler.setupAudio(currentSongName) { error in
                setupAudio(cellInActionTag, error)
            }
        }
    }
        
    fileprivate func setupAudio(_ cellInActionTag: Int, _ error: Error?) {
        if error != nil {
            self.showAlert(title: AudioHandler.Constants.Error, message: String(describing: error))
        } else {
            cellPlayingInAction = (tableView.cellForRow(at: IndexPath(item: cellInActionTag, section: 0)) as! MusicCellTableViewCell)
            changePlayStopButtonStatus(showPlayButton: false)
            playingSong = true
            audioHandler.playSong { delayInSeconds, error in
                self.playSong(error, delayInSeconds)
            }
        }
    }
    
    fileprivate func playSong(_ error: Error?, _ delayInSeconds: Double) {
        if error != nil {
            self.showAlert(title: AudioHandler.Constants.Error, message: String(describing: error))
            self.playingSong = false
            self.cellPlayingInAction = nil
        } else {
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(self.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
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
        
        playingSong = false
        self.cellPlayingInAction = nil
    }
    
    func changePlayStopButtonStatus(showPlayButton: Bool) {
        if showPlayButton {
            self.cellPlayingInAction!.buttonPlay.setBackgroundImage(UIImage(systemName: "play.circle.fill"), for: .normal)
            self.cellPlayingInAction!.buttonPlay.tintColor = UIColor.systemGreen
        } else {
            self.cellPlayingInAction!.buttonPlay.setBackgroundImage(UIImage(systemName: "stop.circle.fill"), for: .normal)
            self.cellPlayingInAction!.buttonPlay.tintColor = UIColor.systemRed
        }
    }
        
    // MARK: - Upload functions
    
    @IBAction func uploadSoundButtonAction(_ sender: Any) {
        if isLoggedIn() && !uploadingSong && !sharingSong {
            animateActivityIndicator(true)
            let cellInActionTag = (sender as! UIButton).tag
            let currentSong = fetchedResultsController.fetchedObjects![cellInActionTag]
            if currentSong.soundId > 0 {
                animateActivityIndicator(false)
                showAlert(title: AudioHandler.Constants.AlreadyUploaded, message: AudioHandler.Constants.AlreadyUploadedToFreeSounds)
            } else {
                uploadSong(cellInActionTag, currentSong.filename!, currentSong)
            }
        }
    }
    
    fileprivate func uploadSong(_ cellInActionTag: Int, _ currentSongName: String, _ currentSong: Song) {
        uploadingSong = true
        cellUploadingInAction = (tableView.cellForRow(at: IndexPath(item: cellInActionTag, section: 0)) as! MusicCellTableViewCell)
        buttonActionTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(self.uploadSongBlinkAnimation), userInfo: nil, repeats: true)
        let accessToken = UserDefaults.standard.string(forKey: "accessToken")!
        NetworkClient.upload(url: AudioHandler.getFilePath(recordingName: currentSongName), name: currentSongName, accessToken: accessToken) { soundId, error in
            self.uploadingSong = false
            self.animateActivityIndicator(false)
            if soundId != nil {
                self.saveSoundId(soundId: soundId!, song: currentSong)
                self.tableView.reloadData()
                self.showAlert(title: AudioHandler.Constants.SongUploaded, message: "\(AudioHandler.Constants.Song) \(currentSongName) \(AudioHandler.Constants.SongWillBeModerated)")
            } else {
                self.showAlert(title: AudioHandler.Constants.ErrorUpload, message: AudioHandler.Constants.ErrorUploadTryLater)
            }
        }
    }
    
    fileprivate func saveSoundId(soundId: Int32, song: Song) {
        song.soundId = soundId
        do {
            try dataController.viewContext.save()
        } catch {
            showAlert(title: AudioHandler.Constants.Error, message: error.localizedDescription)
        }
        try? fetchedResultsController.performFetch()
    }
    
    @objc func uploadSongBlinkAnimation(){
        if uploadingSong {
            UIView.animate(withDuration: 0.7) {
                self.cellUploadingInAction.buttonUpload.alpha = self.cellUploadingInAction.buttonUpload.alpha == 1.0 ? 0.0 : 1.0
            }
        } else {
            buttonActionTimer?.invalidate()
            buttonActionTimer = nil
            self.cellUploadingInAction.buttonUpload.alpha = 1.0
        }
    }
    
    // MARK: - Share functions
               
    @IBAction func shareButtonAction(_ sender: Any) {
        if isLoggedIn() && !sharingSong && !uploadingSong {
            animateActivityIndicator(true)
            let cellInActionTag = (sender as! UIButton).tag
            let currentSong = fetchedResultsController.fetchedObjects![cellInActionTag]
            if currentSong.soundId == 0 {
                animateActivityIndicator(false)
                showAlert(title: AudioHandler.Constants.NotShared, message: AudioHandler.Constants.FirstUploadToShareIt)
            } else {
                shareSong(cellInActionTag, currentSong)
            }
        }
    }
    
    fileprivate func shareSong(_ cellInActionTag: Int, _ currentSong: Song) {
        sharingSong = true
        cellShareingInAction = (tableView.cellForRow(at: IndexPath(item: cellInActionTag, section: 0)) as! MusicCellTableViewCell)
        buttonActionTimer = Timer.scheduledTimer(timeInterval: 0.7, target: self, selector: #selector(self.shareSongBlinkAnimation), userInfo: nil, repeats: true)
        let accessToken = UserDefaults.standard.string(forKey: "accessToken")!
        NetworkClient.getPendingUploads(accessToken: accessToken) { pendingUploadResponse, error in
            self.handlePendingUploadsResponse(soundId: currentSong.soundId, response: pendingUploadResponse, error: error)
        }
    }
    
    func handlePendingUploadsResponse(soundId: Int32, response: PendingUploadResponse?, error: Error?) {
        if let response = response {
            for pendingProcessing in response.pendingProcessing {
                if soundId == pendingProcessing.id {
                    sharingSong = false
                    animateActivityIndicator(false)
                    showAlert(title: AudioHandler.Constants.SongProcessing, message: AudioHandler.Constants.SongProcessingNecessaryWait)
                    return
                }
            }
            for pendingModeration in response.pendingModeration {
                if soundId == pendingModeration.id {
                    sharingSong = false
                    animateActivityIndicator(false)
                    showAlert(title: AudioHandler.Constants.SongModerating, message: AudioHandler.Constants.SongModeratingNecessaryWait)
                    return
                }
            }
            let accessToken = UserDefaults.standard.string(forKey: "accessToken")!
            let soundIdStr = String(soundId)
            NetworkClient.getSoundInstance(soundId: soundIdStr, accessToken: accessToken) { url, error in
                self.handleSoundInstanceResponse(url: url, error: error)
            }
        } else {
            sharingSong = false
            animateActivityIndicator(false)
            showAlert(title: "Error to Share", message: (error as! AppError).message)
        }
    }
    
    func handleSoundInstanceResponse(url: String?, error: Error?) {
        sharingSong = false
        animateActivityIndicator(false)
        if let url = url {
            let share: [Any] = [AudioHandler.Constants.MyNewSongCreateWithSweetMagicalMusicBox, URL(string: url)!]
            let activityViewController = UIActivityViewController(activityItems: share, applicationActivities: nil)
            activityViewController.excludedActivityTypes = [.print, .assignToContact, .saveToCameraRoll, .airDrop]
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        } else {
            showAlert(title: AudioHandler.Constants.ErrorShare, message: (error as! AppError).message)
        }
    }
    
    @objc func shareSongBlinkAnimation(){
        if sharingSong {
            UIView.animate(withDuration: 0.2) {
                self.cellShareingInAction.buttonShare.alpha = self.cellShareingInAction.buttonShare.alpha == 1.0 ? 0.0 : 1.0
            }
        } else {
            buttonActionTimer?.invalidate()
            buttonActionTimer = nil
            self.cellShareingInAction.buttonShare.alpha = 1.0
        }
    }
    
    fileprivate func isLoggedIn() -> Bool {
        if registerLoginButton.title == AudioHandler.Constants.Register {
            showAlert(title: AudioHandler.Constants.NeedRegister, message: AudioHandler.Constants.NeedRegisterFreeSounds)
            return false
        } else if registerLoginButton.title == AudioHandler.Constants.Login {
            showAlert(title: AudioHandler.Constants.NeedLogin, message: AudioHandler.Constants.NeedLoginFreeSounds)
            return false
        }
        return true
    }
        
    // MARK: - Back Button action
    
    @objc func backButtonOverrideAction() {
        if playingSong {
            stopAudio()
        }
        if uploadingSong {
            showAlert(title: AudioHandler.Constants.CantExitNow, message: AudioHandler.Constants.WaitUntilFileUploaded)
        } else if sharingSong {
            showAlert(title: AudioHandler.Constants.CantExitNow, message: AudioHandler.Constants.WaitUntilFileShared)
        } else {
            self.navigationController?.popToRootViewController(animated: true)
        }
    }
    
    // MARK: - Indicator functions
    
    func animateActivityIndicator(_ start: Bool) {
        if start {
            self.indicatorView.alpha = 0.45
            self.activityIndicator.startAnimating()
        } else {
            self.indicatorView.alpha = 0
            self.activityIndicator.startAnimating()
        }
    }
    
}
