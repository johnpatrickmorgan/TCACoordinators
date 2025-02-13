import ComposableArchitecture
import FlowStacks

/// A special action type used in coordinators, which ensures screen-level actions are dispatched to the correct screen reducer,
/// and allows routes to be updated when a user navigates back.
@CasePathable
public enum RouterAction<ID: Hashable, Screen, ScreenAction> {
  case updateRoutes(_ routes: [Route<Screen>])
  case routeAction(id: ID, action: ScreenAction)
}

public extension RouterAction.AllCasePaths {
  subscript(id id: ID) -> AnyCasePath<RouterAction, ScreenAction> {
    AnyCasePath(
      embed: { .routeAction(id: id, action: $0) },
      extract: {
        guard case .routeAction(id, let action) = $0 else { return nil }
        return action
      }
    )
  }
}
