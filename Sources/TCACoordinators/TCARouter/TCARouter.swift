@_spi(Internals) import ComposableArchitecture
import FlowStacks
import SwiftUI

/// TCARouter manages a collection of Routes, i.e., a series of screens, each of which is either pushed or presented.
/// The TCARouter translates that collection into a hierarchy of SwiftUI views, and updates it when the user navigates back.
public struct TCARouter<
  Screen: Equatable,
  ScreenAction,
  ID: Hashable,
  ScreenContent: View
>: View {
  @Perception.Bindable private var store: Store<[Route<Screen>], RouterAction<ID, Screen, ScreenAction>>
  let identifier: (Screen, Int) -> ID
  let screenContent: (Store<Screen, ScreenAction>) -> ScreenContent

  public init(
    store: Store<[Route<Screen>], RouterAction<ID, Screen, ScreenAction>>,
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
    if Screen.self is ObservableState.Type {
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
    } else {
      UnobservedTCARouter(store: store, identifier: identifier, screenContent: screenContent)
    }
  }
}

private extension Store {
  subscript<ID: Hashable, Screen, ScreenAction>() -> [Route<Screen>]
    where State == [Route<Screen>], Action == RouterAction<ID, Screen, ScreenAction>
  {
    get { currentState }
    set {
      send(.updateRoutes(newValue))
    }
  }
}
