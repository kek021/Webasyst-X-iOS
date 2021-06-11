//
//  ConfirmCodeViewModel.swift
//  WebXApp
//
//  Created by Виктор Кобыхно on 10.06.2021.
//

import Foundation
import RxSwift
import Webasyst

protocol ConfirmCodeViewModelProtocol {
    var coordinator: ConfirmCodeCoordinatorProtocol { get }
    var phoneNumber: String { get }
    var enabledTimerSubject: BehaviorSubject<Bool> { get }
    init(_ coordinator: ConfirmCodeCoordinatorProtocol, phoneNumber: String)
    func resendCode()
    func sendCode(with: String)
}

enum ResendCodeStatus {
    case enabled
    case disabled
}

final class ConfirmCodeViewModel: ConfirmCodeViewModelProtocol {
    
    var phoneNumber: String
    
    var coordinator: ConfirmCodeCoordinatorProtocol
    var enabledTimerSubject = BehaviorSubject<Bool>(value: true)
    private var webasyst = WebasystApp()
    
    init(_ coordinator: ConfirmCodeCoordinatorProtocol, phoneNumber: String) {
        self.coordinator = coordinator
        self.phoneNumber = phoneNumber
        self.enabledTimerSubject.onNext(false)
        Timer.scheduledTimer(timeInterval: 90.0, target: self, selector: #selector(self.stopTimer), userInfo: nil, repeats: false)
    }
    
    func sendCode(with: String) {
        webasyst.sendConfirmCode(with) { result in
            if result {
                self.coordinator.successAuth()
            } else {
                self.coordinator.showErrorAlert(with: NSLocalizedString("errorCode", comment: ""))
            }
        }
    }
    
    func resendCode() {
        self.webasyst.getAuthCode(self.phoneNumber, type: .phone) { result in
            switch result {
            case .success:
                self.enabledTimerSubject.onNext(false)
                Timer.scheduledTimer(timeInterval: 90.0, target: self, selector: #selector(self.stopTimer), userInfo: nil, repeats: false)
            case .no_channels:
                self.coordinator.showErrorAlert(with: NSLocalizedString("phoneError", comment: ""))
            case .invalid_client:
                self.coordinator.showErrorAlert(with: NSLocalizedString("clientIdError", comment: ""))
            case .require_code_challenge:
                self.coordinator.showErrorAlert(with: NSLocalizedString("codeChalengeError", comment: ""))
            case .invalid_email:
                self.coordinator.showErrorAlert(with: NSLocalizedString("emailError", comment: ""))
            case .invalid_phone:
                self.coordinator.showErrorAlert(with: NSLocalizedString("phoneError", comment: ""))
            case .request_timeout_limit:
                self.coordinator.showErrorAlert(with: NSLocalizedString("requestTimeoutLimit", comment: ""))
            case .sent_notification_fail:
                self.coordinator.showErrorAlert(with: NSLocalizedString("sentNotificationFail", comment: ""))
            case .server_error:
                self.coordinator.showErrorAlert(with: NSLocalizedString("sentNotificationFail", comment: ""))
            case .undefined(error: let error):
                self.coordinator.showErrorAlert(with: error)
            }
        }
    }
    
    @objc private func stopTimer() {
        enabledTimerSubject.onNext(true)
    }
    
}
