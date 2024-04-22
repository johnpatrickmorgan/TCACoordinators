@_spi(Internals) import ComposableArchitecture
import FlowStacks
import SwiftUI

public struct ObservedTCARouter<
	Screen: Equatable & ObservableState,
	ScreenAction,
	ID: Hashable,
	ScreenContent: View
>: View {
	@Perception.Bindable private var store: Store<[Route<Screen>], RouterAction<Screen, ID, ScreenAction>>
	let identifier: (Screen, Int) -> ID
	let screenContent: (Store<Screen, ScreenAction>) -> ScreenContent

	public init(
		store: Store<[Route<Screen>], RouterAction<Screen, ID, ScreenAction>>,
		identifier: @escaping (Screen, Int) -> ID,
		@ViewBuilder screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
	) {
		self.store = store
		self.identifier = identifier
		self.screenContent = screenContent
	}

	func scopedStore(index: Int, screen: Screen) -> Store<Screen, ScreenAction> {
		var screen = screen
		let id = identifier(screen, index)
		return store.scope(
			id: store.id(state: \.[index], action: \.[id: id]),
			state: ToState {
				screen = $0[safe: index]?.screen ?? screen
				return screen
			},
			action: {
				.routeAction(id: id, action: $0)
			},
			isInvalid: { !$0.indices.contains(index) }
		)
	}

	public var body: some View {
		WithPerceptionTracking {
			Router(
				$store[],
				buildView: { screen, index in
					WithPerceptionTracking {
						screenContent(scopedStore(index: index, screen: screen))
					}
				}
			)
		}
	}
}

extension Store {
	fileprivate subscript<Screen, ID: Hashable, ScreenAction>() -> [Route<Screen>]
	where State == [Route<Screen>], Action == RouterAction<Screen, ID, ScreenAction> {
		get { self.currentState }
		set {
			self.send(.updateRoutes(newValue))
		}
	}
}
