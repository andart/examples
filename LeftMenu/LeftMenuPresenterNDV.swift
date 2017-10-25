//
//  LeftMenuPresenterNDV.swift
//  v1app
//
//  Created by Andrey Artemenko on 15/05/2017.
//

import Foundation

protocol LeftMenuViewProtocol : class {
    func updateProfile(name: String?, numberPhone: String)
    func updateSourceData(_ isDeveloperState: Bool)
}

class LeftMenuPresenter {
    unowned fileprivate var view: LeftMenuViewProtocol
    fileprivate let router = LeftMenuRouter()
    fileprivate let phoneNumber = Session.shared.phoneNumber
    
    init(view: LeftMenuViewProtocol) {
        self.view = view
    }
    
    func viewDidLoad() {
        update()
        
        self.view.updateSourceData(Session.shared.isTestingMode)
    }
    
    func update() {
        view.updateProfile(name: String(format: "%@ %@",  ProfileManager.sharedInstance.profile?.firstName ?? "", ProfileManager.sharedInstance.profile?.lastName ?? ""), numberPhone: "+" + RMPhoneFormat.instance().format(phoneNumber ?? ""))
    }
    
    func showDashboard() {
        router.showDashboard()
    }
    
    func showCardList() {
        router.showCardList()
    }
    
    func showHistory() {
        router.showHistory()
    }
    
    func showHelp() {
        router.showHelp()
    }
    
    func showSettings() {
        router.showSettings()
    }
    
    func showDeveloper() {
        router.showDeveloperMenu()
    }
    
    @objc func showProfile() {
        LeftMenuNDV.shared.hide()
        router.showProfile()
    }
    
    private func loadProfile() {
        ProfileManager.sharedInstance.loadProfile { [weak self] (profile) -> () in
            if let strongSelf = self, let profile = profile, let phone = strongSelf.phoneNumber {
                strongSelf.view.updateProfile(name: String(format: "%@ %@", profile.firstName, profile.lastName), numberPhone: "+" + RMPhoneFormat.instance().format(phone))
            }
        }
    }
    
    func changeDeveloperState() {
        Session.shared.isTestingMode = !Session.shared.isTestingMode
        self.view.updateSourceData(Session.shared.isTestingMode)
    }
    
    func isDeveloperState() -> Bool {
        return Session.shared.isLoggedIn
    }
}
