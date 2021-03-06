//
//  FirstViewController.swift
//  Going
//
//  Created by scott on 1/27/15.
//  Copyright (c) 2015 spw. All rights reserved.
//

import UIKit

class SettingsViewController: UITableViewController {
    @IBOutlet weak var profileNameLabel: UILabel!
    @IBOutlet weak var profileInfoLabel: UILabel!
    @IBOutlet weak var profileView: UIView!

    let settings: [String] = ["",
        "Age preferences",
        "Gender preferences",
        "FAQ",
        "Report a bug",
        "Get in touch",
        "Log out",
        ""]
    let parseConstants: ParseConstants = ParseConstants()
    let currentUser: PFUser = PFUser.currentUser()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        self.styleNavigationBar()
        self.setupProfile()
    }
    
    // MARK: - TableView Data Source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.settings.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cellIdentifier = "Cell"
        
        var cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as UITableViewCell
        
        cell.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        
        cell.textLabel?.text = self.settings[indexPath.row]
        cell.textLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 18)
        
        return cell
    }
    
    // MARK: - TableView Delegate
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if (indexPath.row == 0 || indexPath.row == 7) {
            return 0.5
        } else {
            return super.tableView(tableView, heightForRowAtIndexPath: indexPath)
        }
    }
    
    override func tableView(tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    override func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView(frame: CGRectZero)
    }
    
    override func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRectZero)
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        switch indexPath.row {
        // Age preferences
        case 1:
            self.performSegueWithIdentifier("showAgePreferences", sender: self)
            break
        // Gender preferences
        case 2:
            self.performSegueWithIdentifier("showGenderPreferences", sender: self)
            break
        // FAQ
        case 3:
            self.performSegueWithIdentifier("showFaq", sender: self)
            break
        // Report a bug
        case 4:
            self.performSegueWithIdentifier("showBug", sender: self)
            break
        // Get in touch
        case 5:
            self.performSegueWithIdentifier("showContact", sender: self)
            break
        // Logout
        case 6:
            self.logOut()
            break
        default:
            break
        }
    }
    
    // MARK: - Table cell click handlers
    
    func styleNavigationBar() {
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 0.99, green: 0.66, blue: 0.26, alpha: 1.0)
        self.navigationController?.navigationBar.translucent = false
        self.navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 18)!,
            NSForegroundColorAttributeName: UIColor.whiteColor()]
        self.navigationController?.navigationBar.tintColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
    }
    
    func setupProfile() {
        self.profileView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        let userName = self.currentUser[parseConstants.KEY_FIRST_NAME] as String
        let userAge = self.currentUser[parseConstants.KEY_AGE] as String
        let userHometown = self.currentUser[parseConstants.KEY_HOMETOWN] as String
        self.profileNameLabel.text = userName
        self.profileInfoLabel.text = userAge + "  : :  " + userHometown
    }
    
    func logOut() {
        if (PFFacebookUtils.session() != nil) {
            PFFacebookUtils.session().closeAndClearTokenInformation()
        }
        
        PFUser.logOut()
        
        self.tabBarController?.dismissViewControllerAnimated(true, completion: { () -> Void in
        })
        
    }
    
}

