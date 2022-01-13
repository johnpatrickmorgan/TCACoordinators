import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

extension TCARouter
where
  ID == Int,
  CoordinatorAction: IndexedRouterAction,
  CoordinatorAction.Screen == Screen,
  CoordinatorAction.ScreenAction == ScreenAction,
  CoordinatorState: IndexedRouterState,
  CoordinatorState.Screen == Screen
{

  /// Convenience initializer for managing screens in an `Array` identified by index, where
  /// State and Action conform to the `IdentifiedRouter...` protocols.
  public init(
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
