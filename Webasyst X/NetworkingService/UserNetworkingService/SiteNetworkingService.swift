//
//  SiteNetworkingService.swift
//  WebXApp
//
//  Created by Виктор Кобыхно on 1/27/21.
//

import Foundation
import Alamofire
import RxSwift
import RxCocoa
import Webasyst

protocol SiteNetworkingServiceProtocol: Any {
    func getSiteList() -> Observable<Result<[SiteList]>>
}

class SiteNetwrokingService: UserNetworkingManager, SiteNetworkingServiceProtocol {
    
   private let webasyst = WebasystApp()
    
    func getSiteList() -> Observable<Result<[SiteList]>> {
        return Observable.create { (observer) -> Disposable in
            
            let selectDomain = UserDefaults.standard.string(forKey: "selectDomainUser") ?? ""
            
            guard let changeInstall = self.webasyst.getUserInstall(selectDomain) else {
                observer.onCompleted()
                return Disposables.create { }
            }
            
            let parameters: [String: String] = [
                "access_token": "\(changeInstall.accessToken ?? "")"
            ]
            
            
            let url = changeInstall.url
            
            let request = AF.request("\(url)/api.php/site.domain.getList", method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString)).response { response in
                switch response.result {
                case .success(let data):
                    guard let statusCode = response.response?.statusCode else {
                        observer.onNext(Result.Failure(.requestFailed(text: NSLocalizedString("getStatusCodeError", comment: ""))))
                        observer.onCompleted()
                        return
                    }
                    switch statusCode {
                    case 200...299:
                        if let data = data {
                            do {
//                                let siteList = try JSONDecoder().decode(SiteList.self, from: data)
//                                if siteList.orders.isEmpty {
//                                    observer.onNext(Result.Failure(.notEntity))
//                                } else {
//                                    observer.onNext(Result.Success(siteList.orders))
//                                }
                                observer.onCompleted()
                            } catch let error {
                                print(error)
                                observer.onCompleted()
                            }
                        }
                    case 401:
                        observer.onNext(Result.Failure(.permisionDenied))
                        observer.onCompleted()
                    case 400:
                        observer.onNext(Result.Failure(.notInstall))
                        observer.onCompleted()
                    default:
                        observer.onNext(Result.Failure(.permisionDenied))
                    }
                case .failure:
                    observer.onNext(Result.Failure(.requestFailed(text: NSLocalizedString("getStatusCodeError", comment: ""))))
                }
            }
            
            request.resume()
            
            return Disposables.create {
                request.cancel()
            }
        }
    }
    
}
