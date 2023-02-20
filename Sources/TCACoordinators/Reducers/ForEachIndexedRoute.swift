import ComposableArchitecture
import Foundation

struct ForEachIndexedRoute<CoordinatorReducer: ReducerProtocol, ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>: ReducerProtocol {
  let coordinatorReducer: CoordinatorReducer
  let screenReducer: ScreenReducer
  let cancellationId: CoordinatorID?
  let toLocalState: WritableKeyPath<CoordinatorReducer.State, [Route<ScreenReducer.State>]>
  let toLocalAction: CasePath<CoordinatorReducer.Action, (Int, ScreenReducer.Action)>
  let updateRoutes: CasePath<CoordinatorReducer.Action, [Route<ScreenReducer.State>]>
  
  var body: some ReducerProtocol<CoordinatorReducer.State, CoordinatorReducer.Action> {
    CancelEffectsOnDismiss(
      coordinatedScreensReducer: EmptyReducer()
        .forEachIndex(toLocalState, action: toLocalAction) {
          OnRoutes(wrapped: screenReducer)
        }
        .updatingRoutesOnInteraction(
          updateRoutes: updateRoutes,
          toLocalState: toLocalState
        ),
      routes: { $0[keyPath: toLocalState] },
      routeAction: toLocalAction,
      cancellationId: cancellationId,
      getIdentifier: { _, index in index },
      coordinatorReducer: coordinatorReducer
    )
  }
}

public extension ReducerProtocol {
  func forEachRoute<ScreenReducer: ReducerProtocol, ScreenState, ScreenAction, CoordinatorID: Hashable>(
    coordinatorIdForCancellation: CoordinatorID?,
    toLocalState: WritableKeyPath<Self.State, [Route<ScreenReducer.State>]>,
    toLocalAction: CasePath<Self.Action, (Int, ScreenReducer.Action)>,
    updateRoutes: CasePath<Self.Action, [Route<ScreenReducer.State>]>,
    @ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> where ScreenState == ScreenReducer.State, ScreenAction == ScreenReducer.Action {
    return ForEachIndexedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      cancellationId: coordinatorIdForCancellation,
      toLocalState: toLocalState,
      toLocalAction: toLocalAction,
      updateRoutes: updateRoutes
    )
  }
}

public extension ReducerProtocol where State: IndexedRouterState, Action: IndexedRouterAction, State.Screen == Action.Screen {
  /// Allows a screen reducer to be incorporated into a coordinator reducer, such that each screen in
  /// the coordinator's routes Array will have its actions and state propagated. When screens are
  /// dismissed, the routes will be updated. If a cancellation identifier is passed, in-flight effects
  /// will be cancelled when the screen from which they originated is dismissed.
  /// - Parameters:
  ///   - cancellationId: An ID to use for cancelling in-flight effects when a view is dismissed. It
  ///   will be combined with the screen's identifier.
  ///   - screenReducer: The reducer that operates on all of the individual screens.
  /// - Returns: A new reducer combining the coordinator-level and screen-level reducers.
  func forEachRoute<ScreenReducer: ReducerProtocol, ScreenState, ScreenAction, CoordinatorID: Hashable>(
    coordinatorIdForCancellation: CoordinatorID?,
    @ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action>
    where State.Screen == ScreenReducer.State, ScreenReducer.Action == Action.ScreenAction,
          ScreenState == ScreenReducer.State, ScreenAction == ScreenReducer.Action {
    return ForEachIndexedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      cancellationId: coordinatorIdForCancellation,
      toLocalState: \.routes,
      toLocalAction: /Action.routeAction,
      updateRoutes: /Action.updateRoutes
    )
  }

  /// Allows a screen reducer to be incorporated into a coordinator reducer, such that each screen in
  /// the coordinator's routes Array will have its actions and state propagated. When screens are
  /// dismissed, the routes will be updated. If a cancellation identifier is passed, in-flight effects
  /// will be cancelled when the screen from which they originated is dismissed.
  /// - Parameters:
  ///   - cancellationIdType: A type to use for cancelling in-flight effects when a view is dismissed. It
  ///   will be combined with the screen's identifier. Defaults to the type of the parent reducer.
  ///   - screenReducer: The reducer that operates on all of the individual screens.
  /// - Returns: A new reducer combining the coordinator-level and screen-level reducers.
  func forEachRoute<ScreenReducer: ReducerProtocol, ScreenState, ScreenAction>(
    cancellationIdType: Any.Type = Self.self,
    @ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action>
    where State.Screen == ScreenReducer.State, ScreenReducer.Action == Action.ScreenAction,
          ScreenState == ScreenReducer.State, ScreenAction == ScreenReducer.Action {
    return ForEachIndexedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      cancellationId: ObjectIdentifier(cancellationIdType),
      toLocalState: \.routes,
      toLocalAction: /Action.routeAction,
      updateRoutes: /Action.updateRoutes
    )
  }
}
