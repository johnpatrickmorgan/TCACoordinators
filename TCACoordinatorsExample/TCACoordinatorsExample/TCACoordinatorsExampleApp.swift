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
          reducer: MainTabCoordinator()
        )
      )
    }
  }
}

// MainTabCoordinator

struct MainTabCoordinatorView: View {
  let store: Store<MainTabCoordinator.State, MainTabCoordinator.Action>

  var body: some View {
    TabView {
      IndexedCoordinatorView(
        store: store.scope(
          state: \MainTabCoordinator.State.indexed,
          action: MainTabCoordinator.Action.indexed
        )
      ).tabItem { Text("Indexed") }
      IdentifiedCoordinatorView(
        store: store.scope(
          state: \MainTabCoordinator.State.identified,
          action: MainTabCoordinator.Action.identified
        )
      ).tabItem { Text("Identified") }
      AppCoordinatorView(
        store: store.scope(
          state: \MainTabCoordinator.State.app,
          action: MainTabCoordinator.Action.app
        )
      ).tabItem { Text("Game") }
      FormAppCoordinatorView(
        store: store.scope(
          state: \MainTabCoordinator.State.form,
          action: MainTabCoordinator.Action.form
        )
      ).tabItem { Text("Form") }
    }
  }
}

struct MainTabCoordinator: ReducerProtocol {
  enum Action {
    case identified(IdentifiedCoordinator.Action)
    case indexed(IndexedCoordinator.Action)
    case app(GameApp.Action)
    case form(FormAppCoordinator.Action)
  }

  struct State: Equatable {
    static let initialState = State(
      identified: .initialState,
      indexed: .initialState,
      app: .initialState,
      form: .initialState
    )

    var identified: IdentifiedCoordinator.State
    var indexed: IndexedCoordinator.State
    var app: GameApp.State
    var form: FormAppCoordinator.State
  }

  var body: some ReducerProtocol<State, Action> {
    Scope(state: \.indexed, action: /Action.indexed) {
      IndexedCoordinator()
    }
    Scope(state: \.identified, action: /Action.identified) {
      IdentifiedCoordinator()
    }
    Scope(state: \.app, action: /Action.app) {
      GameApp()
    }
    Scope(state: \.form, action: /Action.form) {
      FormAppCoordinator()
    }
  }
}
