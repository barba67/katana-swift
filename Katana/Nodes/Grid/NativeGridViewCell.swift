//
//  NativeGridViewCell.swift
//  Katana
//
//  Created by Mauro Bolis on 23/08/16.
//  Copyright © 2016 Bending Spoons. All rights reserved.
//

import Foundation

class NativeGridViewCell: UICollectionViewCell {
  private var node: AnyNode? = nil
  private var listenerNode: RootNode? = nil
  
  override var isHighlighted: Bool {
    didSet {
      // let's see if in our subviews there is a CellNativeView, which we can use
      // to properly update the state
      // it there is such view, it is the only subview of contentview
      if let view = self.contentView.subviews.first as? CellNativeView {
        view.setHighlighted(self.isHighlighted)
      }
    }
  }
  
  func update(withParentNode parentNode: AnyNode, description: AnyNodeDescription) {
    // we need to pass the cell frame
    // here we are causing a second evaluation of the description
    // Is there any way to avoid this? Passing the frame to the delegate could be an option
    // but it is very very ugly
    var newDescription = description
    newDescription.frame = self.bounds
    
    
    if let node = self.node {
      if node.anyDescription.replaceKey == description.replaceKey {
        // we just need to let the node do its job
        try! node.update(description: newDescription)
        return
      }
    }
    
    // either we don't have a node or the description are not compatible
    // just create a new node
    for view in self.contentView.subviews {
      view.removeFromSuperview()
    }
    
    self.node = newDescription.node(parentNode: parentNode)
    self.listenerNode = RootNode(store: parentNode.store, node: self.node!)
    self.listenerNode!.draw(container: self.contentView)
  }
  
  func didTap(atIndexPath indexPath: IndexPath) {
    if let description = self.node?.anyDescription as? AnyCellNodeDescription, let store = node?.store {
      type(of: description).anyDidTap(dispatch: store.dispatch, props: description.anyProps, indexPath: indexPath)
    }
  }
}
