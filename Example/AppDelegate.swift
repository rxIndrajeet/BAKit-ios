//
//  AppDelegate.swift
//  BAKit
//
//  Created by HVNT on 08/23/2018.
//  Copyright (c) 2018 HVNT. All rights reserved.
//

import BAKit
import Firebase
import UIKit
import UserNotifications
import os.log
import Messages

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate  {
    var window: UIWindow?
    
    public var badgeNumber = UIApplication.shared.applicationIconBadgeNumber

    private let authOptions = UNAuthorizationOptions(arrayLiteral: [.alert, .badge, .sound])

    func application(_ application: UIApplication, willFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        BoardActive.client.setupEnvironment(appID: "127", appKey: "209d9729-0887-466b-a061-b2a42bd4626a")
        if (!BoardActive.client.userDefaults!.bool(forKey:.DeviceRegistered)) {
            showLogin()
        } else {
            self.requestNotifications()
        }
        
        Messaging.messaging().delegate = self

        application.applicationIconBadgeNumber = 0
        
        return true
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        os_log("App Did Finish Launching")
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        os_log("App Became Active Again")
    }
    
    func showLogin() {
        let alertController = LoginAlertController(title: "Log in", message: "Please enter your credentials", preferredStyle: .alert)
        
        alertController.configure()
    }
    
    public func setupSDK() {
        let operationQueue = OperationQueue()
        let registerDeviceOperation = BlockOperation {
            BoardActive.client.registerDevice()
        }
        
        let requestNotificationsOperation = BlockOperation {
            self.requestNotifications()
        }
        
        let monitorLocationOperation = BlockOperation {
            BoardActive.client.monitorLocation()
        }
        
        requestNotificationsOperation.addDependency(registerDeviceOperation)
        monitorLocationOperation.addDependency(requestNotificationsOperation)
        
        OperationQueue.main.addOperation(monitorLocationOperation)
    }
}


extension AppDelegate {
    enum Identifiers: String {
        case viewAction = "VIEW_IDENTIFIER"
        case newsCategory = "NEWS_CATEGORY"
    }
    
   
    
    func registerCustomActions() {
        let viewAction = UNNotificationAction(identifier: Identifiers.viewAction.rawValue, title: "View", options: [.foreground])
        
        let newsCategory = UNNotificationCategory(identifier: Identifiers.newsCategory.rawValue, actions: [viewAction], intentIdentifiers: [])
        UNUserNotificationCenter.current().setNotificationCategories([newsCategory])
    }
    
    
    /**
     Creates an instance of `NotificationModel` from `userInfo`, validates said instance, and calls `createEvent`, capturing the current application state.
     
     - Parameter userInfo: A dictionary that contains information related to the remote notification, potentially including a badge number for the app icon, an alert sound, an alert message to display to the user, a notification identifier, and custom data. The provider originates it as a JSON-defined dictionary that iOS converts to an `NSDictionary` object; the dictionary may contain only property-list objects plus `NSNull`. For more information about the contents of the remote notification dictionary, see Generating a Remote Notification.
     */
    public func handleNotification(application: UIApplication, userInfo: [AnyHashable: Any]) {
        let tempUserInfo = userInfo as! [String: Any]
        let notificationModel = NotificationModel(fromDictionary: tempUserInfo)
        
        badgeNumber += 1
        application.applicationIconBadgeNumber = badgeNumber
        
        os_log("Notification Model :: %s", notificationModel.toDictionary().debugDescription)
        
        if let _ = notificationModel.aps, let gcmmessageId = notificationModel.gcmmessageId, let firebaseNotificationId = notificationModel.notificationId {
            switch application.applicationState {
            case .active:
                os_log("%s", String.ReceivedBackground)
                BoardActive.client.postEvent(name: String.Received, googleMessageId: gcmmessageId, messageId: firebaseNotificationId)
            case .background:
                os_log("%s", String.ReceivedBackground)
                BoardActive.client.postEvent(name: String.Received, googleMessageId: gcmmessageId, messageId: firebaseNotificationId)
            case .inactive:
                os_log("%s", String.TappedAndTransitioning)
                BoardActive.client.postEvent(name: String.Opened, googleMessageId: gcmmessageId, messageId: firebaseNotificationId)
                BoardActive.client.delegate?.appReceivedRemoteNotification(notification: userInfo)
            default:
                break
            }
        }
    }
    
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        UIApplication.shared.applicationIconBadgeNumber = response.notification.request.content.badge as! Int
        
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {
                return
        }
        
        let userInfo = response.notification.request.content.userInfo as! [String: Any]
        let notificationModel = NotificationModel.init(fromDictionary: userInfo)
        // Print message ID.
        if let messageID = userInfo["gcmMessageIDKey"] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    /**
     This function will be called once a token is available, or has been refreshed. Typically it will be called once per app start, but may be called more often, if a token is invalidated or updated. In this method, you should perform operations such as:
     
     * Uploading the FCM token to your application server, so targeted notifications can be sent.
     * Subscribing to any topics.
     */
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Firebase registration token: \(fcmToken)")
        BoardActive.client.userDefaults?.set(fcmToken, forKey: "deviceToken")
        BoardActive.client.userDefaults?.synchronize()
        
        let dataDict:[String: String] = ["token": fcmToken]
        NotificationCenter.default.post(name: Notification.Name("FCMToken Registration"), object: nil, userInfo: dataDict)
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo["gcmMessageIDKey"] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([])
    }

}

extension AppDelegate: UNUserNotificationCenterDelegate {
    /**
     Called when app in foreground or background as opposed to `application(_:didReceiveRemoteNotification:)` which is only called in the foreground.
     (Source: https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623013-application)
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        handleNotification(application: application, userInfo: userInfo)
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        registerCustomActions()
        let deviceTokenString = deviceToken.reduce("", { $0 + String(format: "%02X", $1) })
        os_log("APNs TOKEN :: %s", deviceTokenString)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        os_log("Reason for failing remote notifications: %s", error.localizedDescription)
    }
    
    public func requestNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { granted, error in
            guard error == nil, granted else {
                return
            }
            
            if BoardActive.client.userDefaults?.object(forKey: "dateNotificationPermissionRequested") == nil {
                BoardActive.client.userDefaults?.set(Date().iso8601, forKey: "dateNotificationPermissionRequested")
                BoardActive.client.userDefaults?.synchronize()
            }
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}