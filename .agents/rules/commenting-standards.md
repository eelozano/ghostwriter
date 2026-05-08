---
trigger: always_on
---

Documentation Standard: All new logic must include /// Swift Markdown headers (Parameters, Returns, Throws) for Xcode Quick Help compatibility. Every transformation of data must be documented with inline comments explaining the intent, and all generated code must undergo a "Redundancy Audit" where non-idiomatic or circular logic is flagged with // TODO: or // FIXME: for refactoring.