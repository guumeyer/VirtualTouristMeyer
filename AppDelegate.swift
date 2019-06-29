//
//  AppDelegate.swift
//  VirtualTouristMeyer
//
//  Created by Meyer, Gustavo on 6/18/19.
//  Copyright © 2019 Gustavo Meyer. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let dataController = DataController(modelName: "VirtualTourist")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        dataController.load()

        let window = UIWindow(frame: UIScreen.main.bounds)
        let travelLocationMapViewController = TravelLocationsMapViewController(
            dataController,
            FlickerPhotoService(client: URLSessionHTTPClient()))
        let navigationController = UINavigationController(rootViewController: travelLocationMapViewController)
        window.rootViewController = navigationController
        self.window = window
        window.makeKeyAndVisible()
        return true
    }
    func applicationDidEnterBackground(_ application: UIApplication) {
        saveViewContext()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveViewContext()
    }

    func saveViewContext() {
        try? dataController.viewContext.save()
    }

}

