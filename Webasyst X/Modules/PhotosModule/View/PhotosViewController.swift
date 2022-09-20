//
//  PhotosViewController.swift
//  Webasyst X
//
//  Created by Aleksandr Zhukov on 19.09.2022.
//

import UIKit
import RxSwift
import RxCocoa
import Webasyst

final class PhotosViewController: UIViewController {

    //MARK: ViewModel property
    var viewModel: PhotosViewModel?
    var coordinator: PhotosCoordinator?
    
    private var disposeBag = DisposeBag()
    
    //MARK: Interface elements property
    lazy var photosTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(UINib(nibName: "PhotosViewCell", bundle: nil), forCellReuseIdentifier: PhotosViewCell.identifier)
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.tableFooterView = UIView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.allowsSelection = false
        tableView.rowHeight = UIScreen.main.bounds.size.width
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = NSLocalizedString("photosTitle", comment: "")
        self.navigationController?.navigationBar.prefersLargeTitles = true
        view.backgroundColor = .systemBackground
        self.createLeftNavigationButton(action: #selector(self.openSetupList))
        self.bindableViewModel()
    }
    
    // Subscribe for model updates
    private func bindableViewModel() {
        guard let viewModel = self.viewModel else { return }
        viewModel.output.photosList
            .map { photosList -> [Photos] in
                if photosList.isEmpty {
                    self.setupEmptyView(entityName: NSLocalizedString("element", comment: ""))
                    return []
                } else {
                    self.setupLayoutTableView(tables: self.photosTableView)
                    return photosList
                }
            }
            .bind(to: photosTableView.rx.items(cellIdentifier: PhotosViewCell.identifier, cellType: PhotosViewCell.self)) { _, photo, cell in
                cell.configure(photosData: photo)
            }.disposed(by: disposeBag)
        
        viewModel.output.showLoadingHub
            .subscribe(onNext: { [weak self] loading in
                if loading {
                    guard let self = self else { return }
                    self.setupLoadingView()
                }
            }).disposed(by: disposeBag)
        viewModel.output.errorServerRequest
            .subscribe (onNext: { [weak self] errors in
                guard let self = self else { return }
                switch errors {
                case .permisionDenied:
                    self.setupServerError(with: NSLocalizedString("permisionDenied", comment: ""))
                case .notEntity:
                    self.setupEmptyView(entityName: NSLocalizedString("element", comment: ""))
                case .requestFailed(text: let text):
                    self.setupServerError(with: text)
                case .notInstall:
                    guard let selectInstall = UserDefaults.standard.string(forKey: "selectDomainUser") else { return }
                    let webasyst = WebasystApp()
                    if let install = webasyst.getUserInstall(selectInstall) {
                        self.setupInstallView(moduleName: NSLocalizedString("shop", comment: ""), installName: install.name ?? "", viewController: self)
                    }
                case .notConnection:
                    self.setupNotConnectionError()
                }
            }).disposed(by: disposeBag)
        viewModel.output.updateActiveSetting
            .subscribe(onNext: { [weak self] update in
                guard let self = self else { return }
                self.createLeftNavigationButton(action: #selector(self.openSetupList))
            }).disposed(by: disposeBag)
    }
    
    @objc func openSetupList() {
        guard let coordinator = self.coordinator else { return }
        coordinator.openSettingsList()
    }
}

extension PhotosViewController: InstallModuleViewDelegate {
    func installModuleTap() {
        let alertController = UIAlertController(title: "Install module", message: "Tap in install module button", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ok", style: .cancel, handler: nil)
        alertController.addAction(action)
        self.navigationController?.present(alertController, animated: true, completion: nil)
    }
}
