import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

extension AnyReducer {
  /// Transforms a reducer into one that tags route actions' effects for cancellation with the `coordinatorId`
  /// and route index.
  /// - Parameter coordinatorId: A stable identifier for the coordinator. It should match the one used in a
  ///     subsequent call to `cancelTaggedScreenEffectsOnDismiss`.
  /// - Parameter routeAction: A case path to an action that dispatches route actions to the correct screen.
  /// - Returns: A new `Reducer`.
  func tagRouteEffectsForCancellation<RouteAction, CoordinatorID: Hashable, RouteID: Hashable>(
    coordinatorId: CoordinatorID,
    routeAction: CasePath<Action, (RouteID, RouteAction)>
  ) -> Self {
    return AnyReducer { state, action, environment in
      let effect = self.run(&state, action, environment)

      if let (routeId, _) = routeAction.extract(from: action) {
        let identity = CancellationIdentity(coordinatorId: coordinatorId, routeId: routeId)
        return effect.cancellable(id: AnyHashable(identity))
      } else {
        return effect
      }
    }
  }

  /// Transforms a reducer into one that cancels tagged route actions when that route is no
  /// longer shown, identifying routes by their index.
  /// - Parameter coordinatorId: A stable identifier for the coordinator.
  /// - Parameter routes: A closure that accesses the coordinator's routes collection.
  /// - Returns: A new `Reducer`.
  func cancelTaggedRouteEffectsOnDismiss<CoordinatorID: Hashable, C: Collection, RouteID: Hashable>(
    coordinatorId: CoordinatorID,
    routes: @escaping (State) -> C,
    getIdentifier: @escaping (C.Element, C.Index) -> RouteID
  ) -> Self {
    return AnyReducer { state, action, environment in
      let preRoutes = routes(state)
      let effect = self.run(&state, action, environment)
      let postRoutes = routes(state)

      var effects: [Effect<Action, Never>] = [effect]

      let preIds = zip(preRoutes, preRoutes.indices).map(getIdentifier)
      let postIds = zip(postRoutes, postRoutes.indices).map(getIdentifier)

      let dismissedIds = Set(preIds).subtracting(postIds)
      for dismissedId in dismissedIds {
        let identity = CancellationIdentity(coordinatorId: coordinatorId, routeId: dismissedId)
        effects.append(Effect<Action, Never>.cancel(id: AnyHashable(identity)))
      }

      return Effect.merge(effects)
    }
  }
}
