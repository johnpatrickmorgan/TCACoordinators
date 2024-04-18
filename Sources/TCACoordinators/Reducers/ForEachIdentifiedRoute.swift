import ComposableArchitecture
import Foundation

struct ForEachIdentifiedRoute<
	CoordinatorReducer: Reducer,
	ScreenReducer: Reducer,
	CoordinatorID: Hashable
>: Reducer
where ScreenReducer.State: Identifiable,
			CoordinatorReducer.Action: CasePathable,
			ScreenReducer.Action: CasePathable
{
  let coordinatorReducer: CoordinatorReducer
  let screenReducer: ScreenReducer
  let cancellationId: CoordinatorID?
  let toLocalState: WritableKeyPath<CoordinatorReducer.State, IdentifiedArrayOf<Route<ScreenReducer.State>>>
	let toLocalAction: CaseKeyPath<CoordinatorReducer.Action, IdentifiedRouterAction<ScreenReducer.State, ScreenReducer.Action>>

  var body: some ReducerOf<CoordinatorReducer> {
    CancelEffectsOnDismiss(
      coordinatedScreensReducer: EmptyReducer()
				.forEach(toLocalState, action: toLocalAction.appending(path: \.routeAction)) {
          OnRoutes(wrapped: screenReducer)
        }
        .updatingRoutesOnInteraction(
					updateRoutes: toLocalAction.appending(path: \.updateRoutes),
          toLocalState: toLocalState
        ),
			routes: toLocalState,
			routeAction: toLocalAction.appending(path: \.routeAction),
      cancellationId: cancellationId,
      getIdentifier: { element, _ in element.id },
      coordinatorReducer: coordinatorReducer
    )
  }
}

public extension Reducer {
  func forEachRoute<ScreenReducer: Reducer, ScreenState, ScreenAction, CoordinatorID: Hashable>(
    cancellationId: CoordinatorID?,
    toLocalState: WritableKeyPath<Self.State, IdentifiedArrayOf<Route<ScreenReducer.State>>>,
		toLocalAction: CaseKeyPath<Self.Action, IdentifiedRouterAction<ScreenReducer.State, ScreenReducer.Action>>,
    updateRoutes: CaseKeyPath<Self.Action, IdentifiedArrayOf<Route<ScreenReducer.State>>>,
    @ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
  ) -> some ReducerOf<Self>
	where Action: CasePathable,
				ScreenReducer.State: Identifiable,
        ScreenState == ScreenReducer.State,
        ScreenAction == ScreenReducer.Action,
				ScreenAction: CasePathable
  {
    ForEachIdentifiedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      cancellationId: cancellationId,
      toLocalState: toLocalState,
      toLocalAction: toLocalAction
    )
  }
}

public extension Reducer where State: IdentifiedRouterState {
	func forEachRoute<ScreenReducer: Reducer, ScreenState: Identifiable, ScreenAction: CasePathable, CoordinatorID: Hashable>(
		_ state: WritableKeyPath<State, IdentifiedArrayOf<Route<ScreenState>>>,
		action: CaseKeyPath<Action, IdentifiedRouterAction<ScreenState, ScreenAction>>,
		cancellationId: CoordinatorID?,
		@ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
	) -> some ReducerOf<Self>
	where ScreenReducer.State: Identifiable,
				State.Screen == ScreenReducer.State,
				Action: CasePathable,
				ScreenState == ScreenReducer.State,
				ScreenAction == ScreenReducer.Action
	{
		ForEachIdentifiedRoute(
			coordinatorReducer: self,
			screenReducer: screenReducer(),
			cancellationId: cancellationId,
			toLocalState: state,
			toLocalAction: action
		)
	}

	/// Allows a screen reducer to be incorporated into a coordinator reducer, such that each screen in
	/// the coordinator's routes IdentifiedArray will have its actions and state propagated. When screens are
	/// dismissed, the routes will be updated. If a cancellation identifier is passed, in-flight effects
	/// will be cancelled when the screen from which they originated is dismissed.
	/// - Parameters:
	///   - cancellationIdType: A type to use for cancelling in-flight effects when a view is dismissed. It
	///   will be combined with the screen's identifier. Defaults to the type of the parent reducer.
	///   - screenReducer: The reducer that operates on all of the individual screens.
	/// - Returns: A new reducer combining the coordinator-level and screen-level reducers.
	func forEachRoute<ScreenReducer: Reducer, ScreenState, ScreenAction>(
		cancellationIdType: Any.Type = Self.self,
		action: CaseKeyPath<Action, IdentifiedRouterAction<ScreenState, ScreenAction>>,
		@ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
	) -> some ReducerOf<Self>
	where ScreenReducer.State: Identifiable,
				State.Screen == ScreenReducer.State,
				Action: CasePathable,
				ScreenState == ScreenReducer.State,
				ScreenAction == ScreenReducer.Action,
				ScreenAction: CasePathable
	{
		ForEachIdentifiedRoute(
			coordinatorReducer: self,
			screenReducer: screenReducer(),
			cancellationId: ObjectIdentifier(cancellationIdType),
			toLocalState: \.routes,
			toLocalAction: action
		)
	}
}

