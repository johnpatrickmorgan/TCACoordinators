import Foundation
import ComposableArchitecture
import FlowStacks

extension IdentifiedArray: RoutableCollection {
  public mutating func _append(element: Element) {
    append(element)
  }
}

extension RoutableCollection where Element: RouteProtocol {
  
  /// Goes back to the topmost (most recently shown) screen in the stack
  /// that matches the given case path. If no screens satisfy the condition,
  /// the routes will be unchanged.
  /// - Parameter condition: The predicate indicating which screen to pop to.
  /// - Returns: A `Bool` indicating whether a screen was found.
  @discardableResult
  public mutating func goBackTo<T>(_ screenCasePath: CasePath<Element.Screen, T>) -> Bool {
    goBackTo(where: { screenCasePath.extract(from: $0.screen) != nil })
  }
  

  /// Pops to the topmost (most recently shown) screen in the stack
  /// that matches the given case path. If no screens satisfy the condition,
  /// the routes will be unchanged. Only screens that have been pushed will
  /// be popped.
  /// - Parameter condition: The predicate indicating which screen to pop to.
  /// - Returns: A `Bool` indicating whether a screen was found.
  @discardableResult
  public mutating func popTo<T>(_ screenCasePath: CasePath<Element.Screen, T>) -> Bool {
    popTo(where: { screenCasePath.extract(from: $0.screen) != nil })
  }
}
