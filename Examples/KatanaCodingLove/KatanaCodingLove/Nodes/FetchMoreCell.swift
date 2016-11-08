//
//  FetchMoreCell.swift
//  Katana
//
//  Created by Alain Caltieri on 07/11/16.
//  Copyright © 2016 Bending Spoons. All rights reserved.
//

import Foundation
import Katana
import KatanaElements

extension FetchMoreCell {
    enum Keys: String {
        case label
    }
    
    struct Props: NodeProps {
        var frame: CGRect = .zero
        var loading: Bool = true
        var allPostsFetched: Bool = false
    }
}


struct FetchMoreCell: PlasticNodeDescription, PlasticNodeDescriptionWithReferenceSize, TableCell  {
    typealias StateType = EmptyHighlightableState
    typealias PropsType = Props
    typealias NativeView = NativeTableCell
    
    var props: Props
    
    static var referenceSize: CGSize {
        return CGSize(width: 640, height: 200)
    }
    
    static func childrenDescriptions(props: PropsType,
                                     state: StateType,
                                     update: @escaping (StateType)->(),
                                     dispatch: @escaping StoreDispatch) -> [AnyNodeDescription] {
        
        var labelText = "Fetch More"
        if props.loading {
            labelText = "Loading..."
        } else if props.allPostsFetched {
            labelText = "No more available"
        }
        
        return [
            Label(props: LabelProps.build({
                $0.key = Keys.label.rawValue
                $0.text = NSAttributedString(string: labelText, attributes: [
                    NSFontAttributeName: UIFont.systemFont(ofSize: 16)
                    ])
                $0.textAlignment = NSTextAlignment.center
                
                if state.highlighted {
                    $0.backgroundColor = UIColor(colorLiteralRed: 0.9, green: 0.9, blue: 0.9, alpha: 1)
                } else {
                    $0.backgroundColor = UIColor.white
                }
            })),
        ]
    }
    
    static func layout(views: ViewsContainer<Keys>, props: Props, state: EmptyHighlightableState) {
        let rootView = views.nativeView
        let title = views[Keys.label]!
        
        title.fill(rootView)
    }
    
    static func didTap(dispatch: StoreDispatch, props: Props, indexPath: IndexPath) {
        if props.allPostsFetched {
            return
        }
        
        dispatch(FetchMorePosts(payload: ""))
    }

}
