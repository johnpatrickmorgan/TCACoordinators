import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct GameCoordinatorView: View {
  let store: StoreOf<GameCoordinator>

  var body: some View {
		TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      SwitchStore(screen) { screen in
        switch screen {
        case .game:
          CaseLet(
            \GameScreen.State.game,
             action: GameScreen.Action.game,
             then: GameView.init
          )
        }
      }
    }
  }
}

@Reducer
struct GameScreen {
  enum State: Equatable, Identifiable {
    case game(Game.State)

    var id: UUID {
      switch self {
      case .game(let state):
        return state.id
      }
    }
  }

  enum Action {
    case game(Game.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: \.game, action: \.game) {
      Game()
    }
  }
}

@Reducer
struct GameCoordinator {
  struct State: Equatable, IndexedRouterState {
    static func initialState(playerName: String = "") -> Self {
      Self(
        routes: [.root(.game(.init(oPlayerName: "Opponent", xPlayerName: playerName.isEmpty ? "Player" : playerName)), embedInNavigationView: true)]
      )
    }

    var routes: [Route<GameScreen.State>]
  }

  enum Action {
		case router(IndexedRouterAction<GameScreen.State, GameScreen.Action>)
  }

  var body: some ReducerOf<Self> {
    EmptyReducer()
			.forEachRoute(action: \.router) {
        GameScreen()
      }
  }
}
