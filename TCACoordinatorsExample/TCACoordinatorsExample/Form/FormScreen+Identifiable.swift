extension FormScreen.State: Identifiable {
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

    var id: ID { self }
  }
}
