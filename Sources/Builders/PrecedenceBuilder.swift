// PEGExBuilders - @PrecedenceBuilder result builder

import Parsing

@resultBuilder
public enum PrecedenceBuilder<Input, Output> {
    public static func buildBlock() -> [AnyPrecedenceLevel<Input, Output>] {
        []
    }

    public static func buildBlock<L>(_ level: L) -> [AnyPrecedenceLevel<Input, Output>]
    where L: PrecedenceLevelType, L.Input == Input, L.Output == Output {
        [level.eraseToPrecedenceLevel()]
    }

    public static func buildBlock<L1, L2>(_ l1: L1, _ l2: L2) -> [AnyPrecedenceLevel<Input, Output>]
    where L1: PrecedenceLevelType, L1.Input == Input, L1.Output == Output,
          L2: PrecedenceLevelType, L2.Input == Input, L2.Output == Output {
        [l1.eraseToPrecedenceLevel(), l2.eraseToPrecedenceLevel()]
    }

    public static func buildBlock<L1, L2, L3>(_ l1: L1, _ l2: L2, _ l3: L3) -> [AnyPrecedenceLevel<Input, Output>]
    where L1: PrecedenceLevelType, L1.Input == Input, L1.Output == Output,
          L2: PrecedenceLevelType, L2.Input == Input, L2.Output == Output,
          L3: PrecedenceLevelType, L3.Input == Input, L3.Output == Output {
        [l1.eraseToPrecedenceLevel(), l2.eraseToPrecedenceLevel(), l3.eraseToPrecedenceLevel()]
    }

    public static func buildBlock<L1, L2, L3, L4>(_ l1: L1, _ l2: L2, _ l3: L3, _ l4: L4) -> [AnyPrecedenceLevel<Input, Output>]
    where L1: PrecedenceLevelType, L1.Input == Input, L1.Output == Output,
          L2: PrecedenceLevelType, L2.Input == Input, L2.Output == Output,
          L3: PrecedenceLevelType, L3.Input == Input, L3.Output == Output,
          L4: PrecedenceLevelType, L4.Input == Input, L4.Output == Output {
        [l1.eraseToPrecedenceLevel(), l2.eraseToPrecedenceLevel(), l3.eraseToPrecedenceLevel(), l4.eraseToPrecedenceLevel()]
    }

    public static func buildBlock<L1, L2, L3, L4, L5>(_ l1: L1, _ l2: L2, _ l3: L3, _ l4: L4, _ l5: L5) -> [AnyPrecedenceLevel<Input, Output>]
    where L1: PrecedenceLevelType, L1.Input == Input, L1.Output == Output,
          L2: PrecedenceLevelType, L2.Input == Input, L2.Output == Output,
          L3: PrecedenceLevelType, L3.Input == Input, L3.Output == Output,
          L4: PrecedenceLevelType, L4.Input == Input, L4.Output == Output,
          L5: PrecedenceLevelType, L5.Input == Input, L5.Output == Output {
        [l1.eraseToPrecedenceLevel(), l2.eraseToPrecedenceLevel(), l3.eraseToPrecedenceLevel(), l4.eraseToPrecedenceLevel(), l5.eraseToPrecedenceLevel()]
    }

    public static func buildArray(_ levels: [AnyPrecedenceLevel<Input, Output>]) -> [AnyPrecedenceLevel<Input, Output>] {
        levels
    }
}

/// Protocol for types that can be used in @PrecedenceBuilder.
public protocol PrecedenceLevelType {
    associatedtype Input
    associatedtype Output
    func eraseToPrecedenceLevel() -> AnyPrecedenceLevel<Input, Output>
}
