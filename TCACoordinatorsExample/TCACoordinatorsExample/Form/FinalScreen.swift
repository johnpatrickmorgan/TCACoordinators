//
//  FinalScreen.swift
//  TCA-Coordinator-Form
//
//  Created by Rhys Morgan on 14/07/2022.
//

import ComposableArchitecture
import SwiftUI

struct FinalScreenView: View {
	let store: Store<FinalScreenState, FinalScreenAction>

	var body: some View {
		WithViewStore(store) { viewStore in
			Form {
				Section {
					Button {
						viewStore.send(.returnToName)
					} label: {
						LabelledRow("First name") {
							Text(viewStore.firstName)
						}
					}

					Button {
						viewStore.send(.returnToName)
					} label: {
						LabelledRow("Last Name") {
							Text(viewStore.lastName)
						}
					}

					Button {
						viewStore.send(.returnToDateOfBirth)
					} label: {
						LabelledRow("Date of Birth") {
							Text(viewStore.dateOfBirth, format: .dateTime.day().month().year())
						}
					}

					Button {
						viewStore.send(.returnToJob)
					} label: {
						LabelledRow("Job") {
							Text(viewStore.job)
						}
					}
				} header: {
					Text("Confirm Your Info")
				}
				.buttonStyle(.plain)

				Button("Submit") {
					viewStore.send(.submit)
				}
			}
			.navigationTitle("Submit")
			.disabled(viewStore.submissionInFlight)
			.overlay {
				if viewStore.submissionInFlight {
					Text("Submitting")
						.padding()
						.background(.thinMaterial)
						.cornerRadius(8)
				}
			}
			.animation(.spring(), value: viewStore.submissionInFlight)
		}
	}
}

struct LabelledRow<Content: View>: View {
	let label: String
	@ViewBuilder var content: () -> Content

	init(
		_ label: String,
		@ViewBuilder content: @escaping () -> Content
	) {
		self.label = label
		self.content = content
	}

	var body: some View {
		HStack {
			Text(label)
			Spacer()
			content()
		}
		.contentShape(Rectangle())
	}
}

struct FinalScreenView_Previews: PreviewProvider {
	static var previews: some View {
		FinalScreenView(
			store: Store(
				initialState: FinalScreenState(
					firstName: "Rhys",
					lastName: "Morgan",
					dateOfBirth: .now,
					job: "iOS Developer"
				),
				reducer: .finalScreen,
				environment: FinalScreenEnvironment(
					mainQueue: .main,
					submit: { _ in
						Effect(value: true)
					}
				)
			)
		)
	}
}

public struct FinalScreenState: Equatable {
	let firstName: String
	let lastName: String
	let dateOfBirth: Date
	let job: String

	var submissionInFlight = false
}

struct APIModel: Codable, Equatable {
	let firstName: String
	let lastName: String
	let dateOfBirth: Date
	let job: String
}

enum FinalScreenAction: Equatable {
	case returnToName
	case returnToDateOfBirth
	case returnToJob

	case submit
	case receiveAPIResponse(Result<Bool, Never>)
}

struct FinalScreenEnvironment {
	let mainQueue: AnySchedulerOf<DispatchQueue>
	let submit: (APIModel) -> Effect<Bool, Never>
}

typealias FinalScreenReducer = Reducer<FinalScreenState, FinalScreenAction, FinalScreenEnvironment>

extension FinalScreenReducer {
	static let finalScreen = Reducer { state, action, environment in
		switch action {
		case .submit:
			state.submissionInFlight = true

			let apiModel = APIModel(
				firstName: state.firstName,
				lastName: state.lastName,
				dateOfBirth: state.dateOfBirth,
				job: state.job
			)

			return environment.submit(apiModel)
				.delay(for: .seconds(0.8), scheduler: RunLoop.main)
				.receive(on: environment.mainQueue)
				.catchToEffect(Action.receiveAPIResponse)

		case .receiveAPIResponse:
			state.submissionInFlight = false
			return .none

		case .returnToName, .returnToDateOfBirth, .returnToJob:
			return .none
		}
	}
}
