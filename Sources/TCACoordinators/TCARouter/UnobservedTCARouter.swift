@_spi(Internals) import ComposableArchitecture
import FlowStacks
import Foundation
import SwiftUI

/// UnobservedTCARouter manages a collection of Routes, i.e., a series of screens, each of which is either pushed or presented.
/// The TCARouter translates that collection into a hierarchy of SwiftUI views, and updates it when the user navigates back.
/// The unobserved router is used when the Screen does not conform to ObservableState.
struct UnobservedTCARouter<
  Screen: Hashable,
  ScreenAction,
  ID: Hashable,
  ScreenContent: View
>: View {
  let store: Store<[Route<Screen>], RouterAction<ID, Screen, ScreenAction>>
  let identifier: (Screen, Int) -> ID
  let screenContent: (Store<Screen, ScreenAction>) -> ScreenContent

  init(
    store: Store<[Route<Screen>], RouterAction<ID, Screen, ScreenAction>>,
    identifier: @escaping (Screen, Int) -> ID,
    @ViewBuilder screenContent: @escaping (Store<Screen, ScreenAction>) -> ScreenContent
  ) {
    self.store = store
    self.identifier = identifier
    self.screenContent = screenContent
  }

  func scopedStore(index: Int, screen: Screen) -> Store<Screen, ScreenAction> {
    store.scope(
      state: \.[index, defaultingTo: screen],
      action: \.[id: identifier(screen, index)]
    )
  }

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Router(
        viewStore
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
}
