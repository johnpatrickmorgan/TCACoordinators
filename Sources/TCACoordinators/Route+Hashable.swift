extension Route: @retroactive Hashable where Screen: Hashable {
  public func hash(into hasher: inout Hasher) {
    hasher.combine(style)
    hasher.combine(embedInNavigationView)
    hasher.combine(screen)
  }
}

extension Route: @unchecked @retroactive Sendable { }
