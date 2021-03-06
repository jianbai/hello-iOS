//
//  GroupChatViewController.swift
//  Going
//
//  Created by scott on 2/5/15.
//  Copyright (c) 2015 spw. All rights reserved.
//

import UIKit
import Foundation


import UIKit
import Foundation

class GroupChatViewController: JSQMessagesViewController {
    @IBOutlet var emptyView: UIView!

    let parseConstants: ParseConstants = ParseConstants()
    let firebaseConstants: FirebaseConstants = FirebaseConstants()
    
    var currentUser: PFUser!
    var groupMembers: [PFUser] = []
    var messages = [Message]()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory.outgoingMessageBubbleImageViewWithColor(UIColor(red: 0.99, green: 0.66, blue: 0.26, alpha: 1.0))
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory.incomingMessageBubbleImageViewWithColor(UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1.0))
    var batchMessages = true
    var loadingScreen: UIView!
    var groupChatRef: Firebase!
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        
        self.showLoadingScreen()
        self.currentUser = PFUser.currentUser()
        self.sender = self.currentUser[parseConstants.KEY_FIRST_NAME] as String
        
        self.styleNavigationBar()
        self.styleCollectionView()
        self.styleInputToolbar()
 
        self.setupFirebase()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.addSingleEventObserver()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.springinessEnabled = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        loadingScreen.removeFromSuperview()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showMatchExpired") {
            self.definesPresentationContext = true
            self.title = "Match Expired!"
            var item = self.tabBarController?.tabBar.items![1] as UITabBarItem
            item.title = nil
            var matchExpiredViewController = segue.destinationViewController as MatchExpiredViewController
            matchExpiredViewController.groupMembers = self.groupMembers
            matchExpiredViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        } else if (segue.identifier == "showProfiles") {
            self.title = "In This Chat"
            var item = self.tabBarController?.tabBar.items![1] as UITabBarItem
            item.title = nil
            self.definesPresentationContext = true
            var profilesViewController = segue.destinationViewController as ProfilesViewController
            profilesViewController.groupMembers = self.groupMembers
            profilesViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Stop, target: self, action: ("exitProfiles:"))
        }
    }
    
    // MARK: - CollectionView Delegate
    
    override func didPressSendButton(button: UIButton!, withMessageText text: String!, sender: String!, date: NSDate!) {
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        var time = self.getTimeStamp(date)
        
        sendMessage(text, sender: sender, time: time)
        
        finishSendingMessage()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, bubbleImageViewForItemAtIndexPath indexPath: NSIndexPath!) -> UIImageView! {
        let message = messages[indexPath.item]
        
        if message.sender() == sender {
            return UIImageView(image: outgoingBubbleImageView.image, highlightedImage: outgoingBubbleImageView.highlightedImage)
        }
        
        return UIImageView(image: incomingBubbleImageView.image, highlightedImage: incomingBubbleImageView.highlightedImage)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageViewForItemAtIndexPath indexPath: NSIndexPath!) -> UIImageView! {
        return nil
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as JSQMessagesCollectionViewCell
        
        cell.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        
        let message = messages[indexPath.item]
        if message.sender() == sender {
            cell.textView.textColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        } else {
            cell.textView.textColor = UIColor(red: 0.20, green: 0.20, blue: 0.20, alpha: 1.0)
        }
        
        let attributes : [NSObject:AnyObject] = [NSForegroundColorAttributeName:cell.textView.textColor, NSUnderlineStyleAttributeName: 1]
        cell.textView.linkTextAttributes = attributes
        
        return cell
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        let message = messages[indexPath.item];
        
        // Sent by me, skip
        if message.sender() == sender {
            return nil;
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.sender() == message.sender() {
                return nil;
            }
        }
        
        var tag = message.sender() + " :: " + message.time()
        
        return NSAttributedString(string:tag)
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        let message = messages[indexPath.item]
        
        // Sent by me, skip
        if message.sender() == sender {
            return CGFloat(0.0);
        }
        
        // Same as previous sender, skip
        if indexPath.item > 0 {
            let previousMessage = messages[indexPath.item - 1];
            if previousMessage.sender() == message.sender() {
                return CGFloat(0.0);
            }
        }
        
        return kJSQMessagesCollectionViewCellLabelHeightDefault
    }
    
    // MARK: - Helper Functions
    
    func showLoadingScreen() {
        self.loadingScreen = NSBundle.mainBundle().loadNibNamed("Loading", owner: self, options: nil)[0] as UIView
        self.loadingScreen.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
        self.view.addSubview(loadingScreen)
    }
    
    func styleNavigationBar() {
        self.navigationController?.navigationBar.tintColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: ("showProfiles:"))
        self.navigationItem.hidesBackButton = true
    }
    
    func styleCollectionView() {
        if (self.messages.count == 0) {
            self.collectionView.addSubview(self.emptyView)
        }
        
        self.collectionView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        self.collectionView.collectionViewLayout.incomingAvatarViewSize = CGSizeZero
        self.collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSizeZero
        self.automaticallyScrollsToMostRecentMessage = true
    }
    
    func styleInputToolbar() {
        self.inputToolbar.contentView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        self.inputToolbar.contentView.textView.backgroundColor = UIColor(red: 0.96, green: 0.96, blue: 0.94, alpha: 1.0)
        self.inputToolbar.contentView.textView.placeHolder = "Write a message"
        self.inputToolbar.contentView.leftBarButtonItem = nil
        self.inputToolbar.contentView.rightBarButtonItem.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 16)
    }
    
    func setupFirebase() {
        var query = PFQuery(className: self.parseConstants.CLASS_GROUPS)
        query.whereKey(self.parseConstants.KEY_GROUP_MEMBER_IDS, equalTo: self.currentUser.objectId)
        query.getFirstObjectInBackgroundWithBlock { (group, error) -> Void in
            self.groupChatRef = Firebase(url: self.firebaseConstants.URL_GROUP_CHATS).childByAppendingPath(group.objectId)
            self.groupChatRef.observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
                if (snapshot.value as NSObject == NSNull() && self.loadingScreen != nil) {
                    self.loadingScreen.removeFromSuperview()
                }
            })
            
            self.groupChatRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
                let text = snapshot.value["message"] as? String
                let sender = snapshot.value["author"] as? String
                let time = snapshot.value["time"] as? String
                
                let message = Message(text: text, sender: sender, time: time)
                self.messages.append(message)
                
                self.emptyView.removeFromSuperview()
                
                self.finishReceivingMessage()
                
                if (self.loadingScreen != nil) {
                    self.loadingScreen.removeFromSuperview()
                }
            })
        }
    }
    
    func sendMessage(text: String!, sender: String!, time: String!) {
        self.groupChatRef.childByAutoId().setValue([
            "message":text,
            "author":sender,
            "time":time
            ])
    }
    
    func tempSendMessage(text: String!, sender: String!, time: String!) {
        let message = Message(text: text, sender: sender, time: time)
        messages.append(message)
    }
    
    func addSingleEventObserver() {
        let currentUserRef = Firebase(url: firebaseConstants.URL_USERS)
            .childByAppendingPath(self.currentUser.objectId)
            .childByAppendingPath(firebaseConstants.KEY_MATCHED)
        
        currentUserRef.observeSingleEventOfType(.Value, withBlock: { (snapshot) -> Void in
            var isMatched = snapshot.value as Bool
            
            if (!isMatched) {
                self.onMatchExpired()
            }
        })
    }
    
    func onMatchExpired() {
        self.navigationItem.rightBarButtonItem = nil
        self.performSegueWithIdentifier("showMatchExpired", sender: self)
        
        loadingScreen = NSBundle.mainBundle().loadNibNamed("Loading", owner: self, options: nil)[0] as UIView
        loadingScreen.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
        self.view.addSubview(loadingScreen)
    }
    
    func receivedMessagePressed(sender: UIBarButtonItem) {
        showTypingIndicator = !showTypingIndicator
        scrollToBottomAnimated(true)
    }
    
    func getTimeStamp(date: NSDate) -> String {
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "h'.'mm a"
        
        return dateFormatter.stringFromDate(date)
    }
    
    // ACTIONS
    
    @IBAction func showProfiles(sender: UIBarButtonItem) {
        performSegueWithIdentifier("showProfiles", sender: self)
    }
    
    @IBAction func exitProfiles(sender: UIBarButtonItem) {
        self.title = "This Weekend"
        var item = self.tabBarController?.tabBar.items![1] as UITabBarItem
        item.title = nil
        
        self.navigationController?.visibleViewController.dismissViewControllerAnimated(true, completion: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: ("showProfiles:"))
    }
}