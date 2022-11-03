import ComposableArchitecture
import Foundation

struct ForEachIdentifiedRoute<CoordinatorReducer: ReducerProtocol, ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>: ReducerProtocol where ScreenReducer.State: Identifiable {
  let coordinatorReducer: CoordinatorReducer
  let screenReducer: ScreenReducer
  let coordinatorIdForCancellation: CoordinatorID?
  let toLocalState: WritableKeyPath<CoordinatorReducer.State, IdentifiedArrayOf<Route<ScreenReducer.State>>>
  let toLocalAction: CasePath<CoordinatorReducer.Action, (ScreenReducer.State.ID, ScreenReducer.Action)>
  let updateRoutes: CasePath<CoordinatorReducer.Action, IdentifiedArrayOf<Route<ScreenReducer.State>>>
  
  var body: some ReducerProtocol<CoordinatorReducer.State, CoordinatorReducer.Action> {
    CancelEffectsOnDismiss(
      coordinatedScreensReducer: EmptyReducer()
        .forEach(toLocalState, action: toLocalAction) {
          OnRoutes(wrapped: screenReducer)
        }
        .updatingScreensOnInteraction(
          updateRoutes: updateRoutes,
          toLocalState: toLocalState
        ),
      routes: { $0[keyPath: toLocalState] },
      routeAction: toLocalAction,
      coordinatorIdForCancellation: coordinatorIdForCancellation,
      getIdentifier: { element, _ in element.id },
      coordinatorReducer: coordinatorReducer
    )
  }
}

public extension ReducerProtocol {
  func forEachIdentifiedRoute<ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>(
    coordinatorIdForCancellation: CoordinatorID?,
    toLocalState: WritableKeyPath<Self.State, IdentifiedArrayOf<Route<ScreenReducer.State>>>,
    toLocalAction: CasePath<Self.Action, (ScreenReducer.State.ID, ScreenReducer.Action)>,
    updateRoutes: CasePath<Self.Action, IdentifiedArrayOf<Route<ScreenReducer.State>>>,
    @ReducerBuilderOf<ScreenReducer> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> where ScreenReducer.State: Identifiable {
    return ForEachIdentifiedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      coordinatorIdForCancellation: coordinatorIdForCancellation,
      toLocalState: toLocalState,
      toLocalAction: toLocalAction,
      updateRoutes: updateRoutes
    )
  }
}

public extension ReducerProtocol where State: IdentifiedRouterState, Action: IdentifiedRouterAction, State.Screen == Action.Screen {
  func forEachIdentifiedRoute<ScreenReducer: ReducerProtocol, CoordinatorID: Hashable>(
    coordinatorIdForCancellation: CoordinatorID?,
    @ReducerBuilderOf<ScreenReducer> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> where ScreenReducer.State: Identifiable, State.Screen == ScreenReducer.State, ScreenReducer.Action == Action.ScreenAction {
    return ForEachIdentifiedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      coordinatorIdForCancellation: coordinatorIdForCancellation,
      toLocalState: \.routes,
      toLocalAction: /Action.routeAction,
      updateRoutes: /Action.updateRoutes
    )
  }
  
  func forEachIdentifiedRoute<ScreenReducer: ReducerProtocol>(
    coordinatorIdType: Any.Type?,
    @ReducerBuilderOf<ScreenReducer> screenReducer: () -> ScreenReducer
  ) -> some ReducerProtocol<State, Action> where ScreenReducer.State: Identifiable, State.Screen == ScreenReducer.State, ScreenReducer.Action == Action.ScreenAction {
    return ForEachIdentifiedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      coordinatorIdForCancellation: coordinatorIdType.map(ObjectIdentifier.init),
      toLocalState: \.routes,
      toLocalAction: /Action.routeAction,
      updateRoutes: /Action.updateRoutes
    )
  }
}
