import SwiftUI
import ComposableArchitecture
import TCACoordinators

struct IndexedCoordinatorView: View {

  let store: Store<IndexedCoordinatorState, IndexedCoordinatorAction>

  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
        CaseLet(
          state: /ScreenState.home,
          action: ScreenAction.home,
          then: HomeView.init
        )
        CaseLet(
          state: /ScreenState.numbersList,
          action: ScreenAction.numbersList,
          then: NumbersListView.init
        )
        CaseLet(
          state: /ScreenState.numberDetail,
          action: ScreenAction.numberDetail,
          then: NumberDetailView.init
        )
      }
    }
  }
}

enum IndexedCoordinatorAction: IndexedRouterAction {

  case routeAction(Int, action: ScreenAction)
  case updateRoutes([Route<ScreenState>])
}

struct IndexedCoordinatorState: Equatable, IndexedRouterState {

  static let initialState = IndexedCoordinatorState(
    routes: [.root(.home(.init()), embedInNavigationView: true)]
  )

  var routes: [Route<ScreenState>]
}

struct IndexedCoordinatorEnvironment {}

typealias IndexedCoordinatorReducer = Reducer<
  IndexedCoordinatorState, IndexedCoordinatorAction, IndexedCoordinatorEnvironment
>

let indexedCoordinatorReducer: IndexedCoordinatorReducer = screenReducer
  .forEachIndexedRoute(environment: { _ in ScreenEnvironment() })
  .withRouteReducer(
    Reducer { state, action, environment in
      switch action {
      case .routeAction(_, .home(.startTapped)):
        state.routes.push(.numbersList(.init(numbers: Array(0..<4))))

      case .routeAction(_, .numbersList(.numberSelected(let number))):
        state.routes.push(.numberDetail(.init(number: number)))

      case .routeAction(_, .numberDetail(.showDouble(let number))):
        state.routes.presentSheet(.numberDetail(.init(number: number * 2)))

      case .routeAction(_, .numberDetail(.goBackTapped)):
        state.routes.dismiss()

      case .routeAction(_, .numberDetail(.goBackToNumbersList)):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBackTo(/ScreenState.numbersList)
        }

      case .routeAction(_, .numberDetail(.goBackToRootTapped)):
        return .routeWithDelaysIfUnsupported(state.routes) {
          $0.goBackToRoot()
        }

      default:
        break
      }
      return .none
    }
  )
