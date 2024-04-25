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

extension Collection {
  /// Returns the element at the specified index if it is within bounds, otherwise nil.
  subscript(safe index: Index) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
