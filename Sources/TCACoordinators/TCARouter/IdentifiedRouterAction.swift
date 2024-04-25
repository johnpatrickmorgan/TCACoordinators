import ComposableArchitecture

public typealias IdentifiedRouterAction<Screen, ScreenAction> = RouterAction<Screen.ID, Screen, ScreenAction> where Screen: Identifiable

public typealias IdentifiedRouterActionOf<R: Reducer> = RouterAction<R.State.ID, R.State, R.Action> where R.State: Identifiable
