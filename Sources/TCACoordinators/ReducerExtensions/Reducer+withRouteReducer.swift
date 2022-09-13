import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

public extension Reducer where State: IndexedRouterState, Action: IndexedRouterAction {

  /// Transforms a reducer so that it tags effects for cancellation based on their index, then combines
  /// it with the provided route reducer, cancelling route effects for any route that has been dismissed.
  ///
  /// - Parameter cancelEffectsOnDismiss: Whether a route's effects should be cancelled when dismissed.
  /// - Parameter routeReducer: The reducer that can mutate the routes array.
  /// - Returns: The new reducer.
  func withRouteReducer(
    cancelEffectsOnDismiss: Bool = true,
    _ routeReducer: Self
  ) -> Self {
    self.withRouteReducer(
      routes: \State.routes,
      routeAction: /Action.routeAction,
      coordinatorIdForCancellation: cancelEffectsOnDismiss ? UUID() : nil,
      getIdentifier: { _, index in index },
      routeReducer: routeReducer
    )
  }
}

public extension Reducer where State: IdentifiedRouterState, Action: IdentifiedRouterAction, State.Screen == Action.Screen {

  /// Transforms a reducer so that it tags effects for cancellation based on their identity, then combines
  /// it with the provided route reducer, cancelling route effects for any route that has been dismissed.
  ///
  /// - Parameter cancelEffectsOnDismiss: Whether a route's effects should be cancelled when dismissed.
  /// - Parameter routeReducer: The reducer that can mutate the routes array.
  /// - Returns: The new reducer.
  func withRouteReducer(
    cancelEffectsOnDismiss: Bool = true,
    _ routeReducer: Self
  ) -> Self {
    self.withRouteReducer(
      routes: \State.routes,
      routeAction: /Action.routeAction,
      coordinatorIdForCancellation: cancelEffectsOnDismiss ? UUID() : nil,
      getIdentifier: { route, _ in route.id },
      routeReducer: routeReducer
    )
  }
}

public extension Reducer {
  
  /// Transforms a reducer so that it tags effects for cancellation based on their `CoordinatorID` and RouteID`,
  /// then combines it with the provided route reducer, cancelling route effects for any route that has been dismissed.
  ///
  /// - Parameter routes: A closure that accesses the routes from State.
  /// - Parameter routeAction: A case path for extracting a route action from an Action.
  /// - Parameter coordinatorIdForCancellation: If provided, each route's effects will be cancelled
  ///     when that route is dismissed.
  /// - Returns: The new reducer.
  func withRouteReducer<CoordinatorID: Hashable, ScreenAction, RouteID: Hashable, C: Collection>(
    routes: @escaping (State) -> C,
    routeAction: CasePath<Action, (RouteID, ScreenAction)>,
    coordinatorIdForCancellation: CoordinatorID?,
    getIdentifier: @escaping (C.Element, C.Index) -> RouteID,
    routeReducer: Self
  ) -> Self
  {
    guard let coordinatorId = coordinatorIdForCancellation else {
      return self.combined(with: routeReducer)
    }
    return self
      .tagRouteEffectsForCancellation(
        coordinatorId: coordinatorId,
        routeAction: routeAction
      )
      .combined(with: routeReducer)
      .cancelTaggedRouteEffectsOnDismiss(
        coordinatorId: coordinatorId,
        routes: routes,
        getIdentifier: getIdentifier
      )
  }
}
