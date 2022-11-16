import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

public extension TCARouter
  where
  CoordinatorState: IdentifiedRouterState,
  CoordinatorAction: IdentifiedRouterAction,
  CoordinatorState.Screen == Screen,
  CoordinatorAction.Screen == Screen,
  CoordinatorAction.ScreenAction == ScreenAction,
  Screen.ID == ID
{
  /// Convenience initializer for managing screens in an `IdentifiedArray`, where State
  /// and Action conform to the `IdentifiedRouter...` protocols.
  init(
    _ store: Store<CoordinatorState, CoordinatorAction>,
    screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
  ) {
    self.init(
      store: store,
      routes: { $0.routes },
      updateRoutes: CoordinatorAction.updateRoutes,
      action: CoordinatorAction.routeAction,
      screenContent: screenContent
    )
  }
}
