# Formula Library foundation

## Architecture

Formula Library is a feature-first, offline module under
`lib/features/formula_library`. Domain models contain bilingual educational
content, the application layer owns search/filter and local favorites state,
and presentation widgets render responsive list and detail views.

`FormulaRegistry` is the single catalog source. `CalcademyToolRegistry` is a
separate application-level registry that maps stable tool IDs to localized
metadata, supported formula categories, routes, and optional input schemas.
Formula entries refer to tools by stable ID and carry a resolved route link.

## Categories

The initial catalog has nine categories: Mathematics, Algebra, Calculus,
Linear Algebra, Statistics & Probability, Finance, Engineering Economy,
Optimization, and Operations Research. Each category has an English and
Turkish label.

## Formula model

Each `FormulaEntry` has a stable ID, English/Turkish title and description,
category, display and plain-text formula, variables, worked examples, tags,
related tool links, difficulty, supported locales, and optional notes/warning.
Variables and examples also carry English and Turkish educational copy.

## Tool registry connection

The first registry covers the scientific calculator, graph plotter, matrix,
equation solver, calculus, statistics, financial calculator, linear
programming, integer programming, operations research, and saved workspaces.
The Formula Detail page uses the declared route to open an applicable tool.

## Future assistant readiness

No AI service, network API, camera, or OCR capability is part of this sprint.
The stable formula IDs, multilingual tags, related tool IDs, supported
categories, route mapping, and input schema metadata form a general registry
that a later assistant can query without coupling the domain to an AI vendor.

## Future prefill support

`supportsPrefill`, `inputSchema`, and `prefillSchema` reserve a typed metadata
boundary. A future sprint can add route query construction and per-tool input
validation while preserving current deep links. Current navigation intentionally
opens the relevant tool without injecting inputs.

Formula favorites use a dedicated SharedPreferences string-list key. They do
not alter Saved Calculations schema in this foundation sprint.
