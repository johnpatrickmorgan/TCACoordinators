import ComposableArchitecture
import Foundation

struct ForEachIndexedRoute<
	CoordinatorReducer: Reducer,
	ScreenReducer: Reducer,
	CoordinatorID: Hashable
>: Reducer
where CoordinatorReducer.Action: CasePathable,
ScreenReducer.Action: CasePathable
{
	let coordinatorReducer: CoordinatorReducer
	let screenReducer: ScreenReducer
	let cancellationId: CoordinatorID?
	let toLocalState: WritableKeyPath<CoordinatorReducer.State, [Route<ScreenReducer.State>]>
	let toLocalAction: CaseKeyPath<CoordinatorReducer.Action, IndexedRouterAction<ScreenReducer.State, ScreenReducer.Action>>

	var body: some ReducerOf<CoordinatorReducer> {
		CancelEffectsOnDismiss(
			coordinatedScreensReducer: EmptyReducer()
				.forEachIndex(toLocalState, action: toLocalAction.appending(path: \.routeAction)) {
					OnRoutes(wrapped: screenReducer)
				}
				.updatingRoutesOnInteraction(
					updateRoutes: toLocalAction.appending(path: \.updateRoutes),
					toLocalState: toLocalState
				),
			routes: toLocalState,
			routeAction: toLocalAction.appending(path: \.routeAction),
			cancellationId: cancellationId,
			getIdentifier: { _, index in index },
			coordinatorReducer: coordinatorReducer
		)
	}
}

public extension Reducer {
	func forEachRoute<ScreenReducer: Reducer, ScreenState, ScreenAction, CoordinatorID: Hashable>(
    coordinatorIdForCancellation: CoordinatorID?,
    toLocalState: WritableKeyPath<Self.State, [Route<ScreenReducer.State>]>,
		toLocalAction: CaseKeyPath<Self.Action, IndexedRouterAction<ScreenReducer.State, ScreenReducer.Action>>,
    @ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
  ) -> some ReducerOf<Self>
	where Action: CasePathable,
				ScreenState == ScreenReducer.State,
        ScreenAction == ScreenReducer.Action,
				ScreenAction: CasePathable
  {
    ForEachIndexedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      cancellationId: coordinatorIdForCancellation,
      toLocalState: toLocalState,
			toLocalAction: toLocalAction
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
	func forEachRoute<ScreenReducer: Reducer, ScreenState, ScreenAction>(
		_ routes: WritableKeyPath<State, [Route<ScreenState>]>,
		action: CaseKeyPath<Action, IndexedRouterAction<ScreenState, ScreenAction>>,
		cancellationIdType: Any.Type = Self.self,
		@ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
	) -> some ReducerOf<Self>
	where Action: CasePathable,
				ScreenState == ScreenReducer.State,
				ScreenAction == ScreenReducer.Action,
				ScreenAction: CasePathable
	{
		ForEachIndexedRoute(
			coordinatorReducer: self,
			screenReducer: screenReducer(),
			cancellationId: ObjectIdentifier(cancellationIdType),
			toLocalState: routes,
			toLocalAction: action
		)
	}
}
