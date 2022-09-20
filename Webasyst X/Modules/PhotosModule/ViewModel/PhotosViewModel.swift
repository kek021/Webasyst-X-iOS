//
//  PhotosViewModel.swift
//  Webasyst X
//
//  Created by Aleksandr Zhukov on 19.09.2022.
//

import Foundation
import RxSwift
import RxCocoa
import Moya
import Webasyst

//MARK: PhotosViewModel
protocol PhotosViewModelType {
    associatedtype Input
    associatedtype Output
    var input: Input { get }
    var output: Output { get }
}

//MARK: PhotosViewModel
final class PhotosViewModel: PhotosViewModelType {

    struct Input {
       //...
    }
    
    let input: Input
    
    struct Output {
        var photosList: BehaviorSubject<[Photos]>
        var showLoadingHub: BehaviorSubject<Bool>
        var errorServerRequest: PublishSubject<ServerError>
        var updateActiveSetting: PublishSubject<Bool>
    }
    
    let output: Output
    
    private var disposeBag = DisposeBag()
    private var moyaProvider: MoyaProvider<NetworkingService>
            
    //MARK: Input Objects
    
    //MARK: Output Objects
    private var photosListSubject = BehaviorSubject<[Photos]>(value: [])
    private var showLoadingHubSubject = BehaviorSubject<Bool>(value: false)
    private var errorServerRequestSubject = PublishSubject<ServerError>()
    private var updateActiveSettingSubject = PublishSubject<Bool>()

    init(moyaProvider: MoyaProvider<NetworkingService>) {
        
        self.moyaProvider = moyaProvider
        
        //Init input property
        self.input = Input(
            //...
        )

        //Init output property
        self.output = Output(
            photosList: photosListSubject.asObserver(),
            showLoadingHub: showLoadingHubSubject.asObserver(),
            errorServerRequest: errorServerRequestSubject.asObserver(),
            updateActiveSetting: updateActiveSettingSubject.asObserver()
        )
        
        self.loadRequestPhotos()
        self.trackingChangeSettings()
    }
    
    private func trackingChangeSettings() {
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(setObserver), name: Notification.Name("ChangedSelectDomain"), object: nil)
    }
    
    @objc private func setObserver() {
        self.updateActiveSettingSubject.onNext(true)
        self.loadRequestPhotos()
    }
    
    private func loadRequestPhotos() {
        self.showLoadingHubSubject.onNext(true)
        if Reachability.isConnectedToNetwork() {
            moyaProvider.rx.request(.requestPhotosList)
                .subscribe { response in
                    guard let statusCode = response.response?.statusCode else {
                        self.showLoadingHubSubject.onNext(false)
                        self.errorServerRequestSubject.onNext(.requestFailed(text: "Failed to get server reply status code"))
                        return
                    }
                    switch statusCode {
                    case 200...299:
                        do {
                            let photosData = try JSONDecoder().decode(PhotosList.self, from: response.data)
                            if let photos = photosData.photos {
                                if !photos.isEmpty {
                                    self.showLoadingHubSubject.onNext(false)
                                    self.photosListSubject.onNext(photos)
                                } else {
                                    self.showLoadingHubSubject.onNext(false)
                                    self.errorServerRequestSubject.onNext(.notEntity)
                                }
                            } else {
                                self.showLoadingHubSubject.onNext(false)
                                self.errorServerRequestSubject.onNext(.notEntity)
                            }
                        } catch let error {
                            self.showLoadingHubSubject.onNext(false)
                            self.errorServerRequestSubject.onNext(.requestFailed(text: error.localizedDescription))
                        }
                    case 401:
                        self.showLoadingHubSubject.onNext(false)
                        do {
                            let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String: String]
                            if let error = json?["error"] {
                                if error == "invalid_client" {
                                    let localizedString = NSLocalizedString("invalidClientError", comment: "")
                                    let webasyst = WebasystApp()
                                    let activeDomain = UserDefaults.standard.string(forKey: "selectDomainUser") ?? ""
                                    let activeInstall = webasyst.getUserInstall(activeDomain)
                                    let replacedString = String(format: localizedString, activeInstall?.url ?? "", String(data: response.data, encoding: String.Encoding.utf8)!)
                                    self.errorServerRequestSubject.onNext(.requestFailed(text: replacedString))
                                } else {
                                    self.errorServerRequestSubject.onNext(.requestFailed(text: json?["error_description"] ?? ""))
                                }
                            } else {
                                self.errorServerRequestSubject.onNext(.permisionDenied)
                            }
                        } catch let error {
                            self.errorServerRequestSubject.onNext(.requestFailed(text: error.localizedDescription))
                        }
                    case 400:
                        self.showLoadingHubSubject.onNext(false)
                        self.errorServerRequestSubject.onNext(.notInstall)
                    case 404:
                        do {
                            let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String: String]
                            if let error = json?["error"] {
                                if error == "disabled" {
                                    let localizedString = NSLocalizedString("disabledErrorText", comment: "")
                                    self.errorServerRequestSubject.onNext(.requestFailed(text: localizedString))
                                } else {
                                    self.errorServerRequestSubject.onNext(.permisionDenied)
                                }
                            }
                        } catch let error {
                            self.errorServerRequestSubject.onNext(.requestFailed(text: error.localizedDescription))
                        }
                    default:
                        self.showLoadingHubSubject.onNext(false)
                        do {
                            let json = try JSONSerialization.jsonObject(with: response.data, options: []) as? [String: String]
                            if let error = json?["error_description"] {
                                self.errorServerRequestSubject.onNext(.requestFailed(text: error))
                            } else {
                                self.errorServerRequestSubject.onNext(.permisionDenied)
                            }
                            
                        } catch let error {
                            self.errorServerRequestSubject.onNext(.requestFailed(text: error.localizedDescription))
                        }
                    }
                } onError: { error in
                    self.showLoadingHubSubject.onNext(false)
                    self.errorServerRequestSubject.onNext(.requestFailed(text: error.localizedDescription))
                }.disposed(by: disposeBag)
        } else {
            self.errorServerRequestSubject.onNext(.notConnection)
        }
    }
    
}
