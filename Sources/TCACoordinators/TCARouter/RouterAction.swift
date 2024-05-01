import ComposableArchitecture
import FlowStacks

/// A special action type used in coordinators, which ensures screen-level actions are dispatched to the correct screen reducer,
/// and allows routes to be updated when a user navigates back.
public enum RouterAction<ID: Hashable, Screen, ScreenAction>: CasePathable {
  case updateRoutes(_ routes: [Route<Screen>])
  case routeAction(id: ID, action: ScreenAction)

  public static var allCasePaths: AllCasePaths {
    AllCasePaths()
  }

  public struct AllCasePaths {
    public var updateRoutes: AnyCasePath<RouterAction, [Route<Screen>]> {
      AnyCasePath(
        embed: RouterAction.updateRoutes,
        extract: {
          guard case let .updateRoutes(routes) = $0 else { return nil }
          return routes
        }
      )
    }

    public var routeAction: AnyCasePath<RouterAction, (id: ID, action: ScreenAction)> {
      AnyCasePath(
        embed: RouterAction.routeAction,
        extract: {
          guard case let .routeAction(id, action) = $0 else { return nil }
          return (id, action)
        }
      )
    }

    public subscript(id id: ID) -> AnyCasePath<RouterAction, ScreenAction> {
      AnyCasePath(
        embed: { .routeAction(id: id, action: $0) },
        extract: {
          guard case .routeAction(id, let action) = $0 else { return nil }
          return action
        }
      )
    }
  }
}
