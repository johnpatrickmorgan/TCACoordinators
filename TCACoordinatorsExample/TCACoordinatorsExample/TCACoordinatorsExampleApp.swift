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
  let store: StoreOf<MainTabCoordinator>

  var body: some View {
    WithViewStore(store, observe: \.selectedTab) { viewStore in
      TabView(selection: viewStore.binding(get: { $0 }, send: MainTabCoordinator.Action.tabSelected)) {
        IndexedCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinator.State.indexed,
            action: MainTabCoordinator.Action.indexed
          )
        )
        .tabItem { Text("Indexed") }
        .tag(MainTabCoordinator.Tab.indexed)

        IdentifiedCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinator.State.identified,
            action: MainTabCoordinator.Action.identified
          )
        )
        .tabItem { Text("Identified") }
        .tag(MainTabCoordinator.Tab.identified)

        AppCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinator.State.app,
            action: MainTabCoordinator.Action.app
          )
        )
        .tabItem { Text("Game") }
        .tag(MainTabCoordinator.Tab.app)

        FormAppCoordinatorView(
          store: store.scope(
            state: \MainTabCoordinator.State.form,
            action: MainTabCoordinator.Action.form
          )
        )
        .tabItem { Text("Form") }
        .tag(MainTabCoordinator.Tab.form)

      }.onOpenURL { _ in
        // In reality, the URL would be parsed into a Deeplink.
        let deeplink = MainTabCoordinator.Deeplink.identified(.showNumber(42))
        viewStore.send(.deeplinkOpened(deeplink))
      }
    }
  }
}

struct MainTabCoordinator: ReducerProtocol {
  enum Tab: Hashable {
    case identified, indexed, app, form, deeplinkOpened
  }

  enum Deeplink {
    case identified(IdentifiedCoordinator.Deeplink)
  }

  enum Action {
    case identified(IdentifiedCoordinator.Action)
    case indexed(IndexedCoordinator.Action)
    case app(GameApp.Action)
    case form(FormAppCoordinator.Action)
    case deeplinkOpened(Deeplink)
    case tabSelected(Tab)
  }

  struct State: Equatable {
    static let initialState = State(
      identified: .initialState,
      indexed: .initialState,
      app: .initialState,
      form: .initialState,
      selectedTab: .app
    )

    var identified: IdentifiedCoordinator.State
    var indexed: IndexedCoordinator.State
    var app: GameApp.State
    var form: FormAppCoordinator.State

    var selectedTab: Tab
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
    Reduce { state, action in
      switch action {
      case .deeplinkOpened(.identified(.showNumber(let number))):
        state.selectedTab = .identified
        if state.identified.routes.canPush == true {
          state.identified.routes.push(.numberDetail(.init(number: number)))
        } else {
          state.identified.routes.presentSheet(.numberDetail(.init(number: number)), embedInNavigationView: true)
        }
      case .tabSelected(let tab):
        state.selectedTab = tab
      default:
        break
      }
      return .none
    }
  }
}
