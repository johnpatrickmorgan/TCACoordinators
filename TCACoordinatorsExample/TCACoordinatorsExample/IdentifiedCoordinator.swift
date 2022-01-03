import SwiftUI
import ComposableArchitecture
import TCACoordinators
import FlowStacks

struct IdentifiedCoordinatorView: View {
  
  let store: Store<IdentifiedCoordinatorState, IdentifiedCoordinatorAction>
  
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

struct IdentifiedCoordinatorState: Equatable, IdentifiedRouterState {
  
  static let initialState = IdentifiedCoordinatorState(
    routes: [.root(.home(.init()), embedInNavigationView: true)]
  )
  
  var routes: IdentifiedArrayOf<Route<ScreenState>>
}

enum IdentifiedCoordinatorAction: IdentifiedRouterAction {
  
  case routeAction(ScreenState.ID, action: ScreenAction)
  case updateRoutes(IdentifiedArrayOf<Route<ScreenState>>)
}

struct IdentifiedCoordinatorEnvironment {}

typealias IdentifiedCoordinatorReducer = Reducer<
  IdentifiedCoordinatorState, IdentifiedCoordinatorAction, IdentifiedCoordinatorEnvironment
>

let identifiedCoordinatorReducer: IdentifiedCoordinatorReducer = screenReducer
  .forEachIdentifiedRoute(environment: { _ in .init() })
  .withRouteReducer(Reducer { state, action, environment in
      switch action {
      case .routeAction(_, .home(.startTapped)):
        state.routes.presentSheet(.numbersList(.init(numbers: Array(0..<4))), embedInNavigationView: true)

      case .routeAction(_, .numbersList(.numberSelected(let number))):
        state.routes.push(.numberDetail(.init(number: number)))

      case .routeAction(_, .numberDetail(.showDouble(let number))):
        state.routes.presentSheet(.numberDetail(.init(number: number * 2)))

      case .routeAction(_, .numberDetail(.goBackTapped)):
        state.routes.goBack()

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
