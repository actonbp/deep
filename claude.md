# Claude AI Contribution Guidelines

These rules are specifically directed at Anthropic's Claude models (any "claude-*" variants) when interacting with this repository.

Claude, please adhere to the following principles:

1. **Safety First**  
   • Never introduce breaking changes to the iOS app.  
   • If a migration is necessary, propose it in a separate PR with a clear rollback path.
2. **Small, Test-Driven Updates**  
   • Prefer surgical edits over sweeping refactors.  
   • Every functional change should include or update unit tests in `deep_appTests/`.
3. **Follow Established Conventions**  
   • Obey the Swift-style guidelines outlined in `cursor.mdc`.  
   • Keep code free of compiler warnings and `swiftlint` violations.  
   • Use Swift concurrency (`async/await`) where already adopted, but do **not** mix callback & async styles in new code.
4. **Documentation**  
   • Update README / docs when behaviour changes or new public APIs are added.  
   • Keep changelog entries concise.
5. **Security & Privacy**  
   • Do not log or commit sensitive tokens or user data.  
   • Any required secrets must use the existing `Secrets.plist` (debug) or a secure runtime mechanism (release).
6. **Ask When Unsure**  
   • If a decision could impact backwards-compatibility, open a discussion rather than guessing.

_Last updated: 2025-05-31_