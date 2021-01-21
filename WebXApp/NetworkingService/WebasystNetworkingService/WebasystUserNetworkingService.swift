//
//  UserNetworkingService.swift
//  WebXApp
//
//  Created by Виктор Кобыхно on 1/18/21.
//

import Foundation
import Alamofire
import RxSwift

protocol WebasystUserNetworkingServiceProtocol {
    func getUserData(completion: @escaping (Bool) -> ())
    func getInstallList() 
    func refreshAccessToken()
    func getAccessTokenApi( clientId: [String]) -> Observable<[String: Any]>
}

final class WebasystUserNetworkingService: WebasystNetworkingManager, WebasystUserNetworkingServiceProtocol {
    
    private var timer: DispatchSourceTimer?
    private let bundleId: String = Bundle.main.bundleIdentifier ?? ""
    private let profileInstallService = ProfileInstallListService()
    
    //MARK: Get user data
    public func getUserData(completion: @escaping (Bool) -> ()) {
        
        let accessToken = KeychainManager.load(key: "accessToken")
        let accessTokenString = String(decoding: accessToken ?? Data("".utf8), as: UTF8.self)
        
        let headers: HTTPHeaders = [
            "Authorization": accessTokenString
        ]
        
        AF.request(buildWebasystUrl("/id/api/v1/profile/", parameters: [:]), method: .get, headers: headers).response { (response) in
            switch response.result {
            case .success:
                guard let statusCode = response.response?.statusCode else { return }
                switch statusCode {
                case 200...299:
                    let userData = try! JSONDecoder().decode(UserData.self, from: response.data!)
                    UserNetworkingManager().downloadImage(userData.userpic_original_crop) { data in
                        ProfileDataService().saveProfileData(userData, avatar: data)
                    }
                    completion(true)
                default:
                    completion(false)
                }
            case .failure:
                completion(false)
            }
        }
    }
    
    //MARK: Get installation's list user
    public func getInstallList() {
        
        let accessToken = KeychainManager.load(key: "accessToken")
        let accessTokenString = String(decoding: accessToken ?? Data("".utf8), as: UTF8.self)
        
        let headers: HTTPHeaders = [
            "Authorization": accessTokenString
        ]
        
         AF.request(self.buildWebasystUrl("/id/api/v1/installations/", parameters: [:]), method: .get, headers: headers).response { (response) in
            switch response.result {
            case .success:
                guard let statusCode = response.response?.statusCode else { return }
                switch statusCode {
                case 200...299:
                    if let data = response.data {
                        let installList = try! JSONDecoder().decode([InstallList].self, from: data)
                        UserDefaults.standard.setValue(installList[0].domain, forKey: "selectDomainUser")
                        var clientId: [String] = []
                        for install in installList {
                            clientId.append(install.id)
                        }
                        let _ = self.getAccessTokenApi(clientId: clientId).bind { (accessToken) in
                            self.getAccessTokenInstall(installList, accessCodes: accessToken)
                        }
                    }
                default:
                    print("UserNetworkingService server answer code not 200")
                }
            case .failure:
                print("UserNetworkingService failure")
            }
        }
        
    }
    
    func refreshAccessToken() {
        
        let refreshToken = KeychainManager.load(key: "refreshToken")
        let refreshTokenString = String(decoding: refreshToken ?? Data("".utf8), as: UTF8.self)
        
        let paramsRequest: [String: String] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshTokenString,
            "client_id": clientId
        ]
        
        AF.upload(multipartFormData: { (multipartFormData) in
            for (key, value) in paramsRequest {
                multipartFormData.append("\(value)".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: key)
            }
        }, to: buildWebasystUrl("/id/oauth2/auth/token", parameters: [:]), method: .post).response { (response) in
            switch response.result {
            case .success:
                guard let statusCode = response.response?.statusCode else { return }
                switch statusCode {
                case 200...299:
                    if let data = response.data {
                        let authData = try! JSONDecoder().decode(UserToken.self, from: data)
                        let _ = KeychainManager.save(key: "accessToken", data: Data("Bearer \(authData.access_token)".utf8))
                        let _ = KeychainManager.save(key: "refreshToken", data: Data(authData.refresh_token.utf8))
                        self.startRefreshTokenTimer(timeInterval: authData.expires_in)
                        }
                default:
                    print("Token refresh error answer")
                }
            case .failure:
                print("Refresh token failure request")
            }
        }
    }
    
    func getAccessTokenApi(clientId: [String]) -> Observable<[String: Any]> {
        return Observable.create { (observer) -> Disposable in
            
            let paramReqestApi: Parameters = [
                "client_id": clientId
            ]
            
            let accessToken = KeychainManager.load(key: "accessToken")
            let accessTokenString = String(decoding: accessToken ?? Data("".utf8), as: UTF8.self)
            
            let headerRequest: HTTPHeaders = [
                "Authorization": accessTokenString
            ]
            
            let apiRequest = AF.request(self.buildWebasystUrl("/id/api/v1/auth/client/", parameters: [:]), method: .post, parameters: paramReqestApi, headers: headerRequest).response { (response) in
                switch response.result {
                case .success:
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                        case 200...299:
                            if let data = response.data {
                                let accessTokens = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                                observer.onNext(accessTokens)
                                observer.onCompleted()
                            }
                        default:
                            observer.onError(NSError(domain: "getAccessTokenApi status code request \(statusCode)", code: -1, userInfo: nil))
                        }
                    } else {
                        observer.onError(NSError(domain: "getAccessTokenApi status code error", code: -1, userInfo: nil))
                    }
                case .failure:
                    observer.onError(NSError(domain: "get center Api tokens list error request", code: -1, userInfo: nil))
                }
            }
            
            apiRequest.resume()
            
            return Disposables.create {
                apiRequest.cancel()
            }
            
        }
    }
    
    func getAccessTokenInstall(_ installList: [InstallList], accessCodes: [String: Any]) {
        for install in installList {
            let code = accessCodes.filter { $0.key == install.id }.first?.value ?? ""
            AF.upload(multipartFormData: { (multipartFormData) in
                multipartFormData.append("\(String(describing: code))".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "code")
                multipartFormData.append("blog,site,shop".data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "scope")
                multipartFormData.append(self.bundleId.data(using: String.Encoding.utf8, allowLossyConversion: false)!, withName: "client_id")
            }, to: "\(install.url)/api.php/token-headless", method: .post).response {response in
                switch response.result {
                case .success:
                    if let statusCode = response.response?.statusCode {
                        switch statusCode {
                        case 200...299:
                            if let data = response.data {
                                let accessCode = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: Any]
                                self.profileInstallService.saveInstall(install, accessToken: "\(accessCode.first?.value ?? "")")
                            }
                            
                        default:
                            print("getAccessTokenInstall status code \(statusCode)")
                        }
                    }
                case .failure:
                    print("error getAccessTokenInstall request")
                }
            }
        }
    }
    
    private func startRefreshTokenTimer(timeInterval: Int) {
        let queue = DispatchQueue(label: "com.webasyst.WebXApp.timerRefreshAccessToken")
        timer = DispatchSource.makeTimerSource(queue: queue)
        timer!.schedule(deadline: .now(), repeating: .seconds(timeInterval))
        timer!.setEventHandler { [weak self] in
            self?.refreshAccessToken()
        }
        timer!.resume()
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }
    
}
