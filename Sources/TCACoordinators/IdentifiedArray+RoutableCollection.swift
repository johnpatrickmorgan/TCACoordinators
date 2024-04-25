import ComposableArchitecture
import FlowStacks
import Foundation

extension IdentifiedArray: RoutableCollection {
  public mutating func _append(element: Element) {
    append(element)
  }
}

public extension RoutableCollection where Element: RouteProtocol {
  /// Goes back to the topmost (most recently shown) screen in the stack
  /// that matches the given case path. If no screens satisfy the condition,
  /// the routes will be unchanged.
  /// - Parameter condition: The predicate indicating which screen to pop to.
  /// - Returns: A `Bool` indicating whether a screen was found.
  @discardableResult
  mutating func goBackTo<T>(_ screenCasePath: AnyCasePath<Element.Screen, T>) -> Bool {
    goBackTo(where: { screenCasePath.extract(from: $0.screen) != nil })
  }

  @discardableResult
  mutating func goBackTo<T>(_ screenCasePath: CaseKeyPath<Element.Screen, T>) -> Bool
    where Element.Screen: CasePathable
  {
    goBackTo(where: { $0.screen[case: screenCasePath] != nil })
  }

  /// Pops to the topmost (most recently shown) screen in the stack
  /// that matches the given case path. If no screens satisfy the condition,
  /// the routes will be unchanged. Only screens that have been pushed will
  /// be popped.
  /// - Parameter condition: The predicate indicating which screen to pop to.
  /// - Returns: A `Bool` indicating whether a screen was found.
  @discardableResult
  mutating func popTo<T>(_ screenCasePath: AnyCasePath<Element.Screen, T>) -> Bool {
    popTo(where: { screenCasePath.extract(from: $0.screen) != nil })
  }

  @discardableResult
  mutating func popTo<T>(_ screenCasePath: CaseKeyPath<Element.Screen, T>) -> Bool
    where Element.Screen: CasePathable
  {
    popTo(where: { $0.screen[case: screenCasePath] != nil })
  }
}
