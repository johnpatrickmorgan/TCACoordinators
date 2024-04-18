import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct IdentifiedCoordinatorView: View {
  let store: StoreOf<IdentifiedCoordinator>

  var body: some View {
		TCARouter(store, action: \.router) { screen in
      SwitchStore(screen) { screen in
        switch screen {
        case .home:
          CaseLet(
            /Screen.State.home,
             action: Screen.Action.home,
             then: HomeView.init
          )

        case .numbersList:
          CaseLet(
            /Screen.State.numbersList,
             action: Screen.Action.numbersList,
             then: NumbersListView.init
          )

        case .numberDetail:
          CaseLet(
            /Screen.State.numberDetail,
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

  struct State: Equatable, IdentifiedRouterState {
    static let initialState = State(
      routes: [.root(.home(.init()), embedInNavigationView: true)]
    )

    var routes: IdentifiedArrayOf<Route<Screen.State>>
  }

  enum Action {
		case router(IdentifiedRouterAction<Screen.State, Screen.Action>)
//    case routeAction(Screen.State.ID, action: Screen.Action)
//    case updateRoutes(IdentifiedArrayOf<Route<Screen.State>>)
  }

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
			case .router(.routeAction(.element(_, .home(.startTapped)))):
        state.routes.presentSheet(.numbersList(.init(numbers: Array(0 ..< 4))), embedInNavigationView: true)

			case .router(.routeAction(.element(_, .numbersList(.numberSelected(let number))))):
        state.routes.push(.numberDetail(.init(number: number)))

			case .router(.routeAction(.element(_, .numberDetail(.showDouble(let number))))):
        state.routes.presentSheet(.numberDetail(.init(number: number * 2)), embedInNavigationView: true)

			case .router(.routeAction(.element(_, .numberDetail(.goBackTapped)))):
        state.routes.goBack()

			case .router(.routeAction(.element(_, .numberDetail(.goBackToNumbersList)))):
				return .routeWithDelaysIfUnsupported(state.routes, action: \.router, scheduler: .main) {
          $0.goBackTo(/Screen.State.numbersList)
        }

			case .router(.routeAction(.element(_, .numberDetail(.goBackToRootTapped)))):
				return .routeWithDelaysIfUnsupported(state.routes, action: \.router, scheduler: .main) {
          $0.goBackToRoot()
        }

      default:
        break
      }
      return .none
		}
		.forEachRoute(action: \.router) {
      Screen()
    }
  }
}
