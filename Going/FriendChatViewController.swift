//
//  FriendChatViewController.swift
//  Going
//
//  Created by scott on 2/9/15.
//  Copyright (c) 2015 spw. All rights reserved.
//

import UIKit

class FriendChatViewController: JSQMessagesViewController {
    
    @IBOutlet var emptyView: UIView!
    
    let parseConstants: ParseConstants = ParseConstants()
    let firebaseConstants: FirebaseConstants = FirebaseConstants()
    
    var currentUser: PFUser!
    var chatId: String!
    var friend: PFUser!
    var messages = [Message]()
    var outgoingBubbleImageView = JSQMessagesBubbleImageFactory.outgoingMessageBubbleImageViewWithColor(UIColor(red: 0.99, green: 0.66, blue: 0.26, alpha: 1.0))
    var incomingBubbleImageView = JSQMessagesBubbleImageFactory.incomingMessageBubbleImageViewWithColor(UIColor(red: 0.91, green: 0.91, blue: 0.91, alpha: 1.0))
    var batchMessages = true
    var loadingScreen: UIView!
    var friendChatRef: Firebase!
    
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
        
        setupFirebase()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.collectionViewLayout.springinessEnabled = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if (segue.identifier == "showEditFriend") {
            var editFriendViewController = segue.destinationViewController as EditFriendViewController
            editFriendViewController.friend = self.friend
            
            self.definesPresentationContext = true
            var item = self.tabBarController?.tabBar.items![1] as UITabBarItem
            item.title = nil
            
            editFriendViewController.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
            
            self.navigationItem.backBarButtonItem = nil
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Stop, target: self, action: ("exitEdit:"))
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
        loadingScreen = NSBundle.mainBundle().loadNibNamed("Loading", owner: self, options: nil)[0] as UIView
        loadingScreen.frame = CGRectMake(0, 0, self.view.frame.width, self.view.frame.height)
        self.view.addSubview(loadingScreen)
    }
    
    func styleNavigationBar() {
        self.navigationItem.title = self.friend[parseConstants.KEY_FIRST_NAME] as? String
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: Selector("editFriend:"))
        self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .Plain, target: nil, action: nil)
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
        self.friendChatRef = Firebase(url: self.firebaseConstants.URL_FRIEND_CHATS).childByAppendingPath(self.chatId)
        self.friendChatRef.observeSingleEventOfType(FEventType.Value, withBlock: { (snapshot) -> Void in
            if (snapshot.value as NSObject == NSNull() && self.loadingScreen != nil) {
                self.loadingScreen.removeFromSuperview()
            }
        })
        self.friendChatRef.observeEventType(FEventType.ChildAdded, withBlock: { (snapshot) in
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
    
    func sendMessage(text: String!, sender: String!, time: String!) {
        self.friendChatRef.childByAutoId().setValue([
            "message":text,
            "author":sender,
            "time":time
            ])
    }
    
    func tempSendMessage(text: String!, sender: String!, time: String!) {
        let message = Message(text: text, sender: sender, time: time)
        messages.append(message)
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
    
    // MARK: - ACTIONS
    
    @IBAction func exitEdit(sender: UIBarButtonItem) {
        self.navigationController?.visibleViewController.dismissViewControllerAnimated(true, completion: nil)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Action, target: self, action: ("editFriend:"))
    }

    @IBAction func editFriend(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("showEditFriend", sender: self)
    }
}