import ComposableArchitecture
import SwiftUI

struct FinalScreenView: View {
  let store: StoreOf<FinalScreen>

  var body: some View {
    WithPerceptionTracking {
      Form {
        Section {
          Button {
            store.send(.returnToName)
          } label: {
            LabelledRow("First name") {
              Text(store.firstName)
            }.foregroundColor(store.firstName.isEmpty ? .red : .black)
          }

          Button {
            store.send(.returnToName)
          } label: {
            LabelledRow("Last Name") {
              Text(store.lastName)
            }.foregroundColor(store.lastName.isEmpty ? .red : .black)
          }

          Button {
            store.send(.returnToDateOfBirth)
          } label: {
            LabelledRow("Date of Birth") {
              Text(store.dateOfBirth, format: .dateTime.day().month().year())
            }
          }

          Button {
            store.send(.returnToJob)
          } label: {
            LabelledRow("Job") {
              Text(store.job ?? "-")
            }.foregroundColor((store.job?.isEmpty ?? true) ? .red : .black)
          }
        } header: {
          Text("Confirm Your Info")
        }
        .buttonStyle(.plain)

        Button("Submit") {
          store.send(.submit)
        }.disabled(store.isIncomplete)
      }
      .navigationTitle("Submit")
      .disabled(store.submissionInFlight)
      .overlay {
        if store.submissionInFlight {
          Text("Submitting")
            .padding()
            .background(.thinMaterial)
            .cornerRadius(8)
        }
      }
      .animation(.spring(), value: store.submissionInFlight)
    }
  }
}

struct LabelledRow<Content: View>: View {
  let label: String
  let content: Content

  init(
    _ label: String,
    @ViewBuilder content: () -> Content
  ) {
    self.label = label
    self.content = content()
  }

  var body: some View {
    HStack {
      Text(label)
      Spacer()
      content
    }
    .contentShape(.rect)
  }
}

struct APIModel: Codable, Equatable {
  let firstName: String
  let lastName: String
  let dateOfBirth: Date
  let job: String
}

@Reducer
struct FinalScreen {
  @ObservableState
  struct State: Equatable {
    let firstName: String
    let lastName: String
    let dateOfBirth: Date
    let job: String?

    var submissionInFlight = false
    var isIncomplete: Bool {
      firstName.isEmpty || lastName.isEmpty || job?.isEmpty ?? true
    }
  }

  enum Action: Equatable {
    case returnToName
    case returnToDateOfBirth
    case returnToJob

    case submit
    case receiveAPIResponse(Bool)
  }

  @Dependency(\.mainQueue) var mainQueue
  @Dependency(FormScreenEnvironment.self) var environment

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .submit:
        guard let job = state.job else { return .none }
        state.submissionInFlight = true

        let apiModel = APIModel(
          firstName: state.firstName,
          lastName: state.lastName,
          dateOfBirth: state.dateOfBirth,
          job: job
        )

        return .run { send in
          try await mainQueue.sleep(for: .seconds(0.8))
          await send(.receiveAPIResponse(environment.submit(apiModel)))
        }

      case .receiveAPIResponse:
        state.submissionInFlight = false
        return .none

      case .returnToName, .returnToDateOfBirth, .returnToJob:
        return .none
      }
    }
  }
}
