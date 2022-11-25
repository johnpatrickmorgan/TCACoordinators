import ComposableArchitecture
import SwiftUI

struct Step2View: View {
  let store: StoreOf<Step2>

  var body: some View {
    WithViewStore(store) { viewStore in
      Form {
        Section {
          DatePicker(
            "Date of Birth",
            selection: viewStore.binding(\.$dateOfBirth),
            in: ...Date.now,
            displayedComponents: .date
          )
          .datePickerStyle(.graphical)
        } header: {
          Text("Date of Birth")
        }

        Button("Next") {
          viewStore.send(.nextButtonTapped)
        }
      }
      .navigationTitle("Step 2")
    }
  }
}

struct Step2: ReducerProtocol {
  public struct State: Equatable {
    @BindableState var dateOfBirth: Date = .now
  }

  public enum Action: Equatable, BindableAction {
    case binding(BindingAction<State>)
    case nextButtonTapped
  }

  var body: some ReducerProtocol<State, Action> {
    BindingReducer()
  }
}
