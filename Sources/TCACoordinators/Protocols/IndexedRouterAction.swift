import FlowStacks
import Foundation

/// A protocol standardizing naming conventions for action types that can manage routes
/// within an `Array`.
public protocol IndexedRouterAction {
  associatedtype Screen
  associatedtype ScreenAction

  /// Creates an action that allows routes to be updated whenever the user navigates back.
  /// - Returns: An `IndexedScreenCoordinatorAction`, usually a case in an enum.
  static func updateRoutes(_ screens: [Route<Screen>]) -> Self

  /// Creates an action that allows the action for a specific screen to be dispatched to that screen's reducer.
  /// - Returns: An `IndexedScreenCoordinatorAction`, usually a case in an enum.
  static func routeAction(_ index: Int, action: ScreenAction) -> Self
}
