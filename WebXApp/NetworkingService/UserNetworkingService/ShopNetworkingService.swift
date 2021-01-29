//
//  ShopNetworkingService.swift
//  WebXApp
//
//  Created by Виктор Кобыхно on 1/27/21.
//

import Foundation
import Alamofire
import RxSwift

protocol ShopNetwrokingServiceProtocol: class {
    func getOrdersList() -> Observable<Result<[Orders]>>
}

class ShopNetworkingService: UserNetworkingManager, ShopNetwrokingServiceProtocol {
    
    private let profileInstallListService = ProfileInstallListService()
    
    func getOrdersList() -> Observable<Result<[Orders]>> {
        return Observable.create { (observer) -> Disposable in
            
            let selectDomain = UserDefaults.standard.string(forKey: "selectDomainUser") ?? ""
            
            let parameters: [String: String] = [
                "limit": "10",
                "access_token": self.profileInstallListService.getTokenActiveInstall(selectDomain)
            ]
            
            
            let url = self.profileInstallListService.getUrlActiveInstall(selectDomain)
            
            let request = AF.request("\(url)/api.php/shop.order.search", method: .get, parameters: parameters, encoding: URLEncoding(destination: .queryString)).response { response in
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
                            let orders = try! JSONDecoder().decode(OrderList.self, from: data)
                            if orders.orders.isEmpty {
                                observer.onNext(Result.Failure(.notEntity))
                            } else {
                                observer.onNext(Result.Success(orders.orders))
                            }
                            observer.onCompleted()
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
