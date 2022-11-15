import ComposableArchitecture
import Foundation

struct ForEachIndexedRoute<CoordinatorReducer: ReducerProtocol, ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>: ReducerProtocol {
  let coordinatorReducer: CoordinatorReducer
  let screenReducer: ScreenReducer
  let coordinatorIdForCancellation: CoordinatorID?
  let toLocalState: WritableKeyPath<CoordinatorReducer.State, Array<Route<ScreenReducer.State>>>
  let toLocalAction: CasePath<CoordinatorReducer.Action, (Int, ScreenReducer.Action)>
  let updateRoutes: CasePath<CoordinatorReducer.Action, Array<Route<ScreenReducer.State>>>
  
  var reducer: AnyReducer<CoordinatorReducer.State, CoordinatorReducer.Action, Void> {
    let x: AnyReducer<CoordinatorReducer.State, CoordinatorReducer.Action, Void> = AnyReducer<ScreenReducer.State, ScreenReducer.Action, Void>(screenReducer)
      .forEachIndexedRoute(
        state: toLocalState,
        action: toLocalAction,
        updateRoutes: updateRoutes,
        environment: { _ in }
      )
    return x
      .withRouteReducer(
        routes: { $0[keyPath: toLocalState] },
        routeAction: toLocalAction,
        coordinatorIdForCancellation: coordinatorIdForCancellation,
        getIdentifier: { _, index in index },
        routeReducer: AnyReducer(coordinatorReducer)
      )
  }
  
  var body: some ReducerProtocol<CoordinatorReducer.State, CoordinatorReducer.Action> {
    Reduce(reducer, environment: ())
  }
}

public extension ReducerProtocol {
  func forEachIndexedRoute<ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>(
    coordinatorIdForCancellation: CoordinatorID?,
    toLocalState: WritableKeyPath<Self.State, Array<Route<ScreenReducer.State>>>,
    toLocalAction: CasePath<Self.Action, (Int, ScreenReducer.Action)>,
    updateRoutes: CasePath<Self.Action, Array<Route<ScreenReducer.State>>>,
    @ReducerBuilderOf<ScreenReducer> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> {
    return ForEachIndexedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      coordinatorIdForCancellation: coordinatorIdForCancellation,
      toLocalState: toLocalState,
      toLocalAction: toLocalAction,
      updateRoutes: updateRoutes
    )
  }
}

public extension ReducerProtocol where State: IndexedRouterState, Action: IndexedRouterAction, State.Screen == Action.Screen {
  func forEachIndexedRoute<ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>(
    coordinatorIdForCancellation: CoordinatorID?,
    @ReducerBuilderOf<ScreenReducer> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> where State.Screen == ScreenReducer.State, ScreenReducer.Action == Action.ScreenAction {
    return ForEachIndexedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      coordinatorIdForCancellation: coordinatorIdForCancellation,
      toLocalState: \.routes,
      toLocalAction: /Action.routeAction,
      updateRoutes: /Action.updateRoutes
    )
  }
  
  func forEachIndexedRoute<ScreenReducer: ReducerProtocol>(
    coordinatorIdType: Any.Type?,
    @ReducerBuilderOf<ScreenReducer> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> where State.Screen == ScreenReducer.State, ScreenReducer.Action == Action.ScreenAction {
    return ForEachIndexedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      coordinatorIdForCancellation: coordinatorIdType.map(ObjectIdentifier.init),
      toLocalState: \.routes,
      toLocalAction: /Action.routeAction,
      updateRoutes: /Action.updateRoutes
    )
  }
}
