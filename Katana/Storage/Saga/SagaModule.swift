//
//  SagaModule.swift
//  ReKatana
//
//  Created by Mauro Bolis on 09/08/16.
//  Copyright © 2016 BendingSpoons. All rights reserved.
//

import Foundation

public struct SagaModule {
  private(set) var sagas: [String: AnySaga] = [:]
  
  mutating func addSaga<ManagedAction: Action, RootReducer: Reducer, Providers: SagaProvidersContainer<RootReducer>>(
    _ saga: Saga<ManagedAction, RootReducer, Providers>,
    forActionNamed name: String
  ) {
    sagas[name] = { action, getState, dispatch, providers in
      if  let a = action as? ManagedAction,
          let gS = getState as? () -> RootReducer.StateType,
          let p = providers as? Providers {

        saga(a, gS, dispatch, p)
        return
      }
    
      preconditionFailure("This should not happen, it is most likely a bug in the library. Please open an issue")
    }
  }
}
