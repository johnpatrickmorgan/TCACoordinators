import ComposableArchitecture
import Foundation
import SwiftUI

extension Reducer
where
  Action: IndexedScreenCoordinatorAction, State: IndexedScreenCoordinatorState,
  Action.ScreenState == State.Screen {
  
  public func updateScreensOnInteraction() -> Reducer {
    return self.combined(with: Reducer { state, action, environment in
      let casePath = /Action.updateScreens
      if let screens = casePath.extract(from: action) {
        state.screens = screens
      }
      return .none
    })
  }
}

extension Reducer
where
  Action: IdentifiedScreenCoordinatorAction, State: IdentifiedScreenCoordinatorState,
  Action.ScreenState == State.Screen {
  
  public func updateScreensOnInteraction() -> Reducer {
    return self.combined(with: Reducer { state, action, environment in
      let casePath = /Action.updateScreens
      if let screens = casePath.extract(from: action) {
        state.screens = screens
      }
      return .none
    })
  }
}
