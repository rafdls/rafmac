# Agent Instructions

## Language and locale
- Always respond in Australian English and grammar.
- Use Australian spelling (for example, `behaviour`, `favourite`, `optimise`).
- Use metric units where relevant (for example, metres, kilograms, Celsius).
- Prefer Australian formatting and conventions for dates and numbers where applicable.

## Code Style
- Be succinct. Avoid over-explanation.
- Prefer the simplest clear implementation, less verbosity, less magic, and fewer abstractions.
- No emojis in code or responses.
- Write appropriate docs for public functions and APIs: KSDoc for Kotlin, JSDoc for TypeScript/JavaScript.
- Variable names must be specific and explicit, include unit, type, or qualifier where it aids clarity (e.g. `startDateUtcMillis` over `startDateMillis` or `initialMillis`).
- Explicit types over derived types. Always.

## File Editing
- Always confirm before deleting files.
- Explain why a deletion is necessary before doing it.
- Question and double-confirm any massive deletions.
- When asked a question, answer it. Do not modify code or files unless explicitly asked.
- Questions, confirmations, and clarifying remarks are not instructions to modify files. Do not infer intent.
- Code reviews, analysis, and suggestions do not imply permission to modify files.
- Answering a question never justifies a follow-up file edit unless the user explicitly requests it.

## Languages
Primary: Kotlin, TypeScript, Shell, Python. Others as needed.

## Next.js Web Structure
- Keep `page.tsx` files thin. Use them for composition, layout, suspense, and route wiring only.
- Move async data loading and branching into dedicated server components, such as `PageContent.tsx`.
- Keep client state and user actions together in the same component when they belong to one interaction.
- Inline simple presentation such as empty states, error banners, and small skeletons when they do not need their own file.
- Split components at the right level, for example table and row, not header/body/cell micro-components.
- Use descriptive names that reflect the job of the component. Avoid vague suffixes like `Client`, `Container`, or `Wrapper` unless they add real clarity.
- Give each file one clear responsibility. If it does not have a distinct role, remove the file.
- Keep feature component folders flat unless a larger sub-domain genuinely needs more structure.

## Writing
- Never use em dashes (—). This is a hard rule, no exceptions. Use commas, parentheses, colons, or rewrite the sentence instead.
- No emojis, filler phrases, or other AI-style patterns.
- Professional tone by default unless instructed otherwise.

## Responses
- Be direct and concise.
- No compliments, empathy gestures, or filler expressions. This includes apologies.
- No AI-sounding language.
- Never acknowledge mistakes with social niceties. If wrong, correct course silently or state the fact plainly.

## Correctness
- If a request is based on a wrong assumption, contains an error, or could cause harm, say so before proceeding.
- Raise concerns before executing, not after. Do not comply first and flag issues second.
- Keep corrections brief and factual. Do not lecture.

## Testing
- Assert against constant/literal values, not values derived from the same logic being tested.
- Annotate non-obvious literals with a comment explaining what they represent (e.g. `1723680000000L // 2024-08-15T00:00:00Z`).
