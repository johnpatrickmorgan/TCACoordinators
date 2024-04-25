import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct IdentifiedCoordinatorView: View {
  let store: StoreOf<IdentifiedCoordinator>

  var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      SwitchStore(screen) { screen in
        switch screen {
        case .home:
          CaseLet(
            \Screen.State.home,
            action: Screen.Action.home,
            then: HomeView.init
          )

        case .numbersList:
          CaseLet(
            \Screen.State.numbersList,
            action: Screen.Action.numbersList,
            then: NumbersListView.init
          )

        case .numberDetail:
          CaseLet(
            \Screen.State.numberDetail,
            action: Screen.Action.numberDetail,
            then: NumberDetailView.init
          )
        }
      }
    }
  }
}

@Reducer
struct IdentifiedCoordinator: Reducer {
  enum Deeplink {
    case showNumber(Int)
  }

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
    .forEachRoute(\.routes, action: \.router) {
      Screen()
    }
  }
}
