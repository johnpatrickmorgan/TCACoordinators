import CasePaths
import ComposableArchitecture
import FlowStacks
import Foundation

@CasePathable
public enum IndexedRouterAction<Screen, ScreenAction> {
	/// An action that allows routes to be updated whenever the user navigates back.
	case updateRoutes(_ routes: [Route<Screen>])

	/// An action that allows the action for a specific screen to be dispatched to that screen's reducer.
	case routeAction(IdentifiedAction<Int, ScreenAction>)
}
