import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

public extension TCARouter where Screen: Identifiable {
  /// Convenience initializer for managing screens in an `IdentifiedArray`.
  init(
    _ store: Store<IdentifiedArrayOf<Route<Screen>>, IdentifiedRouterAction<Screen, ScreenAction>>,
    @ViewBuilder screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
  ) where Screen.ID == ID {
    self.init(
      store: store.scope(state: \.elements, action: \.self),
      identifier: { state, _ in state.id },
      screenContent: screenContent
    )
  }
}

public extension ObservedTCARouter where Screen: Identifiable {
  /// Convenience initializer for managing screens in an `IdentifiedArray`.
  init(
    _ store: Store<IdentifiedArrayOf<Route<Screen>>, IdentifiedRouterAction<Screen, ScreenAction>>,
    @ViewBuilder screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
  ) where Screen.ID == ID {
    self.init(
      store: store.scope(state: \.elements, action: \.self),
      identifier: { state, _ in state.id },
      screenContent: screenContent
    )
  }
}

extension Route: Identifiable where Screen: Identifiable {
  public var id: Screen.ID { screen.id }
}
