//
//  BugViewController.swift
//  Going
//
//  Created by scott on 2/4/15.
//  Copyright (c) 2015 spw. All rights reserved.
//

import UIKit

class BugViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var bugLabel: UILabel!
    @IBOutlet weak var bugTextField: UITextField!
    @IBOutlet weak var reportButton: UIButton!
    
    let currentUser: PFUser = PFUser.currentUser()
    let parseConstants: ParseConstants = ParseConstants()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        
        self.styleReportButton()
        self.styleNavigationBar()
        
        self.bugTextField.returnKeyType = UIReturnKeyType.Done
        self.bugTextField.delegate = self
        self.bugTextField.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
    }
    
    // MARK: - TextField Delegate
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.animateTextField(textField, up: true)
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.animateTextField(textField, up: false)
    }
    
    // MARK: - Helper Functions
    
    func styleNavigationBar() {
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.99, green: 0.66, blue: 0.26, alpha: 1.0)
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 18)!,
            NSForegroundColorAttributeName: UIColor.whiteColor()]
    }
    
    func styleReportButton() {
        self.reportButton.backgroundColor = UIColor.clearColor()
        self.reportButton.layer.cornerRadius = 5
        self.reportButton.layer.borderWidth = 1
        self.reportButton.layer.borderColor = UIColor(red: 0.99, green: 0.66, blue: 0.26, alpha: 1.0).CGColor
        self.reportButton.tintColor = UIColor(red: 0.99, green: 0.66, blue: 0.26, alpha: 1.0)
    }
    
    func animateTextField(textField: UITextField, up: Bool) {
        
        self.bugLabel.hidden = up
        var movementDistance: CGFloat = 80
        let movementDuration = 0.3
        
        var movement: CGFloat = (up ? -movementDistance : movementDistance)
        
        UIView.beginAnimations("anim", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration)
        self.view.frame = CGRectOffset(self.view.frame, 0, movement)
        
        UIView.commitAnimations()
    }
    
    // MARK: - Actions

    @IBAction func report(sender: UIButton) {
        var bugText = self.bugTextField.text
        self.currentUser.addObject(bugText, forKey: parseConstants.KEY_BUG_REPORTS)
        self.currentUser.saveInBackgroundWithBlock { (succeeded, error) -> Void in
        }
        self.navigationController?.popViewControllerAnimated(true)
    }
}
