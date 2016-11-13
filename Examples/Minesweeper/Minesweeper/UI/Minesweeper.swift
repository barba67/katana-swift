//
//  Minesweeper.swift
//  Katana
//
//  Copyright © 2016 Bending Spoons.
//  Distributed under the MIT License.
//  See the LICENSE file for more information.

import Katana
import KatanaElements

// MARK: - NodeDescription
struct Minesweeper: NodeDescription, ConnectedNodeDescription, PlasticNodeDescription, PlasticReferenceSizeable {
  typealias StateType = EmptyState
  typealias PropsType = Props
  typealias NativeView = UIView
  
  var props: Props
  static var referenceSize: CGSize = CGSize(width: 750, height: 1334)
  
  static func childrenDescriptions(props: PropsType,
                                   state: StateType,
                                   update: @escaping (EmptyState) -> (),
                                   dispatch: @escaping StoreDispatch) -> [AnyNodeDescription] {
    
    func buttonTap() {
      dispatch(StartGame(payload: .hard))
    }
    
    let text = props.gameover ? "gameover :( tap to restart" : ":) tap to restart"
    
    let button = Button(props: ButtonProps.build({
      $0.setKey(Keys.title)
      $0.titles = [.normal : text]
      $0.borderColor = .darkGray
      $0.borderWidth = .fixed(2)
      $0.titleColors = [.normal: .black, .highlighted: .lightGray]
      $0.touchHandlers = [.touchUpInside : buttonTap]
    }))
    
    let minesweeperGrid = MinesweeperGrid(props: MinesweeperGrid.Props.build({
      $0.setKey(Keys.field)
    }))
    
    return [button, minesweeperGrid]
  }
  
  static func layout(views: ViewsContainer<Minesweeper.Keys>, props: Minesweeper.Props, state: EmptyState) {
    let root = views.nativeView
    let title = views[.title]!
    let field = views[.field]!
    
    title.asHeader(root, insets: .scalable(30, 0, 0, 0))
    title.height = .scalable(60)
    
    field.fillHorizontally(root)
    field.top = title.bottom
    field.bottom = root.bottom
  }
  
  static func connect(props: inout Minesweeper.Props, to storeState: MinesweeperState) {
    props.gameover = storeState.gameOver
  }
}

// MARK: Keys and Props
extension Minesweeper {
  enum Keys {
    case title, field
  }
  
  struct Props: NodeDescriptionProps, Buildable {
    public var frame: CGRect = .zero
    public var alpha: CGFloat = 1.0
    public var key: String?
    
    var gameover: Bool = false
    
    static func == (lhs: Props, rhs: Props) -> Bool {
      return
        lhs.frame == rhs.frame &&
        lhs.alpha == rhs.alpha &&
        lhs.gameover == rhs.gameover
    }
  }
}
