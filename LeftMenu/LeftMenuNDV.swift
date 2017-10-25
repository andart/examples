//
//  LeftMenuNDV.swift
//  v1app
//
//  Created by Andrey Artemenko on 15/05/2017.
//

import Foundation

private var _shared: LeftMenuNDV!

class LeftMenuNDV: UIWindow {
    
    class var shared: LeftMenuNDV {
        if _shared == nil {
            _shared = LeftMenuNDV()
        }
        return _shared
    }
    
    private let mainViewController = LeftMenuViewControllerNDV()
    
    private init() {
        super.init(frame: UIScreen.main.bounds)
        
        buildView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func destroy() {
        _shared = nil
    }
    
    func buildView() {
        windowLevel = UIWindowLevelStatusBar + 1
        backgroundColor = UIColor.clear
        
        rootViewController = mainViewController
        mainViewController.view.isUserInteractionEnabled = true
        mainViewController.view.backgroundColor = UIColor.clear
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(LeftMenuNDV.handleLeftPanGesture(_:)))
        mainViewController.view.addGestureRecognizer(panGesture)
        
        mainViewController.overlayView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(LeftMenuNDV.hide)))
    }
    
    func show() {
        mainViewController.show()
        UIView.animate(withDuration: 0.3) {
            self.isHidden = false
            self.mainViewController.menuView.frame.origin.x = 0
            self.mainViewController.overlayView.alpha = 1
            
            UIApplication.shared.keyWindow?.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        }
    }
    
    func hide() {
        UIView.animate(withDuration: 0.3, animations: {
            self.mainViewController.menuView.frame.origin.x = -menuW
            self.mainViewController.overlayView.alpha = 0
            
            UIApplication.shared.keyWindow?.transform = CGAffineTransform.identity
        }, completion: { (finish) in
            if finish {
                self.mainViewController.hide()
                self.isHidden = true
            }
        })
    }
    
    var startXPosition: CGFloat = 0
    
    func handleLeftPanGesture(_ panGesture: UIPanGestureRecognizer) {
        let location = panGesture.location(in: rootViewController?.view)
        
        switch panGesture.state {
        case UIGestureRecognizerState.began:
            startXPosition = location.x
        case UIGestureRecognizerState.changed:
            let x = location.x - startXPosition
            if x > -menuW && x < 0 {
                mainViewController.menuView.frame.origin.x = x
            }
            
        case UIGestureRecognizerState.ended:
            if location.x - startXPosition > -20 {
                mainViewController.menuView.frame.origin.x = 0
            } else {
                hide()
            }
            
        default:
            break
        }
        
    }
    
}
