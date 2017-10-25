//
//  RoundBackgroundCollectionViewFlowLayout.swift
//  TopSpin
//
//  Created by Andrey Artemenko on 26/09/2017.
//

import Foundation

class RoundBackgroundCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    fileprivate let bgKey = "BG"
    
    override func prepare() {
        super.prepare()
        
        register(BGReusableView.self, forDecorationViewOfKind: bgKey)
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let attributes = super.layoutAttributesForElements(in: rect) else {
            return nil
        }
        
        var mutableAttributes = attributes
        
        mutableAttributes.append(layoutAttributesForDecorationView(ofKind: bgKey, at: IndexPath(item: 0, section: 0))!)
        
        return mutableAttributes
    }
    
    override func layoutAttributesForDecorationView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let collectionView = collectionView else {
            return nil
        }
        
        let attrs = UICollectionViewLayoutAttributes(forDecorationViewOfKind: elementKind, with: indexPath)
        if elementKind == bgKey {
            attrs.frame = CGRect(x: 0, y: 0, width: collectionView.collectionViewLayout.collectionViewContentSize.width, height: collectionView.collectionViewLayout.collectionViewContentSize.height)
            attrs.zIndex = -1
        }
        
        return attrs
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }
}

class BGReusableView: UICollectionReusableView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        backgroundColor = .white
        layer.cornerRadius = 4
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
