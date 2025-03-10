//
//  NewBlog module - NewBlogCoordinator.swift
//  Webasyst-X-iOS
//
//  Created by viktkobst on 26/07/2021.
//  Copyright © 2021 1312 Inc.. All rights reserved.
//

import UIKit

//MARK NewBlogCoordinator
final class BlogCoordinator {
    
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
        let viewController = screens.createNewBlogViewController(coordinator: self)
        presenter.viewControllers = [viewController]
    }
    
    func openSettingsList() {
        let settingsCoordinator = SettingsListCoordinator(presenter: self.presenter, screens: self.screens)
        settingsCoordinator.start()
    }
    
    func openBlogEntryScreen(post: PostList) {
        let blogDetailCoordinator = BlogDetailCoordinator(presenter: self.presenter, screens: self.screens)
        blogDetailCoordinator.start(post: post)
    }
    
}
