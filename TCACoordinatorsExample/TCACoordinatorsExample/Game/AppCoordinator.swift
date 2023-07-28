import ComposableArchitecture
import SwiftUI
import TCACoordinators

// This coordinator shows one of two child coordinators, depending on if logged in. It
// animates a transition between the two child coordinators.
struct AppCoordinatorView: View {
  let store: StoreOf<GameApp>

  var body: some View {
    WithViewStore(store, observe: { $0.isLoggedIn }) { viewStore in
      VStack {
        if viewStore.state {
          GameCoordinatorView(store: store.scope(state: \.game, action: GameApp.Action.game))
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else {
          LogInCoordinatorView(store: store.scope(state: \.logIn, action: GameApp.Action.logIn))
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
      }
      .animation(.default, value: viewStore.state)
    }
  }
}

struct GameApp: Reducer {
  struct State: Equatable {
    static let initialState = State(logIn: .initialState, game: .initialState(), isLoggedIn: false)

    var logIn: LogInCoordinator.State
    var game: GameCoordinator.State

    var isLoggedIn: Bool
  }

  enum Action {
    case logIn(LogInCoordinator.Action)
    case game(GameCoordinator.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.logIn, action: /Action.logIn) {
      LogInCoordinator()
    }
    Scope(state: \.game, action: /Action.game) {
      GameCoordinator()
    }
    Reduce<State, Action> { state, action in
      switch action {
      case .logIn(.routeAction(_, .logIn(.logInTapped(let name)))):
        state.game = .initialState(playerName: name)
        state.isLoggedIn = true
      case .game(.routeAction(_, .game(.logOutButtonTapped))):
        state.logIn = .initialState
        state.isLoggedIn = false
      default:
        break
      }
      return .none
    }
  }
}
