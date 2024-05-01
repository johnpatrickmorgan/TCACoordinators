import ComposableArchitecture

/// A ``RouterAction`` that identifies Identifiable screens by their identity.
public typealias IdentifiedRouterAction<Screen, ScreenAction> = RouterAction<Screen.ID, Screen, ScreenAction> where Screen: Identifiable

/// A ``RouterAction`` that identifies Identifiable screens by their identity.
public typealias IdentifiedRouterActionOf<R: Reducer> = RouterAction<R.State.ID, R.State, R.Action> where R.State: Identifiable
