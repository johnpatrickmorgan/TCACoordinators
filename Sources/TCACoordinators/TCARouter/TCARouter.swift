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
        if let firstRoute = store.currentState.first {
          FlowStack($store[firstRoute: firstRoute], withNavigation: firstRoute.withNavigation) {
            WithPerceptionTracking {
              screenContent(scopedStore(index: 0, screen: firstRoute.screen))
                .flowDestination(for: Screen.self) { screen, index in
                  WithPerceptionTracking {
                    screenContent(scopedStore(index: index + 1, screen: screen))
                  }
                }
            }
          }
        }
      }
    } else {
      UnobservedTCARouter(store: store, identifier: identifier, screenContent: screenContent)
    }
  }
}

private extension Store {
  subscript<ID: Hashable, Screen, ScreenAction>(firstRoute firstRoute: Route<Screen>) -> [Route<Screen>]
    where State == [Route<Screen>], Action == RouterAction<ID, Screen, ScreenAction>
  {
    get { Array(currentState.dropFirst()) }
    set {
      send(.updateRoutes([firstRoute] + newValue))
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

private struct IndexedFlowDestination<D: Hashable, Destination: View>: View {
  var data: D
  var builder: (D, Int) -> Destination
  @Environment(\.routeIndex) var routeIndex

  var body: some View {
    builder(data, routeIndex ?? -1)
  }
}

extension View {
  /// Allows an index to be passed to the destination builder closure.
  func flowDestination<D: Hashable>(for dataType: D.Type, @ViewBuilder destination builder: @escaping (D, Int) -> some View) -> some View {
    flowDestination(for: dataType) { data in
      IndexedFlowDestination(data: data, builder: builder)
    }
  }
}
