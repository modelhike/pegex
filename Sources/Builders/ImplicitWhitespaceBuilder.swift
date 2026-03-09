// PEGExBuilders - Result builder that inserts whitespace between parsers

import Foundation
import Parsing

@resultBuilder
public enum ImplicitWhitespaceBuilder<Input: Collection>
where Input.SubSequence == Input, Input.Element == Character {
    public static func buildBlock<P: Parser>(_ parser: P) -> P
    where P.Input == Input {
        parser
    }

    public static func buildPartialBlock<P: Parser>(first: P) -> P
    where P.Input == Input {
        first
    }

    // Base case: returns tuple
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> ImplicitWhitespaceSequence<A, B>
    where A.Input == Input, B.Input == Input, Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
    }
    
    // Overload: A outputs Void, skip it
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> Parsers.Map<ImplicitWhitespaceSequence<A, B>, B.Output>
    where A.Input == Input, B.Input == Input, A.Output == Void,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        let seq = ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
        return seq.map { _, b in b }
    }
    
    // Overload: B outputs Void, skip it
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> Parsers.Map<ImplicitWhitespaceSequence<A, B>, A.Output>
    where A.Input == Input, B.Input == Input, B.Output == Void,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        let seq = ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
        return seq.map { a, _ in a }
    }
    
    // Overload: both output Void, skip both (most specific for Void+Void)
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> Parsers.Map<ImplicitWhitespaceSequence<A, B>, Void>
    where A.Input == Input, B.Input == Input, A.Output == Void, B.Output == Void,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        let seq = ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
        return seq.map { _, _ in () }
    }
    
    // Overload: A outputs Void, B outputs Void? → return ()
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> Parsers.Map<ImplicitWhitespaceSequence<A, B>, Void>
    where A.Input == Input, B.Input == Input, A.Output == Void, B.Output == Void?,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        let seq = ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
        return seq.map { _, _ in () }
    }
    
    // Overload: A outputs Void?, B outputs Void → return ()
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> Parsers.Map<ImplicitWhitespaceSequence<A, B>, Void>
    where A.Input == Input, B.Input == Input, A.Output == Void?, B.Output == Void,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        let seq = ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
        return seq.map { _, _ in () }
    }
    
    // Overload: both output Void?, skip both → return ()
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> Parsers.Map<ImplicitWhitespaceSequence<A, B>, Void>
    where A.Input == Input, B.Input == Input, A.Output == Void?, B.Output == Void?,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        let seq = ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
        return seq.map { _, _ in () }
    }
    
    // Overload: A outputs Void?, B is non-Void/non-Void? → return B.Output
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> Parsers.Map<ImplicitWhitespaceSequence<A, B>, B.Output>
    where A.Input == Input, B.Input == Input, A.Output == Void?,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        let seq = ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
        return seq.map { _, b in b }
    }
    
    // Overload: A is non-Void/non-Void?, B outputs Void? → return A.Output
    public static func buildPartialBlock<A: Parser, B: Parser>(
        accumulated: A, next: B
    ) -> Parsers.Map<ImplicitWhitespaceSequence<A, B>, A.Output>
    where A.Input == Input, B.Input == Input, B.Output == Void?,
          Input: Collection, Input.SubSequence == Input, Input.Element == Character {
        let seq = ImplicitWhitespaceSequence(
            accumulated,
            next,
            configuration: ImplicitWhitespaceBuilderContext.currentConfiguration
        )
        return seq.map { a, _ in a }
    }
}

@usableFromInline
enum ImplicitWhitespaceBuilderContext {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var configurationStack: [WhitespaceConfiguration] = []

    @usableFromInline
    static var currentConfiguration: WhitespaceConfiguration {
        lock.lock()
        defer { lock.unlock() }
        return configurationStack.last ?? .standard
    }

    @usableFromInline
    static func withConfiguration<T>(_ configuration: WhitespaceConfiguration, _ body: () -> T) -> T {
        lock.lock()
        configurationStack.append(configuration)
        lock.unlock()

        defer {
            lock.lock()
            _ = configurationStack.popLast()
            lock.unlock()
        }

        return body()
    }
}

/// Sequence with implicit whitespace between parsers - automatically flattens Void outputs
public struct ImplicitWhitespaceSequence<A: Parser, B: Parser>: Parser
where A.Input == B.Input, A.Input: Collection, A.Input.SubSequence == A.Input, A.Input.Element == Character {
    @usableFromInline let a: A
    @usableFromInline let b: B
    @usableFromInline let configuration: WhitespaceConfiguration

    @inlinable
    public init(_ a: A, _ b: B, configuration: WhitespaceConfiguration = .standard) {
        self.a = a
        self.b = b
        self.configuration = configuration
    }

    @inlinable
    public func parse(_ input: inout A.Input) throws -> (A.Output, B.Output) {
        let o1 = try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        let o2 = try b.parse(&input)
        return (o1, o2)
    }
}

// Most specific: both Void
extension ImplicitWhitespaceSequence where A.Output == Void, B.Output == Void {
    @inlinable
    public func parse(_ input: inout A.Input) throws -> Void {
        try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        try b.parse(&input)
    }
}

