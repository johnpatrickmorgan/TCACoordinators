import ComposableArchitecture
import Foundation

struct FormScreenEnvironment {
  let mainQueue: AnySchedulerOf<DispatchQueue>
  let getOccupations: () -> Effect<[String], Never>
  let submit: (APIModel) -> Effect<Bool, Never>

  static let test = FormScreenEnvironment(
    mainQueue: .main,
    getOccupations: {
      .task {
        [
          "iOS Developer",
          "Android Developer",
          "Web Developer",
          "Project Manager",
          "Designer",
          "The Big Cheese"
        ]
      }
    },
    submit: { _ in
      .task { true }
    }
  )
}

struct FormScreen: ReducerProtocol {
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

  var body: some ReducerProtocol<State, Action> {
    EmptyReducer<State, Action>()
      .ifCaseLet(/State.step1, action: /Action.step1) {
        Step1()
      }
      .ifCaseLet(/State.step2, action: /Action.step2) {
        Step2()
      }
      .ifCaseLet(/State.step3, action: /Action.step3) {
        Step3(mainQueue: environment.mainQueue, getOccupations: environment.getOccupations)
      }
      .ifCaseLet(/State.finalScreen, action: /Action.finalScreen) {
        FinalScreen(mainQueue: environment.mainQueue, submit: environment.submit)
      }
  }
}
