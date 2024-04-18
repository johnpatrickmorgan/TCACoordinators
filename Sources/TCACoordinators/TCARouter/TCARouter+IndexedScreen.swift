import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

public extension TCARouter
  where
  ID == Int,
  CoordinatorState: IndexedRouterState,
  CoordinatorState.Screen == Screen,
	CoordinatorAction: CasePathable
{
  /// Convenience initializer for managing screens in an `Array` identified by index, where
  /// State and Action conform to the `IdentifiedRouter...` protocols.
  init(
    _ store: Store<CoordinatorState, CoordinatorAction>,
		action: CaseKeyPath<CoordinatorAction, IndexedRouterAction<Screen, ScreenAction>>,
    screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
  ) {
    self.init(
      store: store,
      routes: \.routes,
			updateRoutes: action.appending(path: \.updateRoutes),
			action: action.appending(path: \.routeAction),
      screenContent: screenContent
    )
  }
}
