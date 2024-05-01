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
  let toLocalAction: CaseKeyPath<CoordinatorReducer.Action, IdentifiedRouterActionOf<ScreenReducer>>

  var body: some ReducerOf<CoordinatorReducer> {
    CancelEffectsOnDismiss(
      coordinatedScreensReducer: EmptyReducer()
        .forEach(toLocalState, action: toLocalAction.appending(path: \.routeAction).appending(path: \.[])) {
          OnRoutes(wrapped: screenReducer)
        }
        .updatingRoutesOnInteraction(
          updateRoutes: toLocalAction.appending(path: \.updateRoutes).appending(path: \.[]),
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
  /// Allows a screen reducer to be incorporated into a coordinator reducer, such that each screen in
  /// the coordinator's routes IdentifiedArray will have its actions and state propagated. When screens are
  /// dismissed, the routes will be updated. If a cancellation identifier is passed, in-flight effects
  /// will be cancelled when the screen from which they originated is dismissed.
  /// - Parameters:
  ///   - routes: A writable keypath for the routes `IdentifiedArray`.
  ///   - action: A casepath for the router action from this reducer's Action type.
  ///   - cancellationId: An identifier to use for cancelling in-flight effects when a view is dismissed. It
  ///   will be combined with the screen's identifier. If `nil`, there will be no automatic cancellation.
  ///   - screenReducer: The reducer that operates on all of the individual screens.
  /// - Returns: A new reducer combining the coordinator-level and screen-level reducers.
  func forEachRoute<ScreenReducer: Reducer, ScreenState, ScreenAction>(
    _ routes: WritableKeyPath<State, IdentifiedArrayOf<Route<ScreenState>>>,
    action: CaseKeyPath<Action, IdentifiedRouterAction<ScreenState, ScreenAction>>,
    cancellationId: (some Hashable)?,
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
      toLocalState: routes,
      toLocalAction: action
    )
  }

  func forEachRoute<ScreenState, ScreenAction>(
    cancellationId: (some Hashable)?,
    _ routes: WritableKeyPath<Self.State, IdentifiedArrayOf<Route<ScreenState>>>,
    action: CaseKeyPath<Self.Action, IdentifiedRouterAction<ScreenState, ScreenAction>>
  ) -> some ReducerOf<Self>
    where Action: CasePathable,
    ScreenState: CaseReducerState,
    ScreenState.StateReducer.Action == ScreenAction,
    ScreenAction: CasePathable
  {
    self.forEachRoute(
      routes,
      action: action,
      cancellationId: cancellationId
    ) {
      ScreenState.StateReducer.body
    }
  }

  /// Allows a screen reducer to be incorporated into a coordinator reducer, such that each screen in
  /// the coordinator's routes IdentifiedArray will have its actions and state propagated. When screens are
  /// dismissed, the routes will be updated. If a cancellation identifier is passed, in-flight effects
  /// will be cancelled when the screen from which they originated is dismissed.
  /// - Parameters:
  ///   - routes: A writable keypath for the routes `IdentifiedArray`.
  ///   - action: A casepath for the router action from this reducer's Action type.
  ///   - cancellationIdType: A type to use for cancelling in-flight effects when a view is dismissed. It
  ///   will be combined with the screen's identifier. Defaults to the type of the parent reducer.
  ///   - screenReducer: The reducer that operates on all of the individual screens.
  /// - Returns: A new reducer combining the coordinator-level and screen-level reducers.
  func forEachRoute<ScreenReducer: Reducer, ScreenState, ScreenAction>(
    _ routes: WritableKeyPath<State, IdentifiedArrayOf<Route<ScreenState>>>,
    action: CaseKeyPath<Action, IdentifiedRouterAction<ScreenState, ScreenAction>>,
    cancellationIdType: Any.Type = Self.self,
    @ReducerBuilder<ScreenState, ScreenAction> screenReducer: () -> ScreenReducer
  ) -> some ReducerOf<Self>
    where ScreenReducer.State: Identifiable,
    Action: CasePathable,
    ScreenState == ScreenReducer.State,
    ScreenAction == ScreenReducer.Action,
    ScreenAction: CasePathable
  {
    ForEachIdentifiedRoute(
      coordinatorReducer: self,
      screenReducer: screenReducer(),
      cancellationId: ObjectIdentifier(cancellationIdType),
      toLocalState: routes,
      toLocalAction: action
    )
  }

  func forEachRoute<ScreenState, ScreenAction>(
    _ routes: WritableKeyPath<State, IdentifiedArrayOf<Route<ScreenState>>>,
    action: CaseKeyPath<Action, IdentifiedRouterAction<ScreenState, ScreenAction>>,
    cancellationIdType: Any.Type = Self.self
  ) -> some ReducerOf<Self>
    where Action: CasePathable,
    ScreenState: CaseReducerState,
    ScreenState: Identifiable,
    ScreenState.StateReducer.Action == ScreenAction,
    ScreenAction: CasePathable
  {
    self.forEachRoute(routes, action: action, cancellationIdType: cancellationIdType) {
      ScreenState.StateReducer.body
    }
  }
}

extension Case {
  subscript<Element: Identifiable>() -> Case<IdentifiedArray<Element.ID, Element>> where Value == [Element] {
    Case<IdentifiedArrayOf<Element>>(
      embed: { self.embed($0.elements) },
      extract: {
        self.extract(from: $0).flatMap { IdentifiedArrayOf(uniqueElements: $0) }
      }
    )
  }

  fileprivate subscript<ID: Hashable, Action>() -> Case<IdentifiedAction<ID, Action>> where Value == (id: ID, action: Action) {
    Case<IdentifiedAction<ID, Action>>(
      embed: { action in
        switch action {
        case let .element(id, action):
          self.embed((id, action))
        }
      },
      extract: {
        self.extract(from: $0).flatMap {
          .element(id: $0, action: $1)
        }
      }
    )
  }
}
