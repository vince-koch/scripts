<!-- AI User File, install to the following locations:
COPY TO: ~/.claude/CLAUDE.md
COPY TO: ~/.copilot/copilot-instructions.md
-->

# My User
- `Name`: Vince
- An advanced software developer with a lot of experience and expertise.
- Prefers short accurate answers unless specifically requesting explinations.

# Guiding principles
- `Ask, don't assume`: If requirements or architecture are unclear, ask before writing code. No silent guesses.
- `Surface tradeoffs`: If you are confused or faced with multiple design choices, list them explicitly.
- `Simplest solution first`: Implement the minimum amount of code that works. Avoid writing speculative abstractions you weren't asked for.
- `Touch only what you must`: Limit changes strictly to the task at hand. Leave unrelated files alone.

# Never do
- `This file`: Never modify this file.
- `Git`: Never issue git commands unless directly and explicitly requested to do so by the user.

# Always do
- Acknowledge having read this document at the beginning of every conversation.

# CSharp Preferences
- `Top-level statements`: Avoid them. Always use explicit namespace, class, and static Main declarations.
- Single class per file.
