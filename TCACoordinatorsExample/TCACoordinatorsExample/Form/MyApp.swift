import ComposableArchitecture
import SwiftUI
import TCACoordinators

struct MyApp: View {
	let store = Store(
		initialState: FormAppCoordinatorState.initialState,
    reducer: .formAppCoordinator,
		environment: AppFlowEnvironment(
			mainQueue: .main,
			getOccupations: {
				.task {
					[
						"iOS Developer",
						"Android Developer",
						"Web Developer",
						"Project Manager",
						"Designer",
						"The Big Cheese"
					]
				}
			},
			submit: { _ in
				.task { true }
			}
		)
	)

    var body: some View {
			TCARouter(store) { screen in
				SwitchStore(screen) {
					CaseLet(state: /AppFlowState.step1, action: AppFlowAction.step1, then: Step1View.init(store:))

					CaseLet(state: /AppFlowState.step2, action: AppFlowAction.step2, then: Step2View.init(store:))

					CaseLet(state: /AppFlowState.step3, action: AppFlowAction.step3, then: Step3View.init(store:))

					CaseLet(state: /AppFlowState.finalScreen, action: AppFlowAction.finalScreen, then: FinalScreenView.init(store:))
				}
			}
    }
}
