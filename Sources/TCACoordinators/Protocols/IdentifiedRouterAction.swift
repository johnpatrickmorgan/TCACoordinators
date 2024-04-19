public typealias IdentifiedRouterAction<Screen, ScreenAction> = RouterAction<Screen, Screen.ID, ScreenAction> where Screen: Identifiable
