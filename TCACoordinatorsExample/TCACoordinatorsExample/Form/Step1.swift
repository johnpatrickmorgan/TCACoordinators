//
//  Step1.swift
//  TCA-Coordinator-Form
//
//  Created by Rhys Morgan on 12/07/2022.
//

import ComposableArchitecture
import SwiftUI

struct Step1View: View {
	let store: Store<Step1State, Step1Action>

	var body: some View {
		WithViewStore(store) { viewStore in
			Form {
				TextField("First Name", text: viewStore.binding( \.$firstName))
				TextField("Last Name", text: viewStore.binding(\.$lastName))

				Section {
					Button("Next") {
						viewStore.send(.nextButtonTapped)
					}
				}
			}
			.navigationTitle("Step 1")
		}
	}
}

struct Step1View_Previews: PreviewProvider {
	static var previews: some View {
		Step1View(store: Store(initialState: .init(), reducer: .step1, environment: Step1Environment(mainQueue: .main)))
	}
}


public struct Step1State: Equatable {
	@BindableState var firstName: String = ""
	@BindableState var lastName: String = ""
}

public enum Step1Action: Equatable, BindableAction {
	case binding(BindingAction<Step1State>)
	case nextButtonTapped
}

struct Step1Environment {
	let mainQueue: AnySchedulerOf<DispatchQueue>
}

typealias Step1Reducer = Reducer<Step1State, Step1Action, Step1Environment>

extension Step1Reducer {
	static let step1 = empty.binding()
}
