import ComposableArchitecture
import FlowStacks

@CasePathable
public enum RouterAction<Screen, ID: Hashable, ScreenAction> {
	case updateRoutes(_ routes: [Route<Screen>])
	case routeAction(IdentifiedAction<ID, ScreenAction>)
}
