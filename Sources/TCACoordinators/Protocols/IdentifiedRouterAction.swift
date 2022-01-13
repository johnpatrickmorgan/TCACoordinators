import Foundation
import ComposableArchitecture
import FlowStacks

/// A protocol standardizing naming conventions for action types that can manage routes
/// within an `IdentifiedArray`.
public protocol IdentifiedRouterAction {
  associatedtype Screen: Identifiable
  associatedtype ScreenAction

  /// Creates an action that allows routes to be updated whenever the user navigates back.
  /// - Returns: An `IdentifiedRouteAction`, usually a case in an enum.
  static func updateRoutes(_ routes: IdentifiedArrayOf<Route<Screen>>) -> Self

  /// Creates an action that allows a child action for a specific screen to be dispatched to that
  /// screen's reducer.
  /// - Returns: An `IdentifiedRouteCoordinatorAction`, usually a case in an enum.
  static func routeAction(_ id: Screen.ID, action: ScreenAction) -> Self
}
