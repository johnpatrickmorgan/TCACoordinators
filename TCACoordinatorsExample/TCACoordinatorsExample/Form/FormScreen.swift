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

extension FormScreenEnvironment {
  var step1: Step1Environment {
    .init(mainQueue: mainQueue)
  }

  var step2: Step2Environment {
    .init(mainQueue: mainQueue)
  }

  var step3: Step3Environment {
    .init(mainQueue: mainQueue, getOccupations: getOccupations)
  }

  var finalScreen: FinalScreenEnvironment {
    .init(mainQueue: mainQueue, submit: submit)
  }
}

struct FormScreen: ReducerProtocol {
  let environment: FormScreenEnvironment
  
  enum State: Equatable, Identifiable {
    case step1(Step1.State)
    case step2(Step2State)
    case step3(Step3State)
    case finalScreen(FinalScreenState)

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
    case step2(Step2Action)
    case step3(Step3Action)
    case finalScreen(FinalScreenAction)
  }
  
  var body: some ReducerProtocol<State, Action> {
    EmptyReducer<State, Action>()
    .ifCaseLet(/State.step1, action: /Action.step1) {
      Step1()
    }
    .ifCaseLet(/State.step2, action: /Action.step2) {
      Reduce(Step2Reducer.step2, environment: environment.step2)
    }
    .ifCaseLet(/State.step3, action: /Action.step3) {
      Reduce(Step3Reducer.step3, environment: environment.step3)
    }
    .ifCaseLet(/State.finalScreen, action: /Action.finalScreen) {
      Reduce(FinalScreenReducer.finalScreen, environment: environment.finalScreen)
    }
  }
}
