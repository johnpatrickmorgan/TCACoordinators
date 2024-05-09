import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct GameCoordinatorView: View {
  let store: StoreOf<GameCoordinator>

  var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .game(store):
        GameView(store: store)
      }
    }
  }
}

@Reducer(state: .equatable)
enum GameScreen {
  case game(Game)
}

@Reducer
struct GameCoordinator {
  struct State: Equatable {
    static func initialState(playerName: String = "") -> Self {
      Self(
        routes: [.root(.game(.init(oPlayerName: "Opponent", xPlayerName: playerName.isEmpty ? "Player" : playerName)), embedInNavigationView: true)]
      )
    }

    var routes: [Route<GameScreen.State>]
  }

  enum Action {
    case router(IndexedRouterActionOf<GameScreen>)
  }

  var body: some ReducerOf<Self> {
    EmptyReducer()
      .forEachRoute(\.routes, action: \.router)
  }
}
