import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct IndexedCoordinatorView: View {
  let store: Store<IndexedCoordinator.State, IndexedCoordinator.Action>
  
  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
        CaseLet(
          state: /Screen.State.home,
          action: Screen.Action.home,
          then: HomeView.init
        )
        CaseLet(
          state: /Screen.State.numbersList,
          action: Screen.Action.numbersList,
          then: NumbersListView.init
        )
        CaseLet(
          state: /Screen.State.numberDetail,
          action: Screen.Action.numberDetail,
          then: NumberDetailView.init
        )
      }
    }
  }
}

struct IndexedCoordinator: ReducerProtocol {
  struct CancellationID {}
  
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
  
  var body: some ReducerProtocol<State, Action> {
    return Reduce<State, Action> { state, action in
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
    }.forEachRoute(cancellationIdType: CancellationID.self) {
      Screen()
    }
  }
}
