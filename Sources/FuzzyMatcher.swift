import Foundation

/// A lightweight, score-based fuzzy matching engine for the Command Palette.
///
/// This matcher produces a continuous `Double` relevance score for each query/candidate pair.
/// Lower scores indicate a better match, following the standard distance metric convention.
///
/// ## Scoring Tiers
/// - `0.0` — Exact match
/// - `0.1` — Prefix match (candidate starts with query)
/// - `0.2` — Substring match (candidate contains query)
/// - `0.3 – 1.0` — Fuzzy character sequence match with consecutive bonuses
/// - `nil` — No match (excluded from results)
///
/// ## Design Notes
/// This is intentionally a dependency-free, pure Swift implementation.
/// It does not require any third-party libraries and is fully testable in isolation.
struct FuzzyMatcher {

    // MARK: - Public API

    /// Computes a relevance score for a query against a candidate string.
    ///
    /// - Parameters:
    ///   - query: The user's search input.
    ///   - candidate: The string to match against (e.g., a category name).
    /// - Returns: A `Double` score where lower is a better match, or `nil` if the candidate
    ///   does not contain all characters of the query in order.
    static func score(query: String, candidate: String) -> Double? {
        // Normalize to lowercase for case-insensitive comparison.
        let q = query.lowercased()
        let c = candidate.lowercased()

        guard !q.isEmpty else { return 0.0 }

        // INFORMATION FLOW: We apply the scoring tiers in order of quality,
        // returning early on exact or near-exact matches to avoid unnecessary work.

        if c == q {
            return 0.0 // Tier 1: Exact match
        }

        if c.hasPrefix(q) {
            return 0.1 // Tier 2: Prefix match
        }

        if c.contains(q) {
            return 0.2 // Tier 3: Substring match
        }

        // Tier 4: Fuzzy character sequence match with consecutive bonus.
        return fuzzyScore(query: q, candidate: c)
    }

    // MARK: - Private Scoring Logic

    /// Computes a fuzzy score by walking the candidate string and matching query characters in order.
    ///
    /// The algorithm rewards:
    /// - **Consecutive matches**: Characters that match back-to-back get a bonus.
    /// - **Match coverage**: A higher proportion of the candidate covered by matches scores better.
    ///
    /// - Parameters:
    ///   - query: The normalized (lowercased) query string.
    ///   - candidate: The normalized (lowercased) candidate string.
    /// - Returns: A score in the range `0.3...1.0`, or `nil` if not all query characters are found.
    private static func fuzzyScore(query: String, candidate: String) -> Double? {
        var qChars = query.unicodeScalars.makeIterator()
        var currentQueryChar = qChars.next()

        var matchCount = 0
        var consecutiveCount = 0
        var consecutiveBonus = 0.0
        var prevWasMatch = false

        for char in candidate.unicodeScalars {
            guard let qChar = currentQueryChar else { break }

            if char == qChar {
                matchCount += 1

                // INFORMATION FLOW: Track consecutive matches to compute a bonus.
                // Consecutive matches (e.g., matching "em" in "email" starting at position 0)
                // are weighted more favourably than scattered matches.
                if prevWasMatch {
                    consecutiveCount += 1
                    consecutiveBonus += Double(consecutiveCount) * 0.05
                } else {
                    consecutiveCount = 0
                }

                prevWasMatch = true
                currentQueryChar = qChars.next()
            } else {
                prevWasMatch = false
            }
        }

        // If we didn't consume all query characters, this is not a match.
        guard currentQueryChar == nil else { return nil }

        // INFORMATION FLOW: Compute the final score.
        // - Base score of 0.3 to keep fuzzy matches below substring matches.
        // - We penalise by how "spread out" the matches are relative to the candidate length.
        // - We reward consecutive bonuses accumulated above.
        let coverage = Double(matchCount) / Double(candidate.unicodeScalars.count)
        let spreadPenalty = 1.0 - coverage
        
        // TODO: Redundancy Audit - The scoring weights (0.3, 0.7, 0.05) are hardcoded.
        // Consider making these configurable via a scoring configuration struct to allow
        // fine-tuning of the fuzzy matching behavior without changing the core logic.
        let rawScore = 0.3 + (spreadPenalty * 0.7) - consecutiveBonus
 
        // Clamp to the valid fuzzy range [0.3, 1.0] to avoid bonus overflow pushing
        // a fuzzy match into the substring tier.
        return min(max(rawScore, 0.3), 1.0)
    }
}
