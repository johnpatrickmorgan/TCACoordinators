import Foundation
import ComposableArchitecture

/// Adapted from a similar function in The Composable Architecture, that was deprecated in favour of an
/// IdentifiedArray-based version. In general, it might be considered unwise to identify child reducers by
/// their Array index in case they move position, but if the only changes made to the Array are
/// index-stable, e.g. pushes and pops, then that's not a problem.
/// https://github.com/pointfreeco/swift-composable-architecture/blob/f7c75217a8087167aacbdad3fe4950867f468a52/Sources/ComposableArchitecture/Internal/Deprecations.swift#L704-L765
extension Reducer {
  func forEachIndex<ElementState, ElementAction, Element: Reducer>(
    _ toElementsState: WritableKeyPath<State, [ElementState]>,
    action toElementAction: CaseKeyPath<Action, IdentifiedAction<Int, ElementAction>>,
    @ReducerBuilder<ElementState, ElementAction> element: () -> Element,
    file: StaticString = #file,
    fileID: StaticString = #fileID,
    line: UInt = #line
  ) -> _ForEachIndexReducer<Self, Element>
  where ElementState == Element.State, ElementAction == Element.Action {
    _ForEachIndexReducer(
      parent: self,
      toElementsState: toElementsState,
      toElementAction: toElementAction,
      element: element(),
      file: file,
      fileID: fileID,
      line: line
    )
  }
}

struct _ForEachIndexReducer<
  Parent: Reducer, Element: Reducer
>: Reducer where Parent.Action: CasePathable {
  let parent: Parent
  let toElementsState: WritableKeyPath<Parent.State, [Element.State]>
  let toElementAction: CaseKeyPath<Parent.Action, IdentifiedAction<Int, Element.Action>>
  let element: Element
  let file: StaticString
  let fileID: StaticString
  let line: UInt

  init(
    parent: Parent,
    toElementsState: WritableKeyPath<Parent.State, [Element.State]>,
    toElementAction: CaseKeyPath<Parent.Action, IdentifiedAction<Int, Element.Action>>,
    element: Element,
    file: StaticString,
    fileID: StaticString,
    line: UInt
  ) {
    self.parent = parent
    self.toElementsState = toElementsState
    self.toElementAction = toElementAction
    self.element = element
    self.file = file
    self.fileID = fileID
    self.line = line
  }

  public var body: some ReducerOf<Parent> {
    Reduce { state, action in
      reduceForEach(into: &state, action: action)
        .merge(with: parent.reduce(into: &state, action: action))
    }
  }

  func reduceForEach(
    into state: inout Parent.State, action: Parent.Action
  ) -> Effect<Parent.Action> {
		guard case let .element(index, elementAction) = action[case: toElementAction] else { return .none }
    let array = state[keyPath: self.toElementsState]
    if array[safe: index] == nil {
      runtimeWarn(
        """
        A "forEachRoute" at "\(self.fileID):\(self.line)" received an action for a screen at \
        index \(index) but the screens array only contains \(array.count) elements.

          Action:
            \(action)

        This may be because a parent reducer (e.g. coordinator reducer) removed the screen at \
        this index before the action was sent.
        """,
        file: self.file,
        line: self.line
      )
      return .none
    }
    return self.element
      .reduce(into: &state[keyPath: self.toElementsState][index], action: elementAction)
			.map { self.toElementAction(.element(id: index, action: $0)) }
  }
}

public func runtimeWarn(
  _ message: @autoclosure () -> String,
  file: StaticString? = nil,
  line: UInt? = nil
) {
#if DEBUG
  let message = message()
  if _XCTIsTesting {
    if let file, let line {
      XCTFail(message, file: file, line: line)
    } else {
      XCTFail(message)
    }
  } else {
    fputs("[TCACoordinators] \(message)\n", stderr)
  }
#endif
}
