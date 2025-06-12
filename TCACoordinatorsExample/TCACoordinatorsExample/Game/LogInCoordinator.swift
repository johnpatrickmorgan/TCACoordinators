import ComposableArchitecture
import SwiftUI
import TCACoordinators

@Reducer(state: .equatable, .hashable)
enum LogInScreen {
  case welcome(Welcome)
  case logIn(LogIn)
}

struct LogInCoordinatorView: View {
  let store: StoreOf<LogInCoordinator>

  var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .welcome(store):
        WelcomeView(store: store)

      case let .logIn(store):
        LogInView(store: store)
      }
    }
  }
}

@Reducer
struct LogInCoordinator {
  @ObservableState
  struct State: Equatable, Sendable {
    static let initialState = LogInCoordinator.State(
      routes: [.root(.welcome(.init()), embedInNavigationView: true)]
    )
    var routes: IdentifiedArrayOf<Route<LogInScreen.State>>
  }

  enum Action {
    case router(IdentifiedRouterActionOf<LogInScreen>)
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
    .forEachRoute(\.routes, action: \.router)
  }
}
