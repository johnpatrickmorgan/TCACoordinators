import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct GameCoordinatorView: View {
  let store: Store<GameCoordinator.State, GameCoordinator.Action>

  var body: some View {
    TCARouter(store) { screen in
      SwitchStore(screen) {
        CaseLet(
          state: /GameScreen.State.game,
          action: GameScreen.Action.game,
          then: GameView.init
        )
      }
    }
  }
}

struct GameScreen: ReducerProtocol {
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

  var body: some ReducerProtocol<State, Action> {
    EmptyReducer()
      .ifCaseLet(/State.game, action: /Action.game) {
        Game()
      }
  }
}

struct GameCoordinator: ReducerProtocol {
  struct CancellationID {}
  struct State: Equatable, IndexedRouterState {
    static func initialState(playerName: String = "") -> Self {
      return .init(
        routes: [.root(.game(.init(oPlayerName: "Opponent", xPlayerName: playerName.isEmpty ? "Player" : playerName)), embedInNavigationView: true)]
      )
    }

    var routes: [Route<GameScreen.State>]
  }

  enum Action: IndexedRouterAction {
    case routeAction(Int, action: GameScreen.Action)
    case updateRoutes([Route<GameScreen.State>])
  }

  var body: some ReducerProtocol<State, Action> {
    EmptyReducer()
      .forEachRoute(cancellationIdType: CancellationID.self) {
        GameScreen()
      }
  }
}
