import ComposableArchitecture
import SwiftUI
import TCACoordinators

@Reducer
struct FormAppCoordinator {
  @ObservableState
  struct State: Equatable {
    static let initialState = Self(routeIDs: [.root(.step1, embedInNavigationView: true)])

    var step1State = Step1.State()
    var step2State = Step2.State()
    var step3State = Step3.State()

    var finalScreenState: FinalScreen.State {
      .init(firstName: step1State.firstName, lastName: step1State.lastName, dateOfBirth: step2State.dateOfBirth, job: step3State.selectedOccupation)
    }

    var routeIDs: IdentifiedArrayOf<Route<FormScreen.State.ID>>

    var routes: IdentifiedArrayOf<Route<FormScreen.State>> {
      get {
        let routes = routeIDs.map { route -> Route<FormScreen.State> in
          route.map { id in
            switch id {
            case .step1:
              return .step1(step1State)
            case .step2:
              return .step2(step2State)
            case .step3:
              return .step3(step3State)
            case .finalScreen:
              return .finalScreen(finalScreenState)
            }
          }
        }
        return IdentifiedArray(uniqueElements: routes)
      }
      set {
        let routeIDs = newValue.map { route -> Route<FormScreen.State.ID> in
          route.map { id in
            switch id {
            case let .step1(step1State):
              self.step1State = step1State
              return .step1
            case let .step2(step2State):
              self.step2State = step2State
              return .step2
            case let .step3(step3State):
              self.step3State = step3State
              return .step3
            case .finalScreen:
              return .finalScreen
            }
          }
        }
        self.routeIDs = IdentifiedArray(uniqueElements: routeIDs)
      }
    }

    mutating func clear() {
      step1State = .init()
      step2State = .init()
      step3State = .init()
    }
  }

  enum Action {
    case router(IdentifiedRouterActionOf<FormScreen>)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .router(.routeAction(_, action: .step1(.nextButtonTapped))):
        state.routeIDs.push(.step2)
        return .none

      case .router(.routeAction(_, action: .step2(.nextButtonTapped))):
        state.routeIDs.push(.step3)
        return .none

      case .router(.routeAction(_, action: .step3(.nextButtonTapped))):
        state.routeIDs.push(.finalScreen)
        return .none

      case .router(.routeAction(_, action: .finalScreen(.returnToName))):
        state.routeIDs.goBackTo(id: .step1)
        return .none

      case .router(.routeAction(_, action: .finalScreen(.returnToDateOfBirth))):
        state.routeIDs.goBackTo(id: .step2)
        return .none

      case .router(.routeAction(_, action: .finalScreen(.returnToJob))):
        state.routeIDs.goBackTo(id: .step3)
        return .none

      case .router(.routeAction(_, action: .finalScreen(.receiveAPIResponse))):
        state.routeIDs.goBackToRoot()
        state.clear()
        return .none

      default:
        return .none
      }
    }
    .forEachRoute(\.routes, action: \.router)
  }
}

struct FormAppCoordinatorView: View {
  let store: StoreOf<FormAppCoordinator>

  var body: some View {
    ObservedTCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      switch screen.case {
      case let .step1(store):
        Step1View(store: store)

      case let .step2(store):
        Step2View(store: store)

      case let .step3(store):
        Step3View(store: store)

      case let .finalScreen(store):
        FinalScreenView(store: store)
      }
    }
  }
}
