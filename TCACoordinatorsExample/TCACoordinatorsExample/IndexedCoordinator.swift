import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct IndexedCoordinatorView: View {
  let store: StoreOf<IndexedCoordinator>

  var body: some View {
    TCARouter(store) { screen in
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

struct IndexedCoordinator: Reducer {
  struct State: Equatable, IndexedRouterState {
    static let initialState = State(
      routes: [.root(.home(.init()), embedInNavigationView: true)]
    )

    var routes: [Route<Screen.State>]
  }

  enum Action: IndexedRouterAction {
    case routeAction(Int, action: Screen.Action)
    case updateRoutes([Route<Screen.State>])
  }

  var body: some ReducerOf<Self> {
    Reduce<State, Action> { state, action in
      switch action {
      case .routeAction(_, .home(.startTapped)):
        state.routes.presentSheet(.numbersList(.init(numbers: Array(0 ..< 4))), embedInNavigationView: true)

      case .routeAction(_, .numbersList(.numberSelected(let number))):
        state.routes.push(.numberDetail(.init(number: number)))

      case .routeAction(_, .numberDetail(.showDouble(let number))):
        state.routes.presentSheet(.numberDetail(.init(number: number * 2)))

      case .routeAction(_, .numberDetail(.goBackTapped)):
        state.routes.goBack()

      case .routeAction(_, .numberDetail(.goBackToNumbersList)):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBackTo(/Screen.State.numbersList)
        }

      case .routeAction(_, .numberDetail(.goBackToRootTapped)):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBackToRoot()
        }

      default:
        break
      }
      return .none
    }.forEachRoute {
      Screen()
    }
  }
}
