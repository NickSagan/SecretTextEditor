//
//  ViewController.swift
//  SecretTextEditor
//
//  Created by Nick Sagan on 01.12.2021.
//

import UIKit
import LocalAuthentication

class ViewController: UIViewController {
    
    var userPin = "6666"
    var hasPassword = false

    @IBOutlet weak var pin: UITextField!
    @IBOutlet weak var secret: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let checkForPass = KeychainWrapper.standard.bool(forKey: "hasPassword") {
            hasPassword = checkForPass
            userPin =  KeychainWrapper.standard.string(forKey: "pin")!
        }
        
        if !hasPassword {
            let ac = UIAlertController(title: "Set your pin", message: nil, preferredStyle: .alert)

            // create submit alert button
            let submitAction = UIAlertAction(title: "Done", style: .default) {
                // parameters we send into
                [weak self, weak ac] _ in
                // closure body
                guard let input = ac?.textFields?[0].text else {return}
                self?.userPin = input
                self?.hasPassword = true
                KeychainWrapper.standard.set(input, forKey: "pin")
                KeychainWrapper.standard.set(true, forKey: "hasPassword")

            }
            
            // add created button
            ac.addAction(submitAction)
            // present alert
            present(ac, animated: true)
        }
        
        // to make the text view adjust its content and scroll insets when the keyboard appears and disappears
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(saveSecretMessage), name: UIApplication.willResignActiveNotification, object: nil)
    }
    @IBAction func cancelTapped(_ sender: Any) {
        saveSecretMessage()
    }
    
    @IBAction func authenticateTapped(_ sender: UIButton) {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Identify yourself!"

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) {
                [weak self] success, authenticationError in

                DispatchQueue.main.async {
                    if success && self?.pin.text == self?.userPin {
                        self?.unlockSecretMessage()
                    } else {
                        let ac = UIAlertController(title: "Authentication failed", message: "You could not be verified; please try again.", preferredStyle: .alert)
                        ac.addAction(UIAlertAction(title: "OK", style: .default))
                        self?.present(ac, animated: true)
                    }
                }
            }
        } else {
            let ac = UIAlertController(title: "Biometry unavailable", message: "Your device is not configured for biometric authentication.", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(ac, animated: true)
        }
        
        unlockSecretMessage()
    }
    
    @objc func adjustForKeyboard(notification: Notification) {
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }

        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)

        if notification.name == UIResponder.keyboardWillHideNotification {
            secret.contentInset = .zero
        } else {
            secret.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }

        secret.scrollIndicatorInsets = secret.contentInset

        let selectedRange = secret.selectedRange
        secret.scrollRangeToVisible(selectedRange)
    }
    
    // Load from keychain
    func unlockSecretMessage() {
        secret.isHidden = false
        title = "SecretText"

        if let text = KeychainWrapper.standard.string(forKey: "SecretText") {
            secret.text = text
        }
    }
    
    // Save to keychain
    @objc func saveSecretMessage() {
        guard secret.isHidden == false else { return }

        KeychainWrapper.standard.set(secret.text, forKey: "SecretText")
        secret.resignFirstResponder()
        secret.isHidden = true
        title = "Nothing to see here"
    }
}

