@_spi(Internals) import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

/// TCARouter manages a collection of Routes, i.e., a series of screens, each of which is either pushed or presented. The TCARouter translates that collection into a hierarchy of SwiftUI views, and ensures that `updateScreens`.
public struct TCARouter<
	Screen: Equatable,
	ScreenAction,
	ID: Hashable,
	ScreenContent: View
>: View {
	let store: Store<[Route<Screen>], RouterAction<Screen, ID, ScreenAction>>
	let identifier: (Screen, Int) -> ID
	let screenContent: (Store<Screen, ScreenAction>) -> ScreenContent
	@ObservedObject private var viewStore: ViewStore<[Route<Screen>], RouterAction<Screen, ID, ScreenAction>>

	public init(
		store: Store<[Route<Screen>], RouterAction<Screen, ID, ScreenAction>>,
		identifier: @escaping (Screen, Int) -> ID,
		@ViewBuilder screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
	) {
		self.store = store
		self.identifier = identifier
		self.screenContent = screenContent
		self.viewStore = ViewStore(
			store,
			observe: { $0 },
			removeDuplicates: {
				$0.map(\.style) == $1.map(\.style)
			}
		)
	}

	func scopedStore(index: Int, screen: Screen) -> Store<Screen, ScreenAction> {
		var screen = screen
		let id = identifier(screen, index)
		return store.scope(
			id: store.id(state: \.[index], action: \.routeAction[id: id]),
			state: ToState {
				screen = $0[safe: index]?.screen ?? screen
				return screen
			},
			action: {
				.routeAction(.element(id: id, action: $0))
			},
			isInvalid: { !$0.indices.contains(index) }
		)
	}

	public var body: some View {
		Router(
			ViewStore(store, observe: { $0 })
				.binding(
					get: { $0 },
					send: RouterAction.updateRoutes
				),
			buildView: { screen, index in
				screenContent(scopedStore(index: index, screen: screen))
			}
		)
	}
}

extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

extension Case {
	fileprivate subscript<ID: Hashable, Action>(id id: ID) -> Case<Action>
	where Value == (ID, action: Action) {
		Case<Action>(
			embed: { (id: id, action: $0) },
			extract: { $0.0 == id ? $0.1 : nil }
		)
	}
}
