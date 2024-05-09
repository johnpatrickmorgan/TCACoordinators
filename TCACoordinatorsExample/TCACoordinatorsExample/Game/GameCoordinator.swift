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
      case let .outcome(store):
        OutcomeView(store: store)
      }
    }
  }
}

@Reducer(state: .equatable)
enum GameScreen {
  case game(Game)
  case outcome(Outcome)
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
    Reduce { state, action in
      guard case let .game(game) = state.routes.first?.screen else { return .none }
      switch action {
      case .router(.routeAction(id: _, action: .outcome(.newGameTapped))):
        state.routes = [.root(.game(.init(oPlayerName: game.xPlayerName, xPlayerName: game.oPlayerName)), embedInNavigationView: true)]
      case .router(.routeAction(id: _, action: .game(.gameCompleted(let winner)))):
        state.routes.push(.outcome(.init(winner: winner, oPlayerName: game.oPlayerName, xPlayerName: game.xPlayerName)))
      default:
        break
      }
      return .none
    }
    .forEachRoute(\.routes, action: \.router)
  }
}
