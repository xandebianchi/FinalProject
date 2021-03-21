//
//  RegisterController.swift
//  SweetMagicalMusicBox
//
//  Created by Alexandre Bianchi on 21/03/21.
//

import Foundation
import UIKit

class RegisterController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var clientIdTextField: UITextField!
    @IBOutlet weak var clientSecretTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        clientIdTextField.delegate = self
        clientSecretTextField.delegate = self
    }
    
    @IBAction func registerFreeSoundsButtonAction(_ sender: Any) {
        NetworkClient.openURL(from: NetworkClient.Endpoints.register) {
        }
    }
    
    @IBAction func registerButtonAction(_ sender: Any) {
        if clientIdTextField.text!.isEmpty || clientSecretTextField.text!.isEmpty {
            showAlert(title: "Copy all fields", message: "You must copy the both fields from FreeSounds. Click in the message to register a new API and copy the codes to here.")
        } else {
            let userDefaults = UserDefaults.standard
            userDefaults.set(clientIdTextField.text, forKey: "clientId")
            userDefaults.set(clientSecretTextField.text, forKey: "clientSecret")
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}
