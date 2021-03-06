//
//  LoginViewController.swift
//  Going
//
//  Created by scott on 1/29/15.
//  Copyright (c) 2015 spw. All rights reserved.
//


import UIKit

class LoginViewController: UIViewController, UIPageViewControllerDataSource {
    
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var loginActivityIndicator: UIActivityIndicatorView!
    
    let pageViewController: UIPageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
    let pageText: [String] = LoginTutorial().getText()
    let pageImages: [String] = LoginTutorial().getImages()
    let permissions: [String] = ["public_profile", "user_friends", "email"]
    // "user_birthday", "hometown",
    let parseConstants: ParseConstants = ParseConstants()
    let firebaseConstants: FirebaseConstants = FirebaseConstants()
    let ref: Firebase = Firebase(url: "https://sayhello.firebaseio.com/web/data/users")
    
    var views: [LoginPageContentViewController] = []
    var currentUser: PFUser!
    var noGender: Bool!
    var noAge: Bool!
    var noHometown: Bool!
    var loadingScreen: UIView!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        self.pageViewController.dataSource = self
        
        self.setupLoginTutorial()
        self.styleLoginButton()
        self.showLoadingScreen()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        UIApplication.sharedApplication().setStatusBarStyle(UIStatusBarStyle.Default, animated: true)
        self.hideActivityIndicator()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        var user = PFUser.currentUser()
        
