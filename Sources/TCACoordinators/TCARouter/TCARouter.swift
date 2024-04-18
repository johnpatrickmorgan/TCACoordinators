import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

extension Binding where Value: Equatable {
	func removeDuplicates() -> Binding {
		Binding(
			get: { self.wrappedValue },
			set: { value in
				if self.wrappedValue != value {
					self.wrappedValue = value
				}
			}
		)
	}
}

/// TCARouter manages a collection of Routes, i.e., a series of screens, each of which is either pushed or presented. The TCARouter translates that collection into a hierarchy of SwiftUI views, and ensures that `updateScreens`.
public struct TCARouter<
  CoordinatorState: Equatable,
	CoordinatorAction,
	Screen: Equatable,
  ScreenAction,
  ID: Hashable,
  ScreenContent: View
>: View {
  let store: Store<CoordinatorState, CoordinatorAction>
  let routes: KeyPath<CoordinatorState, [Route<Screen>]>
  let updateRoutes: CaseKeyPath<CoordinatorAction, [Route<Screen>]>
	let action: CaseKeyPath<CoordinatorAction, IdentifiedAction<ID, ScreenAction>>
  let identifier: (Screen, Int) -> ID

  @ObservedObject private var viewStore: ViewStore<CoordinatorState, CoordinatorAction>
  @ViewBuilder var screenContent: (Store<Screen, ScreenAction>) -> ScreenContent

  func scopedStore(index: Int, screen: Screen) -> Store<Screen?, ScreenAction> {
		let id = identifier(screen, index)
		return store.scope(
			state: routes.appending(path: \.[safe: index]?.screen),
			action: action.appending(path: \.[id: id])
		)
  }

  public var body: some View {
    Router(
			ViewStore(store, observe: { $0 })
				.binding(
					get: { $0[keyPath: routes] },
					send: updateRoutes.callAsFunction
				)
				.removeDuplicates(),
			buildView: { screen, index in
				IfLetStore(scopedStore(index: index, screen: screen)) { store in
					screenContent(store)
				}
      }
    )
  }

  public init(
    store: Store<CoordinatorState, CoordinatorAction>,
    routes: KeyPath<CoordinatorState, [Route<Screen>]>,
    updateRoutes: CaseKeyPath<CoordinatorAction, [Route<Screen>]>,
		action: CaseKeyPath<CoordinatorAction, IdentifiedAction<ID, ScreenAction>>,
    identifier: @escaping (Screen, Int) -> ID,
    screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
  ) {
    self.store = store
    self.routes = routes
    self.updateRoutes = updateRoutes
    self.action = action
    self.identifier = identifier
    self.screenContent = screenContent
    self.viewStore = ViewStore(
			store,
			observe: { $0 },
			removeDuplicates: {
				$0[keyPath: routes].map(\.style) == $1[keyPath: routes].map(\.style)
			}
		)
  }
}

public extension TCARouter where Screen: Identifiable {
  /// Convenience initializer for managing screens in an `IdentifiedArray`.
  init(
    store: Store<CoordinatorState, CoordinatorAction>,
		routes: KeyPath<CoordinatorState, IdentifiedArrayOf<Route<Screen>>>,
    updateRoutes: CaseKeyPath<CoordinatorAction, IdentifiedArrayOf<Route<Screen>>>,
		action: CaseKeyPath<CoordinatorAction, IdentifiedAction<ID, ScreenAction>>,
    screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
  ) where Screen.ID == ID {
    self.init(
      store: store,
			routes: routes.appending(path: \.elements),
			updateRoutes: updateRoutes.appending(path: \.[id: \.id]),
      action: action,
      identifier: { state, _ in state.id },
      screenContent: screenContent
    )
  }
}

public extension TCARouter where ID == Int {
  /// Convenience initializer for managing screens in an `Array`, identified by index.
  init(
    store: Store<CoordinatorState, CoordinatorAction>,
    routes: KeyPath<CoordinatorState, [Route<Screen>]>,
    updateRoutes: CaseKeyPath<CoordinatorAction, [Route<Screen>]>,
		action: CaseKeyPath<CoordinatorAction, IdentifiedAction<Int, ScreenAction>>,
    screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
  ) {
    self.init(
      store: store,
      routes: routes,
      updateRoutes: updateRoutes,
      action: action,
      identifier: { $1 },
      screenContent: screenContent
    )
  }
}

extension Route: Identifiable where Screen: Identifiable {
  public var id: Screen.ID { screen.id }
}

extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}

extension Case {
	func bimap<Output>(
		transform: @escaping (Value) -> Output,
		revert: @escaping (Output) -> Value
	) -> Case<Output> {
		Case<Output>(
			embed: { self.embed(revert($0)) },
			extract: {
				self.extract(from: $0).flatMap(transform)
			}
		)
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

	public subscript<ID, Element>(id id: KeyPath<Element, ID>) -> Case<[Element]> where Value == IdentifiedArray<ID, Element> {
		self.bimap(
			transform: \.elements,
			revert: { IdentifiedArray(uniqueElements: $0, id: id) }
		)
	}

//	func asArray<Element>() -> Case<[Element]> where Value == IdentifiedArrayOf<Element> {
//		Case<[Element]>(
//			embed: { value in value },
//			extract: { value in value }
//		)
//	}

//	fileprivate subscript<Element>() -> Case<[Element]>
//	where Value == IdentifiedArrayOf<Element> {
//		Case<[Element]>(
//			embed: { value in
//				dump(value, name: "Received!")
//				return IdentifiedArray(uniqueElements: value)
//			},
//			extract: { root in root.elements }
//		)
//	}
}
