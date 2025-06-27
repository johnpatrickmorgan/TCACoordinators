import ComposableArchitecture
import SwiftUI
import TCACoordinators

// This coordinator shows one of two child coordinators, depending on if logged in. It
// animates a transition between the two child coordinators.
struct AppCoordinatorView: View {
  let store: StoreOf<GameApp>

  var body: some View {
    WithPerceptionTracking {
      VStack {
        if store.isLoggedIn {
          GameCoordinatorView(store: store.scope(state: \.game, action: \.game))
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else {
          LogInCoordinatorView(store: store.scope(state: \.logIn, action: \.logIn))
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        }
      }
      .animation(.default, value: store.isLoggedIn)
    }
  }
}

@Reducer
struct GameApp {
  @ObservableState
  struct State: Equatable, Sendable {
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
    Scope(state: \.logIn, action: \.logIn) {
      LogInCoordinator()
    }
    Scope(state: \.game, action: \.game) {
      GameCoordinator()
    }
    Reduce<State, Action> { state, action in
      switch action {
      case let .logIn(.router(.routeAction(_, .logIn(.logInTapped(name))))):
        state.game = .initialState(playerName: name)
        state.isLoggedIn = true
      case .game(.router(.routeAction(_, .game(.logOutButtonTapped)))):
        state.logIn = .initialState
        state.isLoggedIn = false
      default:
        break
      }
      return .none
    }
  }
}
