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
      case let .welcome(state):
        state.id
      case let .logIn(state):
        state.id
      }
    }
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.welcome, action: \.welcome) {
      Welcome()
    }
    Scope(state: \.logIn, action: \.logIn) {
      LogIn()
    }
  }
}

struct LogInCoordinatorView: View {
  let store: StoreOf<LogInCoordinator>

  var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      SwitchStore(screen) { screen in
        switch screen {
        case .welcome:
          CaseLet(
            \LogInScreen.State.welcome,
            action: LogInScreen.Action.welcome,
            then: WelcomeView.init
          )

        case .logIn:
          CaseLet(
            \LogInScreen.State.logIn,
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
  struct State: Equatable {
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
      case .router(.routeAction(_, .welcome(.logInTapped))):
        state.routes.push(.logIn(.init()))

      default:
        break
      }
      return .none
    }
    .forEachRoute(\.routes, action: \.router) {
      LogInScreen()
    }
  }
}
