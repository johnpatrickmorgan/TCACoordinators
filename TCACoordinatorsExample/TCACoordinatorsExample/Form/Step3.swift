import ComposableArchitecture
import SwiftUI

struct Step3View: View {
  let store: Store<Step3State, Step3Action>

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

struct Step3View_Previews: PreviewProvider {
  static var previews: some View {
    NavigationView {
      Step3View(
        store: .init(
          initialState: .init(),
          reducer: .step3,
          environment: Step3Environment(
            mainQueue: .main,
            getOccupations: {
              .task {
                [
                  "iOS Developer",
                  "Android Developer",
                  "Web Developer",
                  "Project Manager",
                ]
              }
            }
          )
        )
      )
    }
  }
}

public struct Step3State: Equatable {
  var selectedOccupation: String?
  var occupations: [String] = []
}

public enum Step3Action: Equatable {
  case getOccupations
  case receiveOccupations(Result<[String], Never>)
  case selectOccupation(String)
  case nextButtonTapped
}

struct Step3Environment {
  let mainQueue: AnySchedulerOf<DispatchQueue>
  let getOccupations: () -> Effect<[String], Never>
}

typealias Step3Reducer = Reducer<Step3State, Step3Action, Step3Environment>

extension Step3Reducer {
  static let step3 = Reducer { state, action, environment in
    switch action {
    case .getOccupations:
      return environment
        .getOccupations()
        .receive(on: environment.mainQueue)
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
