import ComposableArchitecture
import SwiftUI
import TCACoordinators

@Reducer
struct FormAppCoordinator {
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
    .forEachRoute(\.routes, action: \.router) {
      FormScreen(environment: .test)
    }
  }
}

struct FormAppCoordinatorView: View {
  let store: StoreOf<FormAppCoordinator>

  var body: some View {
    TCARouter(store.scope(state: \.routes, action: \.router)) { screen in
      SwitchStore(screen) { screen in
        switch screen {
        case .step1:
          CaseLet(\FormScreen.State.step1, action: FormScreen.Action.step1, then: Step1View.init(store:))

        case .step2:
          CaseLet(\FormScreen.State.step2, action: FormScreen.Action.step2, then: Step2View.init(store:))

        case .step3:
          CaseLet(\FormScreen.State.step3, action: FormScreen.Action.step3, then: Step3View.init(store:))

        case .finalScreen:
          CaseLet(\FormScreen.State.finalScreen, action: FormScreen.Action.finalScreen, then: FinalScreenView.init(store:))
        }
      }
    }
  }
}
