//
//  Node.swift
//  Katana
//
//  Created by Luca Querella on 09/08/16.
//  Copyright © 2016 Bending Spoons. All rights reserved.
//

import UIKit

private typealias ChildrenDictionary = [Int:[(node: AnyNode, index: Int)]]

public protocol AnyNode: class {
  var anyDescription: AnyNodeDescription { get }
  var children: [AnyNode]! { get }
  var managedChildren: [AnyNode] { get }

  var parent: AnyNode? {get}
  var root: Root? {get}
  
  func update(with description: AnyNodeDescription) throws
  func update(with description: AnyNodeDescription, parentAnimation: Animation) throws
  
  func addManagedChild(with description: AnyNodeDescription, in container: DrawableContainer) -> AnyNode
  func removeManagedChild(node: AnyNode)
  
  func forceReload()
}

protocol InternalAnyNode: AnyNode {
  //draw should never be called on a node directly, it should only be called from the Root.
  //use Description().makeRoot(..).draw(..)
  func draw(in container: DrawableContainer)
}

public class Node<Description: NodeDescription> {
  public fileprivate(set) var children: [AnyNode]!
  fileprivate var container: DrawableContainer?
  fileprivate(set) var state: Description.StateType
  fileprivate(set) var description: Description
  
  public fileprivate(set) weak var parent: AnyNode?
  public fileprivate(set) weak var root: Root?
  
  public var managedChildren: [AnyNode] = []

  
  public init(description: Description, parent: AnyNode? = nil, root: Root? = nil) {
    
    guard (parent != nil) != (root != nil) else {
      fatalError("either the parent or the root should be passed")
    }
    
    self.description = description
    self.state = Description.StateType.init()
    self.parent = parent
    self.root = root
    
    self.description.props = self.updatedPropsWithConnect(description: description, props: self.description.props)
    
    let childrenDescriptions  = self.childrenDescriptions() // should be renderedChildren()
        
    self.children = self.processedChildrenBeforeDraw(childrenDescriptions).map {
      $0.makeNode(parent: self)
    }
  }
  
  // Customization point for sublcasses. It allowes to update the children before they get drawn
  public func processedChildrenBeforeDraw(_ children: [AnyNodeDescription]) -> [AnyNodeDescription] {
    return children
  }
  
  public func draw(in container: DrawableContainer) {
    if self.container != nil {
      fatalError("draw can only be call once on a node")
    }
    
    self.container = container.addChild() { Description.NativeView() }
    
    let update = { [weak self] (state: Description.StateType) -> Void in
      DispatchQueue.main.async {
        self?.update(for: state)
      }
    }
    
    self.container?.update { view in
      Description.applyPropsToNativeView(props: self.description.props,
                                         state: self.state,
                                         view: view as! Description.NativeView,
                                         update: update,
                                         node: self)
    }
    
    
    children.forEach { child in
      let child = child as! InternalAnyNode
      child.draw(in: self.container!)
    }
  }
  
  public func addManagedChild(with description: AnyNodeDescription, in container: DrawableContainer) -> AnyNode {
    let node = description.makeNode(parent: self) as! InternalAnyNode
    self.managedChildren.append(node)
    node.draw(in: container)
    return node
  }
  
  public func removeManagedChild(node: AnyNode) {
    let index = self.managedChildren.index { node === $0 }
    self.managedChildren.remove(at: index!)
  }

}

