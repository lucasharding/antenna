//
//  LoginViewController.swift
//  ustvnow-tvos
//
//  Created by Lucas Harding on 2015-09-12.
//  Copyright © 2015 Lucas Harding. All rights reserved.
//

import UIKit

class LoginViewController : UIViewController, UITextFieldDelegate {
    
    //MARK: IBOutlets

    @IBOutlet var usernameTextField: UITextField!
    @IBOutlet var passwordTextField: UITextField!
    @IBOutlet var loadingCoverView: UIView!
    
    //MARK: View
    
    open override func viewDidLoad() {
        super.viewDidLoad()
                
        self.view.bringSubview(toFront: self.loadingCoverView)
        self.loadingCoverView.isHidden = true
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if (TVService.sharedInstance.isLoggedIn) {
            self.loadingCoverView.isHidden = false
            
            TVService.sharedInstance.getAccount() { account, error in
                self.loadingCoverView.isHidden = true
            }
        }
    }
    
    //MARK: UITextFieldDelegate
    
    open func textFieldDidEndEditing(_ textField: UITextField) {
        if (self.passwordTextField == textField) {
            startLogin()
        }
    }
    
    //MARK: Actions
    
    @IBAction open func startLogin() -> Void {
        if ((self.usernameTextField.text?.characters.count ?? 0) > 0 && (self.passwordTextField.text?.characters.count ?? 0) > 0) {
            self.loadingCoverView.isHidden = false
            
            TVService.sharedInstance.login(self.usernameTextField.text!, password: self.passwordTextField.text!) {
                account, error in
                
                if let error = error {
                    let alert = UIAlertController(title: "Login Failed", message: error.localizedDescription, preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .cancel) { action in
                        alert.dismiss(animated: true, completion: nil)
                    })
                    self.present(alert, animated: true, completion: nil)
                }
                else if (TVService.sharedInstance.currentAccount?.needAccountActivation == true) {
                    let controller = UIAlertController(title: "Your account still needs to be verified", message: "To fully activate your account, check your email inbox.", preferredStyle: .alert)
                    controller.addAction(UIAlertAction(title: "OK. I activated my account.", style: .default) { _ in
                        self.startLogin()
                    })
                    controller.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    self.present(controller, animated: true, completion: nil)
                }

                self.loadingCoverView.isHidden = true
            }
        }
    }
        
}
