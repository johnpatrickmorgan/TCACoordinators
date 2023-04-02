import ComposableArchitecture
import SwiftUI
import TCACoordinators

// This coordinator shows one of two child coordinators, depending on if logged in. It
// animates a transition between the two child coordinators.
struct AppCoordinatorView: View {
  let store: StoreOf<GameApp>

  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
        CaseLet(
          state: /GameApp.Screen.State.logIn,
          action: GameApp.Screen.Action.logIn,
          then: LogInCoordinatorView.init
        )
        CaseLet(
          state: /GameApp.Screen.State.game,
          action: GameApp.Screen.Action.game,
          then: GameCoordinatorView.init
        )
      }
    }
  }
}

struct GameApp: ReducerProtocol {
  struct Screen: ReducerProtocol {
    enum State: Equatable {
      case logIn(LogInCoordinator.State)
      case game(GameCoordinator.State)
    }

    enum Action {
      case logIn(LogInCoordinator.Action)
      case game(GameCoordinator.Action)
    }

    var body: some ReducerProtocol<State, Action> {
      Scope(state: /State.logIn, action: /Action.logIn) {
        LogInCoordinator()
      }
      Scope(state: /State.game, action: /Action.game) {
        GameCoordinator()
      }
    }
  }

  struct State: Equatable, IndexedRouterState {
    static let initialState = State(routes: [.root(.logIn(.initialState))])

    var routes: [Route<Screen.State>]
  }

  enum Action: IndexedRouterAction {
    case routeAction(_ index: Int, action: Screen.Action)
    case updateRoutes(_ screens: [Route<Screen.State>])
  }

  var body: some ReducerProtocol<State, Action> {
    Reduce<State, Action> { state, action in
      switch action {
      case .routeAction(_, let action):
        switch action {
        case .logIn(.routeAction(_, .logIn(.logInTapped(let name)))):
          state.routes = [.root(.game(.initialState(playerName: name)))]
        case .game(.routeAction(_, .game(.logOutButtonTapped))):
          state.routes = [.root(.logIn(.initialState))]
        default:
          break
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
