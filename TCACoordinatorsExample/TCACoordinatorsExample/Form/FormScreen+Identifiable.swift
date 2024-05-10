extension FormScreen.State: Identifiable {
  var id: ID {
    switch self {
    case .step1:
      .step1
    case .step2:
      .step2
    case .step3:
      .step3
    case .finalScreen:
      .finalScreen
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
