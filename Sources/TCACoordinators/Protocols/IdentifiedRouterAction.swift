import CasePaths
import ComposableArchitecture
import FlowStacks
import Foundation

@CasePathable
public enum IdentifiedRouterAction<Screen: Identifiable, ScreenAction> {
	/// An action that allows routes to be updated whenever the user navigates back.
	case updateRoutes(_ routes: IdentifiedArrayOf<Route<Screen>>)

	/// An action that allows a child action for a specific screen to be dispatched to that screen's reducer
	case routeAction(IdentifiedAction<Screen.ID, ScreenAction>)
}
