//
//  WelcomeViewController.swift
//  WebXApp
//
//  Created by Виктор Кобыхно on 1/13/21.
//

import UIKit

protocol WelcomeViewProtocol: class {
    
}

class WelcomeViewController: UIViewController, WelcomeViewProtocol {
    
    //MARK: Data variables
    var viewModel: WelcomeViewModelProtocol!
    
    //MARK: Interface elements variable
    private var logoImage: UIImageView = {
        let image = UIImageView(image: UIImage(named: "TextLogo"))
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private var welcomeImage: UIImageView = {
        let image = UIImageView(image: UIImage(named: "BigLogo"))
        image.contentMode = .scaleAspectFit
        image.translatesAutoresizingMaskIntoConstraints = false
        return image
    }()
    
    private var appNameLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("appName", comment: "")
        label.font = UIFont.boldSystemFont(ofSize: 30)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var descriptionAppLabel: UILabel = {
        let label = UILabel()
        label.text = NSLocalizedString("appDescription", comment: "")
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var authButton: UIButton = {
        let button = UIButton()
        button.setTitle(NSLocalizedString("loginButtonTitle", comment: "").uppercased(), for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = UIColor.systemIndigo
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        button.layer.cornerRadius = 5
        button.addTarget(self, action: #selector(tapLogin), for: .touchDown)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemBackground
        self.setupLayout()
    }
    
    // Hide navigation bar
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    // Show navigation bar
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    //MARK: Setup layout
    private func setupLayout() {
        view.addSubview(logoImage)
        view.addSubview(welcomeImage)
        view.addSubview(appNameLabel)
        view.addSubview(descriptionAppLabel)
        view.addSubview(authButton)
        NSLayoutConstraint.activate([
            //Top screen constraint
            logoImage.widthAnchor.constraint(equalToConstant: view.frame.width / 3),
            logoImage.heightAnchor.constraint(equalToConstant: 50),
            logoImage.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            logoImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeImage.widthAnchor.constraint(equalToConstant: view.frame.width / 1.5),
            welcomeImage.heightAnchor.constraint(equalToConstant: view.frame.width / 1.5),
            welcomeImage.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeImage.topAnchor.constraint(equalTo: logoImage.bottomAnchor, constant: 10),
            appNameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            appNameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            appNameLabel.topAnchor.constraint(equalTo: welcomeImage.bottomAnchor, constant: 20),
            descriptionAppLabel.widthAnchor.constraint(equalToConstant: 340),
            descriptionAppLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            descriptionAppLabel.topAnchor.constraint(equalTo: appNameLabel.bottomAnchor, constant: 10),
            authButton.widthAnchor.constraint(equalToConstant: view.frame.width / 1.5),
            authButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            authButton.topAnchor.constraint(equalTo: descriptionAppLabel.bottomAnchor, constant: 40),
            authButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    //MARK: User event
    @objc func tapLogin() {
        self.viewModel.tappedLoginButton()
    }
    
}
