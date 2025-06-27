import ComposableArchitecture
import Foundation

@DependencyClient
struct FormScreenEnvironment: DependencyKey, Sendable {
  var getOccupations: @Sendable () async -> [String] = { [] }
  var submit: @Sendable (APIModel) async -> Bool = { _ in false }

  static let liveValue = FormScreenEnvironment(
    getOccupations: {
      [
        "iOS Developer",
        "Android Developer",
        "Web Developer",
        "Project Manager",
        "Designer",
        "The Big Cheese",
      ]
    },
    submit: { _ in true }
  )
}

@Reducer(state: .equatable, .hashable)
enum FormScreen {
  case step1(Step1)
  case step2(Step2)
  case step3(Step3)
  case finalScreen(FinalScreen)
}
