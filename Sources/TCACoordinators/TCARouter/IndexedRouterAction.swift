import ComposableArchitecture

/// A ``RouterAction`` that identifies screens by their index in the routes array.
public typealias IndexedRouterAction<Screen, ScreenAction> = RouterAction<Int, Screen, ScreenAction>

/// A ``RouterAction`` that identifies screens by their index in the routes array.
public typealias IndexedRouterActionOf<R: Reducer> = RouterAction<Int, R.State, R.Action>
