// PEGExBuilders - Quantifier behavior for ZeroOrMore/OneOrMore

/// Controls how quantifiers consume input when multiple matches are possible.
public enum QuantifierBehavior: Sendable {
    /// Consume as much as possible (PEG default).
    case greedy
    /// Consume as little as possible.
    case lazy
}
