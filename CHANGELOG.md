## 1.5.0

- `apiKey` is now **optional** in `KinesteXAIFramework.initialize()`. To use the
  session-token flow, omit the API key and pass the session id via `customParams`
  on any create*View call, e.g. `customParams: {'session': '<sessionId>'}` — the
  API key then never has to live in the app. The legacy API-key flow is unchanged
  (keep passing `apiKey` and nothing else changes).

## 1.2.0
