# AI Assistant Foundation — 1.2.0+11

> **Superseded in part as of 1.8.** The local pipeline described here still
> exists and is still the default, but it is no longer the only mode: signed-in
> Premium accounts can opt in to a Gemini-backed remote assistant. The claims
> below about no external AI provider and unchanged Data Safety answers apply to
> the local mode only. See [`ai_assistant_gemini.md`](ai_assistant_gemini.md).

## Scope

Calcademy Assistant in 1.2.0 is a local, rule-based feature foundation. It is
not a general-purpose chatbot and does not call Gemini, OpenAI, Claude, or any
other external AI service. User prompts stay in temporary in-memory Riverpod
state and are not persisted or sent to a Calcademy backend.

This release includes no camera access, OCR, backend function, account, cloud
sync, or new telemetry. Gemini-backed assistance and camera/OCR are candidates
for later sprints and require separate architecture, consent, privacy, security,
and Data Safety reviews before implementation.

## Architecture

- `AiAssistantService` is the provider-neutral interface.
- `MockAiAssistantService` runs the local pipeline.
- `AiProblemClassifier` maps English and Turkish keywords to a supported intent.
- `AiToolPlanner` creates a safe plan using IDs that resolve through
  `CalcademyToolRegistry` and `FormulaRegistry`.
- `AiResponseComposer` creates bounded educational responses and notices.
- `AiAssistantController` enforces empty-input and 1000-character limits and
  keeps only session state.
- `AiToolCallPlan.prefillPayload` reserves future prefill metadata. No assistant
  prefill is submitted to a tool in this release.

## Supported intents

- scientific calculation
- graphing
- matrices and linear algebra
- equation solving
- calculus
- statistics and probability
- educational finance calculations
- linear programming
- integer programming
- operations research
- formula lookup
- unsupported and out-of-scope boundaries

The local classifier intentionally declines general chat, weather, news,
recipes, personal advice, legal or medical direction, exam cheating, and
investment recommendations. Unknown input receives the same bounded Calcademy
scope explanation rather than a fabricated answer.

## Financial disclaimer

Finance-related calculation guidance always includes this boundary:

> Financial calculations are for informational and educational purposes only
> and are not financial advice.

The Turkish UI provides the equivalent localized notice.

## Registry integration and routing

Tool suggestions are resolved with `CalcademyToolRegistry.byId`. Formula
suggestions are resolved with `FormulaRegistry.byId` or the registry search over
localized titles, descriptions, tags, variables, and formula text. The UI only
renders navigation actions for existing entries and absolute application routes.
Formula actions use `/formulas/:id`; invalid formula IDs are already handled by
the Formula Library's not-found state.

## Privacy and Data Safety

The assistant foundation does not change Calcademy's Data Safety answers:

- no prompt or chat message is sent to an external AI provider;
- no assistant history is written to SharedPreferences;
- no assistant backend or remote logging exists;
- no camera, photo, microphone, or OCR permission is added;
- existing AdMob behavior is unchanged, and the Assistant page has no banner.

The existing AdMob disclosure remains applicable to Home and Saved. It must not
be interpreted as assistant prompt transmission.

## Future sprint boundary

A later Gemini integration should use a backend-held credential, explicit
request/response contracts, allow-listed tool calls, prompt-injection defenses,
rate limits, redaction and retention rules, failure fallbacks, and an updated
privacy/Data Safety assessment. Camera/OCR should be reviewed independently and
must not be bundled into the provider integration without permission and data
flow review.

**That sprint landed in 1.8** and met each of those conditions; see
[`ai_assistant_gemini.md`](ai_assistant_gemini.md). Camera/OCR was deliberately
left out of it and still requires its own review.
