@_spi(Internals) import ComposableArchitecture
import FlowStacks
import SwiftUI

/// TCARouter manages a collection of Routes, i.e., a series of screens, each of which is either pushed or presented.
/// The TCARouter translates that collection into a hierarchy of SwiftUI views, and updates it when the user navigates back.
public struct TCARouter<
  Screen: Hashable,
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

  private func scopedStore(index: Int, screen: Screen) -> Store<Screen, ScreenAction> {
    store.scope(
      state: \.[index, defaultingTo: screen],
      action: \.[id: identifier(screen, index)]
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

  subscript<ID: Hashable, Screen, ScreenAction>(index: Int, defaultingTo defaultScreen: Screen) -> Screen
    where State == [Route<Screen>], Action == RouterAction<ID, Screen, ScreenAction>
  {
    guard currentState.indices.contains(index) else { return defaultScreen }
    return currentState[index].screen
  }
}

extension Array where Element: RouteProtocol {
  subscript(index: Int, defaultingTo defaultScreen: Element.Screen) -> Element.Screen {
    guard indices.contains(index) else { return defaultScreen }
    return self[index].screen
  }
}
