import ComposableArchitecture
import SwiftUI
import TCACoordinators

@main
struct TCACoordinatorsExampleApp: App {
  var body: some Scene {
    WindowGroup {
      MainTabCoordinatorView(
        store: .init(
          initialState: .initialState,
          reducer: mainTabCoordinatorReducer,
          environment: .init()
        )
      )
    }
  }
}

// MainTabCoordinator

struct MainTabCoordinatorView: View {
  let store: Store<MainTabCoordinatorState, MainTabCoordinatorAction>

  var body: some View {
    WithViewStore(store) { _ in
      TabView {
        IndexedCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinatorState.indexed,
            action: MainTabCoordinatorAction.indexed
          )
        ).tabItem { Text("Indexed") }
        IdentifiedCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinatorState.identified,
            action: MainTabCoordinatorAction.identified
          )
        ).tabItem { Text("Identified") }
        GameCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinatorState.gameTCARouter,
            action: MainTabCoordinatorAction.gameTCARouter
          )
        ).tabItem { Text("Game") }
      }
    }
  }
}

enum MainTabCoordinatorAction {
  case identified(IdentifiedCoordinatorAction)
  case indexed(IndexedCoordinatorAction)
  case gameTCARouter(GameCoordinatorAction)
  case game(GameAction)
}

struct MainTabCoordinatorState: Equatable {
  static let initialState = MainTabCoordinatorState(
    identified: .initialState,
    indexed: .initialState,
    gameTCARouter: .initialState
  )

  var identified: IdentifiedCoordinatorState
  var indexed: IndexedCoordinatorState
  var gameTCARouter: GameCoordinatorState
}

struct MainTabCoordinatorEnvironment {}

typealias MainTabCoordinatorReducer = Reducer<
  MainTabCoordinatorState, MainTabCoordinatorAction, MainTabCoordinatorEnvironment
>

let mainTabCoordinatorReducer: MainTabCoordinatorReducer = .combine(
  indexedCoordinatorReducer
    .pullback(
      state: \MainTabCoordinatorState.indexed,
      action: /MainTabCoordinatorAction.indexed,
      environment: { _ in .init() }
    ),
  identifiedCoordinatorReducer
    .pullback(
      state: \MainTabCoordinatorState.identified,
      action: /MainTabCoordinatorAction.identified,
      environment: { _ in .init() }
    ),
  gameCoordinatorReducer
    .pullback(
      state: \MainTabCoordinatorState.gameTCARouter,
      action: /MainTabCoordinatorAction.gameTCARouter,
      environment: { _ in .init() }
    )
)
