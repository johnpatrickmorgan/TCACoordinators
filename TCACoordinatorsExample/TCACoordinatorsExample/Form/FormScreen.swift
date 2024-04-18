import ComposableArchitecture
import Foundation

struct FormScreenEnvironment {
  let getOccupations: () async -> [String]
  let submit: (APIModel) async -> Bool

  static let test = FormScreenEnvironment(
    getOccupations: {
      [
        "iOS Developer",
        "Android Developer",
        "Web Developer",
        "Project Manager",
        "Designer",
        "The Big Cheese"
      ]
    },
    submit: { _ in true }
  )
}

@Reducer
struct FormScreen: Reducer {
  let environment: FormScreenEnvironment

  enum State: Equatable, Identifiable {
    case step1(Step1.State)
    case step2(Step2.State)
    case step3(Step3.State)
    case finalScreen(FinalScreen.State)

    var id: ID {
      switch self {
      case .step1:
        return .step1
      case .step2:
        return .step2
      case .step3:
        return .step3
      case .finalScreen:
        return .finalScreen
      }
    }

    enum ID: Identifiable {
      case step1
      case step2
      case step3
      case finalScreen

      var id: ID {
        self
      }
    }
  }

  enum Action: Equatable {
    case step1(Step1.Action)
    case step2(Step2.Action)
    case step3(Step3.Action)
    case finalScreen(FinalScreen.Action)
  }

  var body: some ReducerOf<Self> {
    Scope(state: /State.step1, action: /Action.step1) {
      Step1()
    }
    Scope(state: /State.step2, action: /Action.step2) {
      Step2()
    }
    Scope(state: /State.step3, action: /Action.step3) {
      Step3(getOccupations: environment.getOccupations)
    }
    Scope(state: /State.finalScreen, action: /Action.finalScreen) {
      FinalScreen(submit: environment.submit)
    }
  }
}