        if (user != nil && PFFacebookUtils.isLinkedWithUser(user)) {
            self.performSegueWithIdentifier("showMain", sender: self)
        } else {
            self.hideLoadingScreen()
        }
    }
    
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        super.prepareForSegue(segue, sender: sender)
        
        if (segue.identifier == "showSetProfile") {
            var setProfileViewController = segue.destinationViewController as SetProfileViewController
            setProfileViewController.setBools(self.noGender!, noAge: self.noAge!, noHometown: self.noHometown!)
        } else if (segue.identifier == "showPrivacy") {
            var nav = segue.destinationViewController.navigationBar
            self.styleNavigationBar(nav)
        }
    }
    
    // MARK: - PageViewController Data Source
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as LoginPageContentViewController).pageIndex
        
        if index == 0 || index == NSNotFound {
            return nil
        }
        
        index--
        
        return self.views[index]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        
        var index = (viewController as LoginPageContentViewController).pageIndex
        
        if index == NSNotFound {
            return nil
        }
        
        index++
        
        if index == self.pageText.count {
            return nil
        }
        
        return self.views[index];
        
    }
    
    func viewControllerAtIndex(index : Int) -> LoginPageContentViewController? {
        if self.pageText.count == 0 || index >= self.pageText.count {
            return nil;
        }
        
        // Create a new view controller and pass suitable data.
        let pageContentViewController = self.storyboard!.instantiateViewControllerWithIdentifier("LoginPageContentViewController") as LoginPageContentViewController
        pageContentViewController.image = self.pageImages[index]
        pageContentViewController.text = self.pageText[index]
        pageContentViewController.view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        pageContentViewController.pageIndex = index
        
        return pageContentViewController;
    }
    
    func presentationCountForPageViewController(pageViewController: UIPageViewController) -> Int {
        return self.pageText.count
    }
    
    func presentationIndexForPageViewController(pageViewController: UIPageViewController) -> Int {
        return 0
    }
    
    // MARK: - Helper Functions
    
    func styleLoginButton() {
        self.loginButton.backgroundColor = UIColor.clearColor()
        self.loginButton.layer.cornerRadius = 5
        self.loginButton.layer.backgroundColor = UIColor(red: (59.0/255.0), green: (89.0/255.0), blue: (152.0/255.0), alpha: 1.0).CGColor
    }
    
    func setupLoginTutorial() {
        for var i=0; i<self.presentationCountForPageViewController(pageViewController); ++i {
            self.views.append(viewControllerAtIndex(i)!)
        }
        
        let startingViewController : LoginPageContentViewController = self.viewControllerAtIndex(0)!
        let viewControllers: NSArray = [startingViewController]
        self.pageViewController
            .setViewControllers(viewControllers, direction: .Forward, animated: false, completion: nil)
        
        // Change the size of page view controller
        self.pageViewController.view.frame =
            CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height - 90);
        
        self.addChildViewController(self.pageViewController)
        self.view.addSubview(self.pageViewController.view)
        self.pageViewController.didMoveToParentViewController(self)
        
        let appearance = UIPageControl.appearance()
        appearance.pageIndicatorTintColor = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 0.30)
        appearance.currentPageIndicatorTintColor = UIColor(red: 0.99, green: 0.66, blue: 0.26, alpha: 1.0)
        appearance.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
    }
    
    func styleNavigationBar(nav: UINavigationBar) {
        nav.barTintColor = UIColor(red: 0.99, green: 0.66, blue: 0.26, alpha: 1.0)
        nav.translucent = false
        nav.titleTextAttributes = [
            NSFontAttributeName: UIFont(name: "HelveticaNeue-Light", size: 18)!,
            NSForegroundColorAttributeName: UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)]
        nav.tintColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
    }
    
    func fetchFacebookData() {
        var session = PFFacebookUtils.session()
        if (session != nil && session.isOpen) {
            self.makeMeRequest()
            self.makeMyFriendsRequest()
        }
    }
    
    func makeMeRequest() {
        var request = FBRequest.requestForMe()
        request.startWithCompletionHandler { (connection: FBRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            if (error == nil) {
                var userData = result as NSDictionary
                
                // Update Parse user info with results
                self.updateUserProfile(userData)
                self.updateUserAge(userData)
                self.updateUserHometown(userData)
                self.updateUserDefaultParseValues()
                
                // Save user info
                
                self.currentUser.saveInBackgroundWithBlock {
                    (succeeded: Bool!, error: NSError!) -> Void in
                    if (error == nil) {
                        self.saveUserToFirebase()
                        if (self.isUserProfileIncomplete()) {
                            self.performSegueWithIdentifier("showSetProfile", sender: self)
                        } else {
                            self.performSegueWithIdentifier("showMain", sender: self)
                        }
                    } else {
                        self.showErrorAlert()
                    }
                    self.hideActivityIndicator()
                }
                
            }
        }
    }
    
    func makeMyFriendsRequest() {
        var request = FBRequest.requestForMyFriends()
        request.startWithCompletionHandler { (connection: FBRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            if (error == nil) {
                var friendsData = result as NSDictionary
                var friendsArray = friendsData.objectForKey("data") as NSArray
                
                for friend in friendsArray {
                    if let id = friend.objectForKey("id") as? String {
                        self.currentUser.addUniqueObject(id, forKey: self.parseConstants.KEY_FACEBOOK_FRIENDS)
                    }
                }
                
                self.currentUser.saveInBackgroundWithBlock({ (succeeded, error) -> Void in
                })
            }
        }
    }
    
    func saveUserToFirebase() {
        var parseId = self.currentUser.objectId
        var firstName: String = self.currentUser.objectForKey(parseConstants.KEY_FIRST_NAME) as String
        var lastName: String = self.currentUser.objectForKey(parseConstants.KEY_LAST_NAME) as String
        var fullName: String = firstName + " " + lastName
        
        var userData = [firebaseConstants.KEY_FULL_NAME: fullName, firebaseConstants.KEY_MATCHED: false]
        var userRef = self.ref.childByAppendingPath(parseId)
        
        userRef.setValue(userData)
    }
    
    func isUserProfileIncomplete() -> Bool {
        self.noGender = self.currentUser.objectForKey(parseConstants.KEY_GENDER) == nil
        self.noAge = self.currentUser.objectForKey(parseConstants.KEY_AGE) == nil
        self.noHometown = self.currentUser.objectForKey(parseConstants.KEY_HOMETOWN) == nil
        
        var missing = self.noGender! || self.noAge! || self.noHometown!
        
        return self.noGender! || self.noAge! || self.noHometown!
    }
    
    func updateUserProfile(userData : NSDictionary) {
        // Add Facebook Id
        self.currentUser[parseConstants.KEY_FACEBOOK_ID] = userData.objectForKey("id") as String
        
        // Add name
        self.currentUser[parseConstants.KEY_FIRST_NAME] = userData.objectForKey("first_name") as String
        self.currentUser[parseConstants.KEY_LAST_NAME] = userData.objectForKey("last_name") as String
        
        // Add gender
        if (userData.objectForKey("gender") != nil) {
            self.currentUser[parseConstants.KEY_GENDER] = userData.objectForKey("gender") as String
        }
        
        // Add email
        if (userData.objectForKey("email") != nil) {
            self.currentUser[parseConstants.KEY_EMAIL] = userData.objectForKey("email") as String
        }
    }
    
    func updateUserAge(userData : NSDictionary) {
        if (userData.objectForKey("birthday") != nil) {
            var birthday = userData.objectForKey("birthday") as String
            self.currentUser[parseConstants.KEY_BIRTHDAY] = birthday
            
            var age = calculateAge(birthday)
            self.currentUser[parseConstants.KEY_AGE] = age as String
        }
    }
    
    func updateUserHometown(userData : NSDictionary) {
        if (userData.objectForKey("hometown") != nil) {
            var error: NSError?
            let hometownData = userData.objectForKey("user_hometown") as NSData
            
            let parsedObject : AnyObject? = NSJSONSerialization.JSONObjectWithData(hometownData, options: NSJSONReadingOptions.AllowFragments, error: &error)
            
            if let data = parsedObject as? NSDictionary {
                if let hometownName = data[parseConstants.KEY_HOMETOWN_NAME] as? String {
                    self.currentUser[parseConstants.KEY_HOMETOWN] = hometownName
                }
            }
        }
    }
    
    func updateUserDefaultParseValues() {
        self.currentUser[parseConstants.KEY_IS_MATCHED] = false
        self.currentUser[parseConstants.KEY_IS_SEARCHING] = false
        self.currentUser[parseConstants.KEY_MATCH_DIALOG_SEEN] = false
        self.currentUser[parseConstants.KEY_PICK_FRIENDS_DIALOG_SEEN] = true
        self.currentUser[parseConstants.KEY_GENDER_SETTINGS] = 0
        self.currentUser[parseConstants.KEY_AGE_SETTINGS_0] = true
        self.currentUser[parseConstants.KEY_AGE_SETTINGS_20] = false
        self.currentUser[parseConstants.KEY_AGE_SETTINGS_30] = false
        self.currentUser[parseConstants.KEY_AGE_SETTINGS_40] = false
        self.currentUser[parseConstants.KEY_EULA_AGREED] = false
    }
    
    func calculateAge(birthday : String) -> String {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        var date = dateFormatter.dateFromString(birthday)
        var cal = NSCalendar.currentCalendar()
        
        var age = String(cal.components(NSCalendarUnit.CalendarUnitYear, fromDate: date!, toDate: NSDate(), options: nil).year)
        
        return age
    }
    
    func showErrorAlert() {
        let loginErrorController = UIAlertController(title: "Login Error", message: "Something is rotten in the state of your network connection...", preferredStyle: .Alert)
        let okButton = UIAlertAction(title: "OK", style: .Default, handler: nil)
        loginErrorController.addAction(okButton)
        
        self.presentViewController(loginErrorController, animated: true, completion: nil)
    }
    
    func showActivityIndicator() {
        loginButton.hidden = true
        loginActivityIndicator.hidden = false
        loginActivityIndicator.startAnimating()
    }
    
    func hideActivityIndicator() {
        loginButton.hidden = false
        loginActivityIndicator.hidden = true
        loginActivityIndicator.stopAnimating()
    }
    
    func showLoadingScreen() {
        self.loadingScreen =
            NSBundle.mainBundle().loadNibNamed("Loading", owner: self, options: nil)[0] as UIView
        self.loadingScreen.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
        self.view.addSubview(loadingScreen)
    }
    
    func hideLoadingScreen() {
        self.loadingScreen.removeFromSuperview()
    }
    
    // MARK: - Actions
    
    @IBAction func showPrivacy() {
        self.performSegueWithIdentifier("showPrivacy", sender: self)
    }
    
    @IBAction func login() {
        self.showActivityIndicator()
        
        PFFacebookUtils.logInWithPermissions(permissions, {
            (user: PFUser!, error: NSError!) -> Void in
            self.currentUser = PFUser.currentUser()
            
            if user == nil {
                self.showErrorAlert()
                self.hideActivityIndicator()
            } else if user.isNew {
                self.fetchFacebookData()
            } else {
                self.performSegueWithIdentifier("showMain", sender: self)
            }
        })
    }
    
}














