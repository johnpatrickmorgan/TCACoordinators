import Foundation
import FlowStacks

/// A protocol standardizing naming conventions for state types that contain routes
/// within an `IdentifiedArray`.
public protocol IndexedRouterState {
  associatedtype Screen

  /// An array of screens, identified by index, representing a navigation/presentation stack.
  var routes: [Route<Screen>] { get set }
}
