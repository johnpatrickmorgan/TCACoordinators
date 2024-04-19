import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

public extension TCARouter
  where
  CoordinatorState: IdentifiedRouterState,
  CoordinatorState.Screen == Screen,
	CoordinatorAction: CasePathable,
  Screen.ID == ID
{
  /// Convenience initializer for managing screens in an `IdentifiedArray`, where State
  /// and Action conform to the `IdentifiedRouter...` protocols.
  init(
    _ store: Store<CoordinatorState, CoordinatorAction>,
		action: CaseKeyPath<CoordinatorAction, IdentifiedRouterAction<Screen, ScreenAction>>,
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
