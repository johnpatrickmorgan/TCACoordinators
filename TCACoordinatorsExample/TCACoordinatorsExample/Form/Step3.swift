import ComposableArchitecture
import SwiftUI

struct Step3View: View {
  let store: StoreOf<Step3>

  var body: some View {
    WithPerceptionTracking {
      Form {
        Section {
          if !store.occupations.isEmpty {
            List(store.occupations, id: \.self) { occupation in
              Button {
                store.send(.selectOccupation(occupation))
              } label: {
                HStack {
                  WithPerceptionTracking {
                    Text(occupation)
                    
                    Spacer()
                    
                    if let selected = store.selectedOccupation, selected == occupation {
                      Image(systemName: "checkmark")
                    }
                  }
                }
              }
              .buttonStyle(.plain)
            }
          } else {
            ProgressView()
              .progressViewStyle(.automatic)
          }
        } header: {
          Text("Jobs")
        }

        Button("Next") {
          store.send(.nextButtonTapped)
        }
      }
      .onAppear {
        store.send(.getOccupations)
      }
      .navigationTitle("Step 3")
    }
  }
}

@Reducer
struct Step3 {
  @ObservableState
  struct State: Equatable {
    var selectedOccupation: String?
    var occupations: [String] = []
  }

  enum Action: Equatable {
    case getOccupations
    case receiveOccupations([String])
    case selectOccupation(String)
    case nextButtonTapped
  }

  @Dependency(FormScreenEnvironment.self) var environment

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .getOccupations:
        return .run { send in
          await send(.receiveOccupations(environment.getOccupations()))
        }

      case let .receiveOccupations(occupations):
        state.occupations = occupations
        return .none

      case let .selectOccupation(occupation):
        if state.occupations.contains(occupation) {
          state.selectedOccupation = state.selectedOccupation == occupation ? nil : occupation
        }

        return .none

      case .nextButtonTapped:
        return .none
      }
    }
  }
}
