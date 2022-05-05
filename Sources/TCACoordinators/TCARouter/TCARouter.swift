import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

/// TCARouter manages a collection of Routes, i.e., a series of screens, each of which is either pushed or presented. The TCARouter translates that collection into a hierarchy of SwiftUI views, and ensures that `updateScreens`.
public struct TCARouter<
  CoordinatorState: Equatable,
  CoordinatorAction,
  Screen,
  ScreenAction,
  ID: Hashable,
  ScreenContent: View
>: View {
  let store: Store<CoordinatorState, CoordinatorAction>
  let routes: (CoordinatorState) -> [Route<Screen>]
  let updateRoutes: ([Route<Screen>]) -> CoordinatorAction
  let action: (ID, ScreenAction) -> CoordinatorAction
  let identifier: (Screen, Int) -> ID

  @ViewBuilder var screenContent: (Store<Screen, ScreenAction>) -> ScreenContent

  func scopedStore(id: ID, screen: Screen, index: Int) -> Store<Screen, ScreenAction> {
    store.scope(
      state: { routes($0)[index].screen },
      action: { action(id, $0) }
    )
  }

  public var body: some View {
    WithViewStore(store) { viewStore in
      Router(
        viewStore.binding(
          get: routes,
          send: updateRoutes
        ),
        buildView: { screen, index in
          let id = identifier(screen, index)
          screenContent(scopedStore(id: id, screen: screen, index: index))
        }
      )
    }
  }
}

extension TCARouter where Screen: Identifiable {

  /// Convenience initializer for managing screens in an `IdentifiedArray`.
  public init(
    store: Store<CoordinatorState, CoordinatorAction>,
    routes: @escaping (CoordinatorState) -> IdentifiedArrayOf<Route<Screen>>,
    updateRoutes: @escaping (IdentifiedArrayOf<Route<Screen>>) -> CoordinatorAction,
    action: @escaping (ID, ScreenAction) -> CoordinatorAction,
    screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
  ) where Screen.ID == ID {
    self.init(
      store: store,
      routes: { Array(routes($0)) },
      updateRoutes: { updateRoutes(IdentifiedArray(uniqueElements: $0)) },
      action: action,
      identifier: { state, _ in state.id },
      screenContent: screenContent
    )
  }
}

extension TCARouter where ID == Int {

  /// Convenience initializer for managing screens in an `Array`, identified by index.
  public init(
    store: Store<CoordinatorState, CoordinatorAction>,
    routes: @escaping (CoordinatorState) -> [Route<Screen>],
    updateRoutes: @escaping ([Route<Screen>]) -> CoordinatorAction,
    action: @escaping (Int, ScreenAction) -> CoordinatorAction,
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
