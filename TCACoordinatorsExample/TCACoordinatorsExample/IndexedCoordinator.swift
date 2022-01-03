import SwiftUI
import ComposableArchitecture
import TCACoordinators
import FlowStacks

struct IndexedNavCoordinatorView: View {

  let store: Store<IndexedNavCoordinatorState, IndexedNavCoordinatorAction>

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

enum IndexedNavCoordinatorAction: IndexedRouterAction {

  case routeAction(Int, action: ScreenAction)
  case updateRoutes([Route<ScreenState>])
}

struct IndexedNavCoordinatorState: Equatable, IndexedRouterState {

  static let initialState = IndexedNavCoordinatorState(
    routes: [.root(.home(.init()), embedInNavigationView: true)]
  )

  var routes: [Route<ScreenState>]
}

struct IndexedNavCoordinatorEnvironment {}

typealias IndexedNavCoordinatorReducer = Reducer<
  IndexedNavCoordinatorState, IndexedNavCoordinatorAction, IndexedNavCoordinatorEnvironment
>

let indexedNavCoordinatorReducer: IndexedNavCoordinatorReducer = screenReducer
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
