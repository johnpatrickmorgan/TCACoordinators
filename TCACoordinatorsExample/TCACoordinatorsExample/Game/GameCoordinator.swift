import ComposableArchitecture
import SwiftUI
import TCACoordinators

enum GameScreenAction {
  case game(GameAction)
}

enum GameScreenState: Equatable, Identifiable {
  case game(GameState)

  var id: UUID {
    switch self {
    case .game(let state):
      return state.id
    }
  }
}

struct GameScreenEnvironment {}

let gameScreenReducer = Reducer<GameScreenState, GameScreenAction, GameScreenEnvironment>.combine(
  gameReducer
    .pullback(
      state: /GameScreenState.game,
      action: /GameScreenAction.game,
      environment: { _ in GameEnvironment() }
    )
)

struct GameCoordinatorState: Equatable, IndexedRouterState {
  static func initialState(playerName: String = "") -> GameCoordinatorState {
    return GameCoordinatorState(
      routes: [.root(.game(.init(oPlayerName: "Opponent", xPlayerName: playerName.isEmpty ? "Player" : playerName)), embedInNavigationView: true)]
    )
  }

  var routes: [Route<GameScreenState>]
}

enum GameCoordinatorAction: IndexedRouterAction {
  case routeAction(Int, action: GameScreenAction)
  case updateRoutes([Route<GameScreenState>])
}

struct GameCoordinatorEnvironment {}

typealias GameCoordinatorReducer = Reducer<GameCoordinatorState, GameCoordinatorAction, GameCoordinatorEnvironment>

let gameCoordinatorReducer: GameCoordinatorReducer = gameScreenReducer
  .forEachIndexedRoute(environment: { _ in GameScreenEnvironment() })

struct GameCoordinatorView: View {
  let store: Store<GameCoordinatorState, GameCoordinatorAction>

  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
        CaseLet(
          state: /GameScreenState.game,
          action: GameScreenAction.game,
          then: GameView.init
        )
      }
    }
  }
}
