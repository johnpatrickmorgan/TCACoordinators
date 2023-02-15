import ComposableArchitecture
import SwiftUI

struct Step3View: View {
  let store: StoreOf<Step3>

  var body: some View {
    WithViewStore(store) { viewStore in
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

struct Step3: ReducerProtocol {
  struct State: Equatable {
    var selectedOccupation: String?
    var occupations: [String] = []
  }

  enum Action: Equatable {
    case getOccupations
    case receiveOccupations(Result<[String], Never>)
    case selectOccupation(String)
    case nextButtonTapped
  }

  let mainQueue: AnySchedulerOf<DispatchQueue>
  let getOccupations: () -> EffectTask<[String]>

  var body: some ReducerProtocol<State, Action> {
    Reduce { state, action in
      switch action {
      case .getOccupations:
        return getOccupations()
          .receive(on: mainQueue)
          .catchToEffect(Action.receiveOccupations)

      case .receiveOccupations(.success(let occupations)):
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
