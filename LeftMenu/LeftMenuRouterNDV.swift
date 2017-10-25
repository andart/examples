//
//  LeftMenuRouterNDV.swift
//  v1app
//
//  Created by Andrey Artemenko on 15/05/2017.
//

import Foundation

class LeftMenuRouter {
    
    func showWelcome() {
        let vc = WelcomeViewControllerNDV.fromNib()
        
        AppDelegate.makeRootViewController(vc, animated: true)
    }
    
    func showDashboard() {
        
    }
    
    func showCardList() {
        let vc = CardListViewControllerNDV.fromNib()
        
        AppDelegate.pushViewController(vc)
    }
    
    func showHistory() {
        let vc = HistoryViewControllerNDV.fromNib()
        
        AppDelegate.pushViewController(vc)
    }
    
    func showHelp() {
        let vc = HelpViewControllerNDV.fromNib()
        
        AppDelegate.pushViewController(vc)
    }
    
    func showSettings() {
        let vc = SettingViewControllerNDV.fromNib()
        
        AppDelegate.pushViewController(vc)
    }
    
    func showProfile() {
        ProfileRouter.show()
    }
    
    func showDeveloperMenu() {
        let vc = DeveloperViewControllerNDV.fromNib()
        AppDelegate.pushViewController(vc)
    }
}
