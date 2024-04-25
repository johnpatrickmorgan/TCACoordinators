import ComposableArchitecture
import FlowStacks
import Foundation

/// A protocol standardizing naming conventions for state types that contain routes
/// within an `IdentifiedArray`.
@available(*, deprecated, message: "Obsoleted, can be removed from your State type")
public protocol IdentifiedRouterState {
  associatedtype Screen: Identifiable

  /// An identified array of routes representing a navigation/presentation stack.
  var routes: IdentifiedArrayOf<Route<Screen>> { get set }
}
