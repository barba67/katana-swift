//
//  SetPin.swift
//  Katana
//
//  Created by Luca Querella on 29/08/16.
//  Copyright © 2016 Bending Spoons. All rights reserved.
//

import Katana

struct AddTodo: SyncAction {
  var payload: String
  
  static func reduce(state: State, action: AddTodo) -> State {
    guard var state = state as? ToDoState else {
      fatalError()
    }

    state.todos.append(action.payload)
    state.todosCompleted.append(false)
    return state
  }
}
