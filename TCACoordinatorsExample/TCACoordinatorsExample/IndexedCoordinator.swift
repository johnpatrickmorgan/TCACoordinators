import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct IndexedCoordinatorView: View {
  @State var store: StoreOf<IndexedCoordinator>

  var body: some View {
    ObservedTCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .home(store):
        HomeView(store: store)

      case let .numbersList(store):
        NumbersListView(store: store)

      case let .numberDetail(store):
        NumberDetailView(store: store)
      }
    }
  }
}

@Reducer
struct IndexedCoordinator {
  @ObservableState
  struct State: Equatable {
    static let initialState = State(
      routes: [.root(.home(.init()), embedInNavigationView: true)]
    )

    var routes: [Route<Screen.State>]
  }

  enum Action {
    case router(IndexedRouterActionOf<Screen>)
  }

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
      case .router(.routeAction(_, .home(.startTapped))):
        state.routes.presentSheet(.numbersList(.init(numbers: Array(0 ..< 4))), embedInNavigationView: true)

      case let .router(.routeAction(_, .numbersList(.numberSelected(number)))):
        state.routes.push(.numberDetail(.init(number: number)))

      case let .router(.routeAction(_, .numberDetail(.showDouble(number)))):
        state.routes.presentSheet(.numberDetail(.init(number: number * 2)), embedInNavigationView: true)

      case .router(.routeAction(_, .numberDetail(.goBackTapped))):
        state.routes.goBack()

      case .router(.routeAction(_, .numberDetail(.goBackToNumbersList))):
        return .routeWithDelaysIfUnsupported(state.routes, action: \.router) {
          $0.goBackTo(\.numbersList)
        }

      case .router(.routeAction(_, .numberDetail(.goBackToRootTapped))):
        return .routeWithDelaysIfUnsupported(state.routes, action: \.router) {
          $0.goBackToRoot()
        }

      default:
        break
      }
      return .none
    }
    .forEachRoute(\.routes, action: \.router)
  }
}
