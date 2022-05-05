import ComposableArchitecture
import SwiftUI
import TCACoordinators

enum LogInScreenAction {
  case welcome(WelcomeAction)
  case logIn(LogInAction)
}

enum LogInScreenState: Equatable, Identifiable {
  case welcome(WelcomeState)
  case logIn(LogInState)

  var id: UUID {
    switch self {
    case .welcome(let state):
      return state.id
    case .logIn(let state):
      return state.id
    }
  }
}

struct LogInScreenEnvironment {}

let logInScreenReducer = Reducer<LogInScreenState, LogInScreenAction, LogInScreenEnvironment>.combine(
  welcomeReducer
    .pullback(
      state: /LogInScreenState.welcome,
      action: /LogInScreenAction.welcome,
      environment: { _ in WelcomeEnvironment() }
    ),
  logInReducer
    .pullback(
      state: /LogInScreenState.logIn,
      action: /LogInScreenAction.logIn,
      environment: { _ in LogInEnvironment() }
    )
)

struct LogInCoordinatorView: View {
  let store: Store<LogInCoordinatorState, LogInCoordinatorAction>

  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
        CaseLet(
          state: /LogInScreenState.welcome,
          action: LogInScreenAction.welcome,
          then: WelcomeView.init
        )
        CaseLet(
          state: /LogInScreenState.logIn,
          action: LogInScreenAction.logIn,
          then: LogInView.init
        )
      }
    }
  }
}

struct LogInCoordinatorState: Equatable, IdentifiedRouterState {
  static let initialState = LogInCoordinatorState(
    routes: [.root(.welcome(.init()), embedInNavigationView: true)]
  )

  var routes: IdentifiedArrayOf<Route<LogInScreenState>>
}

enum LogInCoordinatorAction: IdentifiedRouterAction {
  case routeAction(ScreenState.ID, action: LogInScreenAction)
  case updateRoutes(IdentifiedArrayOf<Route<LogInScreenState>>)
}

struct LogInCoordinatorEnvironment {}

typealias LogInCoordinatorReducer = Reducer<
  LogInCoordinatorState, LogInCoordinatorAction, LogInCoordinatorEnvironment
>

let logInCoordinatorReducer: LogInCoordinatorReducer = logInScreenReducer
  .forEachIdentifiedRoute(environment: { _ in .init() })
  .withRouteReducer(Reducer { state, action, _ in
    switch action {
    case .routeAction(_, .welcome(.logInTapped)):
      state.routes.push(.logIn(.init()))

    default:
      break
    }
    return .none
  })
