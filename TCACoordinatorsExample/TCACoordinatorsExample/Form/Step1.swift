import ComposableArchitecture
import SwiftUI

struct Step1: ReducerProtocol {
  public struct State: Equatable {
    @BindableState var firstName: String = ""
    @BindableState var lastName: String = ""
  }

  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case nextButtonTapped
  }
  
  var body: some ReducerProtocol<State, Action> {
    BindingReducer()
  }
}

struct Step1View: View {
  let store: Store<Step1.State, Step1.Action>

  var body: some View {
    WithViewStore(store) { viewStore in
      Form {
        TextField("First Name", text: viewStore.binding(\.$firstName))
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

struct Step1Environment {
  let mainQueue: AnySchedulerOf<DispatchQueue>
}
