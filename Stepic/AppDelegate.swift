 //
//  AppDelegate.swift
//  Stepic
//
//  Created by Alexander Karpov on 25.08.15.
//  Copyright (c) 2015 Alex Karpov. All rights reserved.
//

import UIKit
import MediaPlayer
import Fabric
import Crashlytics
import Google 
import IQKeyboardManagerSwift
import SVProgressHUD
 
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        Fabric.with([Crashlytics.self])
        
        SVProgressHUD.setMinimumDismissTimeInterval(0.5)
        
//        setVideoTestRootController()
        setRootController()
        ConnectionHelper.shared.instantiate()
        if !AudioManager.sharedManager.initAudioSession() {
            print("Could not initialize audio session")
        }
        
        // Configure tracker from GoogleService-Info.plist.
        var configureError:NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
        
        // Optional: configure GAI options.
        let gai = GAI.sharedInstance()
        gai.trackUncaughtExceptions = true  // report uncaught exceptions
        gai.logger.logLevel = GAILogLevel.None  // remove before app release
        
        NotificationRegistrator.sharedInstance.registerForRemoteNotifications(application)
        
        IQKeyboardManager.sharedManager().enable = true
        IQKeyboardManager.sharedManager().shouldResignOnTouchOutside = true
        IQKeyboardManager.sharedManager().keyboardDistanceFromTextField = 24
        IQKeyboardManager.sharedManager().enableAutoToolbar = false

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(AppDelegate.updateNotificationRegistrationStatus(_:)), name: NotificationRegistrator.sharedInstance.registrationKey, object: nil)
//        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0]
//        print(documentsPath)
        return true
    }

    func updateNotificationRegistrationStatus(notification: NSNotification) {
        if let info = notification.userInfo as? [String:String] {
            if let error = info["error"] {
                print("Error registering with GCM: \(error)")
            } else if let _ = info["registrationToken"] {
                print("Token registration successful!")
            }
        }
    }
    
    func application(application: UIApplication, handleOpenURL url: NSURL) -> Bool {
        print("opened app via url \(url.absoluteString)")
        let codeOpt = Parser.sharedParser.codeFromURL(url)
        if let code = codeOpt {
            NSNotificationCenter.defaultCenter().postNotificationName("ReceivedAuthorizationCodeNotification", object: self, userInfo: ["code": code])            
        } else {
            print("error while authentificating")
        }
        return true
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        NotificationRegistrator.sharedInstance.getGCMRegistrationToken(deviceToken: deviceToken)
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("error while registering to remote notifications")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("didReceiveRemoteNotification with userInfo: \(userInfo)")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("didReceiveRemoteNotification: fetchCompletionHandler with userInfo: \(userInfo)")
        
        let notification = UILocalNotification()
        notification.fireDate = NSDate(timeIntervalSinceNow: 1)
        notification.alertBody = "YO! NOTIFICATION HERE BRO!"
        notification.timeZone = NSTimeZone.defaultTimeZone()
        notification.soundName = UILocalNotificationDefaultSoundName
        
        UIApplication.sharedApplication().scheduleLocalNotification(notification)
        
        completionHandler(UIBackgroundFetchResult.NoData)
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
//        CoreDataHelper.instance.deleteAllPending()
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

//    func application(application: UIApplication, supportedInterfaceOrientationsForWindow window: UIWindow?) -> UIInterfaceOrientationMask {
//        
//        
//        if let c = window?.rootViewController?.presentedViewController?.classForCoder  {
//            if c != UITabBarController.classForCoder() && c != SignInViewController.classForCoder() && c != UIAlertController.classForCoder() {
//                print("class -> \(c)")
//                return UIInterfaceOrientationMask.Landscape
//            }
//        }
//        return UIInterfaceOrientationMask.Portrait
//    }
    
    private func setRootController() {
        if StepicAPI.shared.isAuthorized {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            
            // instantiate your desired ViewController
            let rootController = storyboard.instantiateViewControllerWithIdentifier("MainTabBarController") 
            
            // Because self.window is an optional you should check it's value first and assign your rootViewController
            if self.window != nil {
                self.window!.rootViewController = rootController
            }
        }
    }
    
    private func setVideoTestRootController() {
        let rootController = ControllerHelper.instantiateViewController(identifier: "PlayerTestViewController", storyboardName: "PlayerTestStoryboard")
        if self.window != nil {
            self.window!.rootViewController = rootController
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NotificationRegistrator.sharedInstance.registrationKey, object: nil)
    }

}