// Second most specific: A is Void (but not B)
extension ImplicitWhitespaceSequence where A.Output == Void {
    @inlinable
    public func parse(_ input: inout A.Input) throws -> B.Output {
        try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        return try b.parse(&input)
    }
}

// Second most specific: B is Void (but not A)
extension ImplicitWhitespaceSequence where B.Output == Void {
    @inlinable
    public func parse(_ input: inout A.Input) throws -> A.Output {
        let o1 = try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        try b.parse(&input)
        return o1
    }
}

// Handle optional Void: A is Void?
extension ImplicitWhitespaceSequence where A.Output == Void? {
    @inlinable
    public func parse(_ input: inout A.Input) throws -> B.Output {
        _ = try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        return try b.parse(&input)
    }
}

// Handle optional Void: B is Void?
extension ImplicitWhitespaceSequence where B.Output == Void? {
    @inlinable
    public func parse(_ input: inout A.Input) throws -> A.Output {
        let o1 = try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        _ = try b.parse(&input)
        return o1
    }
}

/// Sequence that skips the first parser's Void output (whitespace between).
public struct ImplicitWhitespaceSkipFirst<A: Parser, B: Parser>: Parser
where A.Input == B.Input, A.Output == Void,
      A.Input: Collection, A.Input.SubSequence == A.Input, A.Input.Element == Character {
    @usableFromInline let a: A
    @usableFromInline let b: B
    @usableFromInline let configuration: WhitespaceConfiguration

    @inlinable
    public init(_ a: A, _ b: B, configuration: WhitespaceConfiguration = .standard) {
        self.a = a
        self.b = b
        self.configuration = configuration
    }

    @inlinable
    public func parse(_ input: inout A.Input) throws -> B.Output {
        try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        return try b.parse(&input)
    }
}

/// Sequence that skips the second parser's Void output (whitespace between).
public struct ImplicitWhitespaceSkipSecond<A: Parser, B: Parser>: Parser
where A.Input == B.Input, B.Output == Void,
      A.Input: Collection, A.Input.SubSequence == A.Input, A.Input.Element == Character {
    @usableFromInline let a: A
    @usableFromInline let b: B
    @usableFromInline let configuration: WhitespaceConfiguration

    @inlinable
    public init(_ a: A, _ b: B, configuration: WhitespaceConfiguration = .standard) {
        self.a = a
        self.b = b
        self.configuration = configuration
    }

    @inlinable
    public func parse(_ input: inout A.Input) throws -> A.Output {
        let o1 = try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        try b.parse(&input)
        return o1
    }
}

/// Sequence that skips both parsers' Void outputs (whitespace between).
public struct ImplicitWhitespaceSkipBoth<A: Parser, B: Parser>: Parser
where A.Input == B.Input, A.Output == Void, B.Output == Void,
      A.Input: Collection, A.Input.SubSequence == A.Input, A.Input.Element == Character {
    @usableFromInline let a: A
    @usableFromInline let b: B
    @usableFromInline let configuration: WhitespaceConfiguration

    @inlinable
    public init(_ a: A, _ b: B, configuration: WhitespaceConfiguration = .standard) {
        self.a = a
        self.b = b
        self.configuration = configuration
    }

    @inlinable
    public func parse(_ input: inout A.Input) throws -> Void {
        try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        try b.parse(&input)
    }
}

/// Sequence that skips the first parser's optional Void output (whitespace between).
public struct ImplicitWhitespaceSkipFirstOptional<A: Parser, B: Parser>: Parser
where A.Input == B.Input, A.Output == Void?,
      A.Input: Collection, A.Input.SubSequence == A.Input, A.Input.Element == Character {
    @usableFromInline let a: A
    @usableFromInline let b: B
    @usableFromInline let configuration: WhitespaceConfiguration

    @inlinable
    public init(_ a: A, _ b: B, configuration: WhitespaceConfiguration = .standard) {
        self.a = a
        self.b = b
        self.configuration = configuration
    }

    @inlinable
    public func parse(_ input: inout A.Input) throws -> B.Output {
        _ = try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        return try b.parse(&input)
    }
}

/// Sequence that skips the second parser's optional Void output (whitespace between).
public struct ImplicitWhitespaceSkipSecondOptional<A: Parser, B: Parser>: Parser
where A.Input == B.Input, B.Output == Void?,
      A.Input: Collection, A.Input.SubSequence == A.Input, A.Input.Element == Character {
    @usableFromInline let a: A
    @usableFromInline let b: B
    @usableFromInline let configuration: WhitespaceConfiguration

    @inlinable
    public init(_ a: A, _ b: B, configuration: WhitespaceConfiguration = .standard) {
        self.a = a
        self.b = b
        self.configuration = configuration
    }

    @inlinable
    public func parse(_ input: inout A.Input) throws -> A.Output {
        let o1 = try a.parse(&input)
        _ = try Whitespace<A.Input>(configuration: configuration).parse(&input)
        _ = try b.parse(&input)
        return o1
    }
}