fileprivate extension Node {
  fileprivate func redraw(childrenToAdd: [AnyNode], viewIndexes: [Int], animation: Animation) {
    guard let container = self.container else {
      return
    }
    
    assert(viewIndexes.count == self.children.count)
    
    let update = { [weak self] (state: Description.StateType) -> Void in
      self?.update(for: state)
    }
    
    animation.animate {
      container.update { view in
        Description.applyPropsToNativeView(props: self.description.props,
                                           state: self.state,
                                           view: view as! Description.NativeView,
                                           update: update,
                                           node: self)
      }
    }
    
    childrenToAdd.forEach { node in
      let node = node as! InternalAnyNode
      return node.draw(in: container)
    }
    
    var currentSubviews: [DrawableContainerChild?] =  container.children().map { $0 }
    let sorted = viewIndexes.isSorted
    
    for viewIndex in viewIndexes {
      let currentSubview = currentSubviews[viewIndex]!
      if !sorted {
        container.bringChildToFront(currentSubview)
      }
      currentSubviews[viewIndex] = nil
    }
    
    for view in currentSubviews {
      if let viewToRemove = view {
        self.container?.removeChild(viewToRemove)
      }
    }
  }
  
  fileprivate func childrenDescriptions() -> [AnyNodeDescription] {
    let update = { [weak self] (state: Description.StateType) -> Void in
      DispatchQueue.main.async {
        self?.update(for: state)
      }
    }
    
    let dispatch =  self.treeRoot.store?.dispatch ?? { fatalError("\($0) cannot be dispatched. Store not avaiable.") }
    
    return type(of: description).childrenDescriptions(props: self.description.props,
                                        state: self.state,
                                        update: update,
                                        dispatch: dispatch)
  }
  
  fileprivate func updatedPropsWithConnect(description: Description, props: Description.PropsType) -> Description.PropsType {
    if let desc = description as? AnyConnectedNodeDescription {
      // description is connected to the store, we need to update it
      
      guard let store = self.treeRoot.store else {
        fatalError("connected not lacks store")
      }
      
      let state = store.anyState
      return type(of: desc).anyConnect(parentProps: description.props, storageState: state) as! Description.PropsType
    }
    
    return props
  }
  
  fileprivate func update(for state: Description.StateType) {
    self.update(for: state, description: self.description, parentAnimation: .none)
  }
  
  fileprivate func update(for state: Description.StateType,
                          description: Description,
                          parentAnimation: Animation,
                          force: Bool = false) {
    
    guard force || self.description.props != description.props || self.state != state else {
      return
    }
    
    let childrenAnimation = type(of: self.description).childrenAnimationForNextRender(
      currentProps: self.description.props,
      nextProps: description.props,
      currentState: self.state,
      nextState: state,
      parentAnimation: parentAnimation
    )
    
    self.description = description
    self.state = state
    
    var currentChildren = ChildrenDictionary()
    
    for (index, child) in children.enumerated() {
      let key = child.anyDescription.replaceKey
      let value = (node: child, index: index)
      
      if currentChildren[key] == nil {
        currentChildren[key] = [value]
      } else {
        currentChildren[key]!.append(value)
      }
    }
    
    var newChildrenDescriptions = self.childrenDescriptions()
    
    newChildrenDescriptions = self.processedChildrenBeforeDraw(newChildrenDescriptions)
    
    var nodes: [AnyNode] = []
    var viewIndexes: [Int] = []
    var childrenToAdd: [AnyNode] = []
    
    for newChildDescription in newChildrenDescriptions {
      let key = newChildDescription.replaceKey
      
      let childrenCount = currentChildren[key]?.count ?? 0
      
      if childrenCount > 0 {
        let replacement = currentChildren[key]!.removeFirst()
        assert(replacement.node.anyDescription.replaceKey == newChildDescription.replaceKey)
        try! replacement.node.update(with: newChildDescription, parentAnimation: childrenAnimation)
        
        nodes.append(replacement.node)
        viewIndexes.append(replacement.index)
        
      } else {
        //else create a new node
        let node = newChildDescription.makeNode(parent: self)
        viewIndexes.append(children.count + childrenToAdd.count)
        nodes.append(node)
        childrenToAdd.append(node)
      }
    }
    
    self.children = nodes
    self.redraw(childrenToAdd: childrenToAdd, viewIndexes: viewIndexes, animation: parentAnimation)
  }
}

extension Node: AnyNode {
  public var anyDescription: AnyNodeDescription {
    get {
      return self.description
    }
  }
  
  public func update(with description: AnyNodeDescription) throws {
    try self.update(with: description, parentAnimation: .none)
  }
  
  public func update(with description: AnyNodeDescription, parentAnimation animation: Animation = .none) throws {
    var description = description as! Description
    description.props = self.updatedPropsWithConnect(description: description, props: description.props)
    self.update(for: self.state, description: description, parentAnimation: animation)
  }
  
  public func forceReload() {
    self.update(for: self.state, description: self.description, parentAnimation: .none, force: true)
  }
}

extension Node : InternalAnyNode {
  
}
