import ComposableArchitecture
import SwiftUI

struct Step1: Reducer {
  public struct State: Equatable {
    @BindingState var firstName: String = ""
    @BindingState var lastName: String = ""
  }

  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case nextButtonTapped
  }

  var body: some ReducerOf<Self> {
    BindingReducer()
  }
}

struct Step1View: View {
  let store: StoreOf<Step1>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Form {
        TextField("First Name", text: viewStore.$firstName)
        TextField("Last Name", text: viewStore.$lastName)

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
