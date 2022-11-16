import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct LogInScreen: ReducerProtocol {
  enum Action {
    case welcome(Welcome.Action)
    case logIn(LogIn.Action)
  }

  enum State: Equatable, Identifiable {
    case welcome(Welcome.State)
    case logIn(LogIn.State)

    var id: UUID {
      switch self {
      case .welcome(let state):
        return state.id
      case .logIn(let state):
        return state.id
      }
    }
  }

  var body: some ReducerProtocol<State, Action> {
    EmptyReducer()
      .ifCaseLet(/State.welcome, action: /Action.welcome) {
        Welcome()
      }
      .ifCaseLet(/State.logIn, action: /Action.logIn) {
        LogIn()
      }
  }
}

struct LogInCoordinatorView: View {
  let store: Store<LogInCoordinator.State, LogInCoordinator.Action>

  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
        CaseLet(
          state: /LogInScreen.State.welcome,
          action: LogInScreen.Action.welcome,
          then: WelcomeView.init
        )
        CaseLet(
          state: /LogInScreen.State.logIn,
          action: LogInScreen.Action.logIn,
          then: LogInView.init
        )
      }
    }
  }
}

struct LogInCoordinator: ReducerProtocol {
  struct CancellationID {}
  struct State: Equatable, IdentifiedRouterState {
    static let initialState = LogInCoordinator.State(
      routes: [.root(.welcome(.init()), embedInNavigationView: true)]
    )
    var routes: IdentifiedArrayOf<Route<LogInScreen.State>>
  }

  enum Action: IdentifiedRouterAction {
    case routeAction(LogInScreen.State.ID, action: LogInScreen.Action)
    case updateRoutes(IdentifiedArrayOf<Route<LogInScreen.State>>)
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .routeAction(_, .welcome(.logInTapped)):
        state.routes.push(.logIn(.init()))

      default:
        break
      }
      return .none
    }.forEachIdentifiedRoute(coordinatorIdType: CancellationID.self) {
      LogInScreen()
    }
  }
}
