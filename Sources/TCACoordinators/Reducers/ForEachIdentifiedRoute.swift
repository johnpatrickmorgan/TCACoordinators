import ComposableArchitecture
import Foundation

struct ForEachIdentifiedRoute<CoordinatorReducer: ReducerProtocol, ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>: ReducerProtocol where ScreenReducer.State: Identifiable {
  let coordinatorReducer: CoordinatorReducer
  let screenReducer: ScreenReducer
  let cancellationId: CoordinatorID?
  let toLocalState: WritableKeyPath<CoordinatorReducer.State, IdentifiedArrayOf<Route<ScreenReducer.State>>>
  let toLocalAction: CasePath<CoordinatorReducer.Action, (ScreenReducer.State.ID, ScreenReducer.Action)>
  let updateRoutes: CasePath<CoordinatorReducer.Action, IdentifiedArrayOf<Route<ScreenReducer.State>>>

  var body: some ReducerProtocol<CoordinatorReducer.State, CoordinatorReducer.Action> {
    CancelEffectsOnDismiss(
      coordinatedScreensReducer: EmptyReducer()
        .forEach(toLocalState, action: toLocalAction) {
          OnRoutes(wrapped: screenReducer)
        }
        .updatingRoutesOnInteraction(
          updateRoutes: updateRoutes,
          toLocalState: toLocalState
        ),
      routes: { $0[keyPath: toLocalState] },
      routeAction: toLocalAction,
      cancellationId: cancellationId,
      getIdentifier: { element, _ in element.id },
      coordinatorReducer: coordinatorReducer
    )
  }
}

public extension ReducerProtocol {
  func forEachRoute<ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>(
    cancellationId: CoordinatorID?,
    toLocalState: WritableKeyPath<Self.State, IdentifiedArrayOf<Route<ScreenReducer.State>>>,
    toLocalAction: CasePath<Self.Action, (ScreenReducer.State.ID, ScreenReducer.Action)>,
    updateRoutes: CasePath<Self.Action, IdentifiedArrayOf<Route<ScreenReducer.State>>>,
    @ReducerBuilderOf<ScreenReducer> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> where ScreenReducer.State: Identifiable {
    return ForEachIdentifiedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      cancellationId: cancellationId,
      toLocalState: toLocalState,
      toLocalAction: toLocalAction,
      updateRoutes: updateRoutes
    )
  }
}

public extension ReducerProtocol where State: IdentifiedRouterState, Action: IdentifiedRouterAction, State.Screen == Action.Screen {
  /// Allows a screen reducer to be incorporated into a coordinator reducer, such that each screen in
  /// the coordinator's routes IdentifiedArray will have its actions and state propagated. When screens are
  /// dismissed, the routes will be updated. If a cancellation identifier is passed, in-flight effects
  /// will be cancelled when a screen is dismissed.
  /// - Parameters:
  ///   - cancellationId: An ID to use for cancelling in-flight effects when a view is dismissed. It
  ///   will be combined with the screen's identifier.
  ///   - screenReducer: The reducer that operates on all of the individual screens.
  /// - Returns: A new reducer combining the coordinator-level and screen-level reducers.
  func forEachRoute<ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>(
    cancellationId: CoordinatorID?,
    @ReducerBuilderOf<ScreenReducer> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> where ScreenReducer.State: Identifiable, State.Screen == ScreenReducer.State, ScreenReducer.Action == Action.ScreenAction {
    return ForEachIdentifiedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      cancellationId: cancellationId,
      toLocalState: \.routes,
      toLocalAction: /Action.routeAction,
      updateRoutes: /Action.updateRoutes
    )
  }
  
  /// Allows a screen reducer to be incorporated into a coordinator reducer, such that each screen in
  /// the coordinator's routes IdentifiedArray will have its actions and state propagated. When screens are
  /// dismissed, the routes will be updated. If a cancellation identifier is passed, in-flight effects
  /// will be cancelled when a screen is dismissed.
  /// - Parameters:
  ///   - cancellationIdType: A type to use for cancelling in-flight effects when a view is dismissed. It
  ///   will be combined with the screen's identifier.
  ///   - screenReducer: The reducer that operates on all of the individual screens.
  /// - Returns: A new reducer combining the coordinator-level and screen-level reducers.
  func forEachRoute<ScreenReducer: ReducerProtocol>(
    cancellationIdType: Any.Type = Self.self,
    @ReducerBuilderOf<ScreenReducer> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> where ScreenReducer.State: Identifiable, State.Screen == ScreenReducer.State, ScreenReducer.Action == Action.ScreenAction {
    return ForEachIdentifiedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      cancellationId: ObjectIdentifier(cancellationIdType),
      toLocalState: \.routes,
      toLocalAction: /Action.routeAction,
      updateRoutes: /Action.updateRoutes
    )
  }
}
