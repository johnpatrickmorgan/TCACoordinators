//
//  AppCoordinator.swift
//  TCA-Coordinator-Form
//
//  Created by Rhys Morgan on 14/07/2022.
//

import ComposableArchitecture
import TCACoordinators

struct FormAppCoordinatorState: IdentifiedRouterState, Equatable {

	static let initialState = Self(routeIDs: [.root(.step1, embedInNavigationView: true)])
  
  var step1State = Step1State()
  var step2State = Step2State()
  var step3State = Step3State()
  
  var finalScreenState: FinalScreenState {
    return .init(firstName: step1State.firstName, lastName: step1State.lastName, dateOfBirth: step2State.dateOfBirth, job: step3State.selectedOccupation!)
  }
  
  var routeIDs: IdentifiedArrayOf<Route<AppFlowState.ID>>

  var routes: IdentifiedArrayOf<Route<AppFlowState>> {
    get {
      let routes = routeIDs.map { route -> Route<AppFlowState> in
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
      let routeIDs = newValue.map { route -> Route<AppFlowState.ID> in
        route.map { id in
          switch id {
          case .step1(let step1State):
            self.step1State = step1State
            return .step1
          case .step2(let step2State):
            self.step2State = step2State
            return .step2
          case .step3(let step3State):
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
}

enum FormAppCoordinatorAction: IdentifiedRouterAction {
	case updateRoutes(IdentifiedArrayOf<Route<AppFlowState>>)
	case routeAction(AppFlowState.ID, action: AppFlowAction)
}

typealias FormAppCoordinatorReducer = Reducer<FormAppCoordinatorState, FormAppCoordinatorAction, AppFlowEnvironment>

extension FormAppCoordinatorReducer {
	static let formAppCoordinator = AppFlowReducer.appFlow
		.forEachIdentifiedRoute(environment: { $0 })
		.withRouteReducer(Reducer { state, action, _ in
			switch action {
			case .routeAction(_, action: .step1(.nextButtonTapped)):
        state.routeIDs.push(.step2)
				return .none

			case .routeAction(_, action: .step2(.nextButtonTapped)):
        state.routeIDs.push(.step3)
				return .none

			case .routeAction(_, action: .step3(.nextButtonTapped)):
				state.routeIDs.push(.finalScreen)

				return .none

			case .routeAction(_, action: .finalScreen(.returnToName)):
				state.routeIDs.goBackTo(id: .step1)
				return .none

			case .routeAction(_, action: .finalScreen(.returnToDateOfBirth)):
				state.routeIDs.goBackTo(id: .step2)
				return .none

			case .routeAction(_, action: .finalScreen(.returnToJob)):
				state.routeIDs.goBackTo(id: .step3)
				return .none

			default:
				return .none
			}
		})
}

