import ComposableArchitecture
import SwiftUI
import TCACoordinators

@Reducer
struct LogInScreen {
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

  var body: some ReducerOf<Self> {
    Scope(state: /State.welcome, action: /Action.welcome) {
      Welcome()
    }
    Scope(state: /State.logIn, action: /Action.logIn) {
      LogIn()
    }
  }
}

struct LogInCoordinatorView: View {
  let store: StoreOf<LogInCoordinator>

  var body: some View {
		TCARouter(store, action: \.router) { screen in
      SwitchStore(screen) { screen in
        switch screen {
        case .welcome:
          CaseLet(
            /LogInScreen.State.welcome,
             action: LogInScreen.Action.welcome,
             then: WelcomeView.init
          )

        case .logIn:
          CaseLet(
            /LogInScreen.State.logIn,
             action: LogInScreen.Action.logIn,
             then: LogInView.init
          )
        }
      }
    }
  }
}

@Reducer
struct LogInCoordinator: Reducer {
  struct State: Equatable, IdentifiedRouterState {
    static let initialState = LogInCoordinator.State(
      routes: [.root(.welcome(.init()), embedInNavigationView: true)]
    )
    var routes: IdentifiedArrayOf<Route<LogInScreen.State>>
  }

	enum Action {
		case router(IdentifiedRouterAction<LogInScreen.State, LogInScreen.Action>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
			case .router(.routeAction(.element(_, .welcome(.logInTapped)))):
        state.routes.push(.logIn(.init()))

      default:
        break
      }
      return .none
    }
		.forEachRoute(action: \.router) {
      LogInScreen()
    }
  }
}
