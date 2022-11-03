import Foundation
import ComposableArchitecture
import FlowStacks

/// A protocol standardizing naming conventions for state types that contain routes
/// within an `IdentifiedArray`.
public protocol IdentifiedRouterState {
  associatedtype Screen: Identifiable

  /// An identified array of routes representing a navigation/presentation stack.
  var routes: IdentifiedArrayOf<Route<Screen>> { get set }
}

public typealias IdentifiedRouter<State, Action> = ReducerProtocol<State, Action> where State: IdentifiedRouterState, Action: IdentifiedRouterAction, State.Screen == Action.Screen
