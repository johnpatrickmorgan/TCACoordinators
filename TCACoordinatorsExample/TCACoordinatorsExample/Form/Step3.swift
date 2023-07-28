import ComposableArchitecture
import SwiftUI

struct Step3View: View {
  let store: StoreOf<Step3>

  var body: some View {
    WithViewStore(store, observe: { $0 }) { viewStore in
      Form {
        Section {
          if !viewStore.occupations.isEmpty {
            List(viewStore.occupations, id: \.self) { occupation in
              Button {
                viewStore.send(.selectOccupation(occupation))
              } label: {
                HStack {
                  Text(occupation)

                  Spacer()

                  if let selected = viewStore.selectedOccupation, selected == occupation {
                    Image(systemName: "checkmark")
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
          viewStore.send(.nextButtonTapped)
        }
      }
      .onAppear {
        viewStore.send(.getOccupations)
      }
      .navigationTitle("Step 3")
    }
  }
}

struct Step3: Reducer {
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

  let getOccupations: () async -> [String]

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .getOccupations:
        return .run { send in
          await send(.receiveOccupations(getOccupations()))
        }

      case .receiveOccupations(let occupations):
        state.occupations = occupations
        return .none

      case .selectOccupation(let occupation):
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
