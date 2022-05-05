import ComposableArchitecture
import SwiftUI
import TCACoordinators

// This coordinator shows one of two child coordinators, depending on if logged in. It
// animates a transition between the two child coordinators.
struct AppCoordinatorView: View {
  let store: Store<AppCoordinatorState, AppCoordinatorAction>

  var body: some View {
    WithViewStore(store, removeDuplicates: { $0.isLoggedIn == $1.isLoggedIn }) { viewStore in
      VStack {
        if viewStore.isLoggedIn {
          GameCoordinatorView(store: store.scope(state: \.game, action: AppCoordinatorAction.game))
            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
        } else {
          LogInCoordinatorView(store: store.scope(state: \.logIn, action: AppCoordinatorAction.logIn))
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
      }
      .animation(.default, value: viewStore.isLoggedIn)
    }
  }
}

struct AppCoordinatorState: Equatable {
  var logIn: LogInCoordinatorState
  var game: GameCoordinatorState

  var isLoggedIn: Bool

  static let initialState = AppCoordinatorState(logIn: .initialState, game: .initialState(), isLoggedIn: false)
}

enum AppCoordinatorAction {
  case logIn(LogInCoordinatorAction)
  case game(GameCoordinatorAction)
}

struct AppCoordinatorEnvironment {}

typealias AppCoordinatorReducer = Reducer<
  AppCoordinatorState, AppCoordinatorAction, AppCoordinatorEnvironment
>

let appCoordinatorReducer: AppCoordinatorReducer = .combine(
  logInCoordinatorReducer
    .pullback(
      state: \AppCoordinatorState.logIn,
      action: /AppCoordinatorAction.logIn,
      environment: { _ in .init() }
    ),
  gameCoordinatorReducer
    .pullback(
      state: \AppCoordinatorState.game,
      action: /AppCoordinatorAction.game,
      environment: { _ in .init() }
    ),
  Reducer { state, action, _ in
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
)
