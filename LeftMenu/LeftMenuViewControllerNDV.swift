//
//  LeftMenuViewControllerNDV.swift
//  v1app
//
//  Created by Andrey Artemenko on 15/05/2017.
//

import UIKit

let menuW = 270.0 as CGFloat

class LeftMenuViewControllerNDV : UIViewController {
    
    enum LeftMenuItems : Int {
        case dashboard
        case cards
        case history
        case empty
        case dev
        case help
        case settings
        //case logout
    }
    
    fileprivate var presenter: LeftMenuPresenter!
    var menuContent: [LeftMenuItems] = [.dashboard, .cards, .history, .empty, .help, .settings]
    
    let headerView = LeftMenuHeaderView.fromNib() as! LeftMenuHeaderView
    let emptyCellIndentifier = "EmptyCell"
    
    lazy var overlayView: UIView = {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: screenSize.width, height: screenSize.height))
        view.backgroundColor = UIColor.black.withAlphaComponent(0.42)
        view.alpha = 0
        
        return view
    }()
    
    lazy var menuView: UIView = {
        let view = UIView(frame: CGRect(x: -menuW, y: 0, width: menuW, height: screenSize.height))
        view.backgroundColor = UIColor.color0
        view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        return view
    }()
    
    lazy var tableView: UITableView = {
        [unowned self] in
        let tableView = UITableView(frame: self.menuView.bounds)
        tableView.bounces = false
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.separatorStyle = .none
        tableView.tableHeaderView = self.headerView
        tableView.dataSource = self
        tableView.delegate = self
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        
        tableView.register(LeftMenuItemTableViewCell.self)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: self.emptyCellIndentifier)
        
        return tableView
    }()

    override func loadView() {
        super.loadView()
        
        presenter = LeftMenuPresenter(view: self)
        
        view.addSubview(overlayView)
        view.addSubview(menuView)
        
        menuView.addSubview(tableView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(self.changeDeveloperState(_:)))
        recognizer.numberOfTouchesRequired = 2
        recognizer.minimumPressDuration = 3
        
        presenter.viewDidLoad()
        
        self.headerView.addGestureRecognizer(recognizer)
        
        self.headerView.addGestureRecognizer(UITapGestureRecognizer(target: presenter, action: #selector(LeftMenuPresenter.showProfile)))
    }
    
    func show() {
        presenter.update()
    }
    
    func hide() {
        
    }
    
}

extension LeftMenuViewControllerNDV {
    func changeDeveloperState(_ recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.began {
            presenter.changeDeveloperState()
        }
    }
}

extension LeftMenuViewControllerNDV: LeftMenuViewProtocol {
    
    func updateProfile(name: String?, numberPhone: String) {
        headerView.phoneLabel.text = numberPhone
        
        if let name = name {
            headerView.nameLabel.text = name
        }
        
        ContactsWrapper.sharedInstance.searchForContactUsingPhoneNumber(phoneNumbers: [numberPhone.digits], success: { [weak self] (contacts) in
            if let contact = contacts.first {
                let (_, _, image) = contact
                self?.headerView.avatarImageView.image = image ?? UIImage(named: "menuAva")
            }
        }) {
            
        }
    }
    
    func updateSourceData(_ isDeveloperState : Bool) {
        if isDeveloperState {
            menuContent = [.dashboard, .cards, .history, .empty, .dev, .help, .settings]
        } else {
            menuContent = [.dashboard, .cards, .history, .empty, .help, .settings]
        }
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
}

extension LeftMenuViewControllerNDV : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuContent.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if menuContent[indexPath.row] == .empty {
            return tableView.dequeueReusableCell(withIdentifier: emptyCellIndentifier, for: indexPath)
        }
        return tableView.dequeueReusableCell(LeftMenuItemTableViewCell.self, forIndexPath: indexPath)
    }
}

extension LeftMenuViewControllerNDV : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let itemHeight = 60 as CGFloat
        if menuContent[indexPath.row] == .empty {
            let h = max(tableView.frame.size.height - headerView.frame.size.height - itemHeight * CGFloat(menuContent.count - 1), 0)
            return h
        }
        
        return itemHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        switch menuContent[indexPath.row] {
        case .dashboard:
            (cell as! LeftMenuItemTableViewCell).iconView.image = UIImage(named: "dashboard")
            (cell as! LeftMenuItemTableViewCell).titleLabel.text = localized("menuItemDashboard")
        case .cards:
            (cell as! LeftMenuItemTableViewCell).iconView.image = UIImage(named: "cards")
            (cell as! LeftMenuItemTableViewCell).titleLabel.text = localized("menuItemCards")
        case .history:
            (cell as! LeftMenuItemTableViewCell).iconView.image = UIImage(named: "history")
            (cell as! LeftMenuItemTableViewCell).titleLabel.text = localized("menuItemHistory")
        case .help: 
            (cell as! LeftMenuItemTableViewCell).iconView.image = UIImage(named: "help")
            (cell as! LeftMenuItemTableViewCell).titleLabel.text = localized("menuItemHelp")
        case .settings:
            (cell as! LeftMenuItemTableViewCell).iconView.image = UIImage(named: "settings")
            (cell as! LeftMenuItemTableViewCell).titleLabel.text = localized("menuItemSettings")
        case .dev:
            (cell as! LeftMenuItemTableViewCell).iconView.image = UIImage(named: "settings")
            (cell as! LeftMenuItemTableViewCell).titleLabel.text = "Developer"
        default:
            break
        }
    }
    
    func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        if menuContent[indexPath.row] == .empty {
            return false
        }
        
        return true
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        LeftMenuNDV.shared.hide()
        tableView.deselectRow(at: indexPath, animated: true)
        switch menuContent[indexPath.row] {
        case .dashboard:
            presenter.showDashboard()
        case .cards:
            presenter.showCardList()
        case .history:
            presenter.showHistory()
        case .help:
            presenter.showHelp()
        case .settings:
            presenter.showSettings()
        case .dev:
            presenter.showDeveloper()
//        case .logout:
//            logout()
        default:
            break
        }
    }
}
