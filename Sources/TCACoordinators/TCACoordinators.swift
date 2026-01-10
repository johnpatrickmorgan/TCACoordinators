@_exported import FlowStacks
@_spi(Private) import FlowStacks

let setUpLibraryOnce: Void = {
  // Configure FlowStacks rootIndex, as TCACoordinators includes the root screen within its collection.
  isWithinTCACoordinators = true
}()
