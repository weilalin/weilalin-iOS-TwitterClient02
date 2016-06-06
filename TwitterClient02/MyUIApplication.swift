//
//  MyUIApplication.swift
//  TwitterClient02
//
//  Created by guest on 2016/05/13.
//  Copyright © 2016年 mycompany. All rights reserved.
//

import UIKit

class MyUIApplication: UIApplication {

    var myOpenURL = NSURL()
    override func openURL(url: NSURL) -> Bool {
        myOpenURL = url
        
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let navigationController = appDelegate.navigationController
        let webViewController = storyboard.instantiateViewControllerWithIdentifier("WebViewController") as! WebViewController
        //
        webViewController.openURL = myOpenURL
        navigationController.pushViewController(webViewController, animated: true)
        return true
    }
}
