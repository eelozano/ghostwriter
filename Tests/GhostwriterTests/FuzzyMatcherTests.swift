import XCTest
@testable import Ghostwriter

/// Unit tests for the `FuzzyMatcher` scoring engine.
///
/// These tests verify the correctness of the scoring tiers and ensure
/// that the relevance ordering is sensible for common user inputs.
final class FuzzyMatcherTests: XCTestCase {

    // MARK: - Exact Match

    func testExactMatchScoresZero() {
        let score = FuzzyMatcher.score(query: "email", candidate: "email")
        XCTAssertEqual(score, 0.0, "Exact match should score 0.0")
    }

    func testExactMatchIsCaseInsensitive() {
        let score = FuzzyMatcher.score(query: "Email", candidate: "email")
        XCTAssertEqual(score, 0.0, "Exact match should be case-insensitive")
    }

    // MARK: - Prefix Match

    func testPrefixMatchScoresBetterThanSubstring() {
        let prefixScore = FuzzyMatcher.score(query: "em", candidate: "email")
        let substringScore = FuzzyMatcher.score(query: "ail", candidate: "email")

        XCTAssertNotNil(prefixScore)
        XCTAssertNotNil(substringScore)
        XCTAssertLessThan(prefixScore!, substringScore!, "Prefix match should score lower (better) than substring match")
    }

    func testPrefixMatchScores0_1() {
        let score = FuzzyMatcher.score(query: "em", candidate: "email")
        XCTAssertEqual(score, 0.1, "Prefix match should score 0.1")
    }

    // MARK: - Substring Match

    func testSubstringMatchScores0_2() {
        let score = FuzzyMatcher.score(query: "ail", candidate: "email")
        XCTAssertEqual(score, 0.2, "Substring match should score 0.2")
    }

    func testSubstringMatchScoresBetterThanFuzzy() {
        let substringScore = FuzzyMatcher.score(query: "ail", candidate: "email")
        let fuzzyScore = FuzzyMatcher.score(query: "eml", candidate: "email")

        XCTAssertNotNil(substringScore)
        XCTAssertNotNil(fuzzyScore)
        XCTAssertLessThan(substringScore!, fuzzyScore!, "Substring match should score lower (better) than fuzzy match")
    }

    // MARK: - Fuzzy Match

    func testFuzzyMatchReturnsNonNilForSequentialChars() {
        // "eml" is not a prefix or substring of "email", but the characters appear in order.
        let score = FuzzyMatcher.score(query: "eml", candidate: "email")
        XCTAssertNotNil(score, "Character sequence match should return a score")
    }

    func testFuzzyMatchScoresInFuzzyRange() {
        let score = FuzzyMatcher.score(query: "eml", candidate: "email")
        XCTAssertNotNil(score)
        XCTAssertGreaterThanOrEqual(score!, 0.3, "Fuzzy score should be >= 0.3")
        XCTAssertLessThanOrEqual(score!, 1.0, "Fuzzy score should be <= 1.0")
    }

    func testConsecutiveCharsBonusProducesBetterScore() {
        // "em" is consecutive at the start of "email address"
        // "ea" is scattered — not consecutive.
        let consecutiveScore = FuzzyMatcher.score(query: "em", candidate: "email address")
        let scatteredScore = FuzzyMatcher.score(query: "ea", candidate: "email address")

        XCTAssertNotNil(consecutiveScore)
        XCTAssertNotNil(scatteredScore)
        // "em" matches as a prefix, so it will score 0.1 vs a substring match for "ea"
        XCTAssertLessThan(consecutiveScore!, scatteredScore!, "Consecutive chars should score lower (better)")
    }

    // MARK: - No Match

    func testNoMatchReturnsNil() {
        let score = FuzzyMatcher.score(query: "zzz", candidate: "email")
        XCTAssertNil(score, "Query with no matching characters should return nil")
    }

    func testCharactersOutOfOrderReturnsNil() {
        // "lme" — the characters exist in "email" but not in this order.
        let score = FuzzyMatcher.score(query: "lme", candidate: "email")
        XCTAssertNil(score, "Characters in wrong order should return nil")
    }

    // MARK: - Edge Cases

    func testEmptyQueryScoresZero() {
        let score = FuzzyMatcher.score(query: "", candidate: "email")
        XCTAssertEqual(score, 0.0, "Empty query should always score 0.0 (show all)")
    }

    func testScoringTierOrder() {
        // Verify the overall ranking: exact < prefix < substring < fuzzy
        let exact     = FuzzyMatcher.score(query: "email", candidate: "email")!
        let prefix    = FuzzyMatcher.score(query: "em",    candidate: "email")!
        let substring = FuzzyMatcher.score(query: "ail",   candidate: "email")!
        let fuzzy     = FuzzyMatcher.score(query: "eml",   candidate: "email")!

        XCTAssertLessThan(exact, prefix,    "Exact < Prefix")
        XCTAssertLessThan(prefix, substring, "Prefix < Substring")
        XCTAssertLessThan(substring, fuzzy,  "Substring < Fuzzy")
    }
}
