//
//  Welcome module - WelcomeCoordinator.swift
//  Teamwork
//
//  Created by viktkobst on 19/07/2021.
//  Copyright © 2021 1312 Inc.. All rights reserved.
//

import UIKit
import Webasyst

//MARK WelcomeCoordinator
final class WelcomeCoordinator {
    
    var presenter: UINavigationController
    var screens: ScreensBuilder
    
    init(presenter: UINavigationController, screens: ScreensBuilder) {
        self.presenter = presenter
        self.screens = screens
    }
    
    func start() {
        self.initialViewController()
    }
    
    //MARK: Initial ViewController
    private func initialViewController() {
        let viewController = screens.createWelcomeViewComtroller(coordinator: self)
        presenter.viewControllers = [viewController]
    }
    
    func openPhoneLogin() {
        let coordinator = PhoneAuthCoordinator(presenter: self.presenter, screens: screens)
        coordinator.start()
    }
    
    func webasystIDLogin() {
        let webasyst = WebasystApp()
        webasyst.oAuthLogin(navigationController: self.presenter) { serverAnswer in
            switch serverAnswer {
            case .success:
                DispatchQueue.main.async {
                    let scene = UIApplication.shared.connectedScenes.first
                    if let sceneDelegate = scene?.delegate as? SceneDelegate {
                        let appCoordinator = AppCoordinator(sceneDelegate: sceneDelegate)
                        appCoordinator.authUser()
                    }
                }
            case .error(error: let error):
                print(error)
            }
        }
    }
    
}
