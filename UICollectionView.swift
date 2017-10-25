//
//  UICollection.swift
//  TopSpin
//
//  Created by Andrey Artemenko on 23/08/2017.
//

import Foundation

extension UICollectionView {
    
    private struct AssociatedKeys {
        static var sectionChangesKey = "sectionChanges"
        static var objectChangesKey = "objectChanges"
    }
    
    var sectionChanges: [NSNumber : NSMutableIndexSet]? {
        get {
            var _sectionChanges = objc_getAssociatedObject(self, &AssociatedKeys.sectionChangesKey) as? [NSNumber : NSMutableIndexSet]
            if _sectionChanges == nil {
                _sectionChanges = [NSNumber : NSMutableIndexSet]()
                objc_setAssociatedObject(self, &AssociatedKeys.sectionChangesKey, _sectionChanges, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return _sectionChanges
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.sectionChangesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var objectChanges: [NSNumber : NSMutableArray]? {
        get {
            var _objectChanges = objc_getAssociatedObject(self, &AssociatedKeys.objectChangesKey) as? [NSNumber : NSMutableArray]
            if _objectChanges == nil {
                _objectChanges = [NSNumber : NSMutableArray]()
                objc_setAssociatedObject(self, &AssociatedKeys.objectChangesKey, _objectChanges, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
            return _objectChanges
        }
        
        set {
            objc_setAssociatedObject(self, &AssociatedKeys.objectChangesKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func register<T: UICollectionViewCell>(_ type: T.Type) {
        if Bundle.main.path(forResource: String(describing: type), ofType: "nib") != nil {
            let nib = UINib(nibName: String(describing: type), bundle: nil)
            register(nib, forCellWithReuseIdentifier: String(describing: type))
        } else {
            register(type, forCellWithReuseIdentifier: String(describing: type))
        }
    }
    
    func register<T: UICollectionReusableView>(_ type: T.Type, forSupplementaryViewOfKind kind: String) {
        if Bundle.main.path(forResource: String(describing: type), ofType: "nib") != nil {
            let nib = UINib(nibName: String(describing: type), bundle: nil)
            register(nib, forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: type))
        } else {
            register(type, forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: type))
        }
    }
    
    func dequeueReusableCell<T: UICollectionViewCell>(_ type: T.Type, forIndexPath indexPath: IndexPath) -> T  {
        guard let cell = dequeueReusableCell(withReuseIdentifier: String(describing: type), for: indexPath) as? T else {
            fatalError("Could not dequeue cell with identifier: \(String(describing: type))")
        }
        
        return cell
    }
    
    func dequeueReusableSupplementaryView<T: UICollectionReusableView>(_ type: T.Type, ofKind kind: String, for indexPath: IndexPath) -> T  {
        guard let view = dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: type), for: indexPath) as? T else {
            fatalError("Could not dequeue view with identifier: \(String(describing: type))")
        }
        
        return view
    }
    
    func addChangeForSection(at index: Int, type: NSFetchedResultsChangeType) {
        if type == .insert || type == .delete {
            
            if let changeSet = sectionChanges?[NSNumber(value: type.rawValue)] {
                changeSet.add(index)
            } else {
                sectionChanges?[NSNumber(value: type.rawValue)] = NSMutableIndexSet(index: index)
            }
        }
    }
    
    func addChangeForObject(at indexPath: IndexPath?, type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        var changeSet = objectChanges?[NSNumber(value: type.rawValue)]
        if changeSet == nil {
            changeSet = NSMutableArray()
            objectChanges?[NSNumber(value: type.rawValue)] = changeSet
        }
    
        switch(type) {
        case .insert:
            changeSet?.add(newIndexPath!)
        case .delete:
            changeSet?.add(indexPath!)
        case .update:
            changeSet?.add(indexPath!)
        case .move:
            changeSet?.add([indexPath!, newIndexPath!])
        }
    }
    
    func commitChanges() {
        if window == nil {
            clearChanges()
            reloadData()
        } else {
            if let moves = objectChanges?[NSNumber(value: NSFetchedResultsChangeType.move.rawValue)], moves.count > 0 {
                let updatedMoves = NSMutableArray()
                
                if let insertSections = sectionChanges?[NSNumber(value: NSFetchedResultsChangeType.insert.rawValue)],
                    let deleteSections = sectionChanges?[NSNumber(value: NSFetchedResultsChangeType.delete.rawValue)] {
                    for move in moves as! [[IndexPath]] {
                        let fromIP = move[0]
                        let toIP = move[1]
                        
                        if deleteSections.contains(fromIP.section) {
                            if !insertSections.contains(toIP.section) {
                                var changeSet = objectChanges?[NSNumber(value: NSFetchedResultsChangeType.insert.rawValue)]
                                if changeSet == nil {
                                    changeSet = [toIP]
                                    objectChanges?[NSNumber(value: NSFetchedResultsChangeType.insert.rawValue)] = changeSet
                                } else {
                                    changeSet?.add(toIP)
                                }
                            }
                        } else if insertSections.contains(toIP.section) {
                            var changeSet = objectChanges?[NSNumber(value: NSFetchedResultsChangeType.delete.rawValue)]
                            if changeSet == nil {
                                changeSet = [fromIP]
                                objectChanges?[NSNumber(value: NSFetchedResultsChangeType.delete.rawValue)] = changeSet
                            } else {
                                changeSet?.add(fromIP)
                            }
                        } else {
                            updatedMoves.add(move)
                        }
                    }
                    
                    
                    if updatedMoves.count > 0 {
                        objectChanges?[NSNumber(value: NSFetchedResultsChangeType.move.rawValue)] = updatedMoves
                    } else {
                        objectChanges?.removeValue(forKey: NSNumber(value: NSFetchedResultsChangeType.move.rawValue))
                    }
                }
            }
            
            if let deletes = objectChanges?[NSNumber(value: NSFetchedResultsChangeType.delete.rawValue)], deletes.count > 0, let deletedSections = sectionChanges?[NSNumber(value: NSFetchedResultsChangeType.delete.rawValue)] {
                deletes.filter(using: NSPredicate(block: { (indexPath, bindings) -> Bool in
                    return !deletedSections.contains((indexPath as! IndexPath).section)
                }))
            }
            
            if let inserts = objectChanges?[NSNumber(value: NSFetchedResultsChangeType.insert.rawValue)], inserts.count > 0, let insertedSections = sectionChanges?[NSNumber(value: NSFetchedResultsChangeType.insert.rawValue)] {
                inserts.filter(using: NSPredicate(block: { (indexPath, bindings) -> Bool in
                    return !insertedSections.contains((indexPath as! IndexPath).section)
                }))
            }
            
            performBatchUpdates({ 
                
                if let deletedSections = self.sectionChanges?[NSNumber(value: NSFetchedResultsChangeType.delete.rawValue)], deletedSections.count > 0 {
                    self.deleteSections(deletedSections as IndexSet)
                }
                
                if let insertedSections = self.sectionChanges?[NSNumber(value: NSFetchedResultsChangeType.insert.rawValue)], insertedSections.count > 0 {
                    self.insertSections(insertedSections as IndexSet)
                }
                
                if let deletedItems = self.objectChanges?[NSNumber(value: NSFetchedResultsChangeType.delete.rawValue)], deletedItems.count > 0 {
                    self.deleteItems(at: deletedItems as! [IndexPath])
                }
                
                if let insertedItems = self.objectChanges?[NSNumber(value: NSFetchedResultsChangeType.insert.rawValue)], insertedItems.count > 0 {
                    self.insertItems(at: insertedItems as! [IndexPath])
                }
                
                if let reloadItems = self.objectChanges?[NSNumber(value: NSFetchedResultsChangeType.update.rawValue)], reloadItems.count > 0 {
                    self.reloadItems(at: reloadItems as! [IndexPath])
                }
                
                if let moveItems = self.objectChanges?[NSNumber(value: NSFetchedResultsChangeType.move.rawValue)] as? [[IndexPath]] {
                    for paths in moveItems {
                        self.deleteItems(at: [paths[0]])
                        self.insertItems(at: [paths[1]])
                    }
                }
            }, completion: nil)
            
            objectChanges = nil
            sectionChanges = nil
        }
    }
    
    func clearChanges() {
        objectChanges = nil
        sectionChanges = nil
    }
    
}
