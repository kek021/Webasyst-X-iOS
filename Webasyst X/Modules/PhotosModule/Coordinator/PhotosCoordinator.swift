//
//  PhotosCoordinator.swift
//  Webasyst X
//
//  Created by Aleksandr Zhukov on 19.09.2022.
//

import UIKit

//MARK PhotosCoordinator
final class PhotosCoordinator {
    
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
        let viewController = screens.createPhotosViewController(coordinator: self)
        presenter.viewControllers = [viewController]
    }
    
    func openSettingsList() {
        let settingsListCoordinator = SettingsListCoordinator(presenter: self.presenter, screens: self.screens)
        settingsListCoordinator.start()
    }
}
