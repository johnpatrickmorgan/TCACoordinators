import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct IdentifiedCoordinatorView: View {
  @State var store: StoreOf<IdentifiedCoordinator>

  var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
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

extension Screen.State: Identifiable {
  var id: UUID {
    switch self {
    case let .home(state):
      return state.id
    case let .numbersList(state):
      return state.id
    case let .numberDetail(state):
      return state.id
    }
  }
}

@Reducer
struct IdentifiedCoordinator {
  enum Deeplink {
    case showNumber(Int)
  }

  @ObservableState
  struct State: Equatable {
    static let initialState = State(
      routes: [.root(.home(.init()), embedInNavigationView: true)]
    )

    var routes: IdentifiedArrayOf<Route<Screen.State>>
  }

  enum Action {
    case router(IdentifiedRouterActionOf<Screen>)
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
        return .routeWithDelaysIfUnsupported(state.routes, action: \.router, scheduler: .main) {
          $0.goBackTo(\.numbersList)
        }

      case .router(.routeAction(_, .numberDetail(.goBackToRootTapped))):
        return .routeWithDelaysIfUnsupported(state.routes, action: \.router, scheduler: .main) {
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
