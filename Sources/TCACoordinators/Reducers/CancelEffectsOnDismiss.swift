import ComposableArchitecture
import Foundation

/// Identifier for a particular route within a particular coordinator.
public struct CancellationIdentity<CoordinatorID: Hashable, RouteID: Hashable>: Hashable {
  let coordinatorId: CoordinatorID
  let routeId: RouteID
}

struct CancelEffectsOnDismiss<CoordinatorScreensReducer: Reducer, CoordinatorReducer: Reducer, CoordinatorID: Hashable, ScreenAction, RouteID: Hashable, C: Collection>: Reducer where CoordinatorScreensReducer.State == CoordinatorReducer.State, CoordinatorScreensReducer.Action == CoordinatorReducer.Action {
  let coordinatedScreensReducer: CoordinatorScreensReducer
  let routes: (CoordinatorReducer.State) -> C
  let routeAction: CasePath<Action, (RouteID, ScreenAction)>
  let cancellationId: CoordinatorID?
  let getIdentifier: (C.Element, C.Index) -> RouteID
  let coordinatorReducer: CoordinatorReducer

  var body: some ReducerOf<CoordinatorReducer> {
    if let cancellationId {
      CancelTaggedRouteEffectsOnDismiss(
        coordinatorReducer: CombineReducers {
          TagRouteEffectsForCancellation(
            screenReducer: coordinatedScreensReducer,
            coordinatorId: cancellationId,
            routeAction: routeAction
          )
          coordinatorReducer
        },
        coordinatorId: cancellationId,
        routes: routes,
        getIdentifier: getIdentifier
      )
    } else {
      CombineReducers {
        coordinatorReducer
        coordinatedScreensReducer
      }
    }
  }
}

struct TagRouteEffectsForCancellation<ScreenReducer: Reducer, CoordinatorID: Hashable, RouteID: Hashable, RouteAction>: Reducer {
  let screenReducer: ScreenReducer
  let coordinatorId: CoordinatorID
  let routeAction: CasePath<Action, (RouteID, RouteAction)>

  var body: some ReducerOf<ScreenReducer> {
    Reduce { state, action in
      let effect = screenReducer.reduce(into: &state, action: action)

      if let (routeId, _) = routeAction.extract(from: action) {
        let identity = CancellationIdentity(coordinatorId: coordinatorId, routeId: routeId)
        return effect.cancellable(id: AnyHashable(identity))
      } else {
        return effect
      }
    }
  }
}

struct CancelTaggedRouteEffectsOnDismiss<CoordinatorReducer: Reducer, CoordinatorID: Hashable, C: Collection, RouteID: Hashable>: Reducer {
  let coordinatorReducer: CoordinatorReducer
  let coordinatorId: CoordinatorID
  let routes: (State) -> C
  let getIdentifier: (C.Element, C.Index) -> RouteID

  var body: some ReducerOf<CoordinatorReducer> {
    Reduce { state, action in
      let preRoutes = routes(state)
      let effect = coordinatorReducer.reduce(into: &state, action: action)
      let postRoutes = routes(state)

      var effects: [Effect<Action>] = [effect]

      let preIds = zip(preRoutes, preRoutes.indices).map(getIdentifier)
      let postIds = zip(postRoutes, postRoutes.indices).map(getIdentifier)

      let dismissedIds = Set(preIds).subtracting(postIds)
      for dismissedId in dismissedIds {
        let identity = CancellationIdentity(coordinatorId: coordinatorId, routeId: dismissedId)
        effects.append(Effect<Action>.cancel(id: AnyHashable(identity)))
      }

      return .merge(effects)
    }
  }
}
