//
//  RegisterController.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 21/03/21.
//

import Foundation
import UIKit

class RegisterController: UIViewController, UITextFieldDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var clientIdTextField: UITextField!
    @IBOutlet weak var clientSecretTextField: UITextField!
    @IBOutlet weak var saveCodesButton: UIButton!
    @IBOutlet weak var codesStackView: UIStackView!
    
    // MARK: - Properties
    
    var keyboardIsVisible = false
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clientIdTextField.delegate = self
        clientSecretTextField.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.view.endEditing(true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        subscribeToKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromKeyboardNotifications()
    }
    
    // MARK: - Actions
    
    @IBAction func registerFreeSoundsButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        NetworkClient.openURL(from: NetworkClient.Endpoints.register) {}
    }
    
    @IBAction func saveCodesButtonAction(_ sender: Any) {
        self.view.endEditing(true)
        if clientIdTextField.text!.isEmpty || clientSecretTextField.text!.isEmpty {
            showAlert(title: AudioHandler.Constants.CopyAllFields, message: AudioHandler.Constants.StepsToRegister)
        } else {
            let userDefaults = UserDefaults.standard
            userDefaults.set(clientIdTextField.text, forKey: "clientId")
            userDefaults.set(clientSecretTextField.text, forKey: "clientSecret")
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    // MARK: - Text field delegate functions
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let isBackSpace = strcmp(string.cString(using: String.Encoding.utf8)!, "\\b") == -92
        return string.isAlphanumeric || isBackSpace
    }
    
    // MARK: - Subscribe and unsubscribe from keyboard notifications
    
    func subscribeToKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }

    func unsubscribeFromKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Functions related to keyboard presentation
    
    // Function called when keyboard must be shown and the screen must be moved up
    @objc func keyboardWillShow(_ notification:Notification) {
        if !keyboardIsVisible && (clientIdTextField.isEditing || clientSecretTextField.isEditing) {
            let height = clientIdTextField.frame.height + clientSecretTextField.frame.height + saveCodesButton.frame.height
            view.frame.origin.y -= height
            keyboardIsVisible = true
        }
    }
    
    // Function called when screen must be moved down
    @objc func keyboardWillHide(_ notification:Notification) {
        if keyboardIsVisible {
            let height = clientIdTextField.frame.height + clientSecretTextField.frame.height + saveCodesButton.frame.height
            view.frame.origin.y += height
            keyboardIsVisible = false
        }
    }
    
}
