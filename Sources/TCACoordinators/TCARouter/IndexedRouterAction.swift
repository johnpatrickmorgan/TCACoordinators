import ComposableArchitecture

public typealias IndexedRouterAction<Screen, ScreenAction> = RouterAction<Int, Screen, ScreenAction>

public typealias IndexedRouterActionOf<R: Reducer> = RouterAction<Int, R.State, R.Action>
