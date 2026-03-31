# Project AGENTS.md

## Project Goal
- This project is a people-centered todo list app.
- The app should open on a message-like home screen that shows cards for different people.
- Tapping a person's card should navigate to that person's dedicated todo list page.
- The top area of each todo list page should be a person-specific profile/info section that stores notes and contextual information about that person.

## Product Direction
- Treat each person as the primary unit of organization, not each task.
- The home screen should feel like a conversation inbox, but every entry represents a person and their todo context.
- The detail screen should clearly separate:
  - person information
  - todo progress
  - actionable task items

## Technical Requirements
- Use a modern Flutter project structure with clear separation of concerns.
- Use Material Design 3 as the primary UI system.
- Use `flutter_riverpod` for state management and UI data flow.
- Use `freezed` for data models and immutable state structures.
- Prefer generated or ecosystem-standard tooling instead of handwritten boilerplate when appropriate.

## Implementation Preferences
- Prefer feature-first structure for Flutter folders.
- Keep routing, theme, localization, and shared utilities under a clear `core/` area.
- Keep domain/application/presentation concerns separated when complexity justifies it.
- Do not put too many unrelated classes in a single file; split files when responsibilities differ.
- Do not mix data classes and UI code in the same file.
- Avoid packing multiple state, stateful widget, or other large widget classes into one file when they should be separated by responsibility.
- Avoid manually writing repetitive model classes when `freezed` can generate them.
- Do not handwrite immutable boilerplate such as `copyWith`, value equality, `hashCode`, or `toString` for models/state objects when `freezed` is a reasonable fit; prefer `freezed` first for typed immutable structures in this project.
- Prefer the existing localization solution in this project over introducing JSON/XML-based ad hoc localization.
- Reuse stable packages and established Flutter patterns instead of reinventing common infrastructure.

## Flutter Project Conventions

### Data Models
- Always use `freezed` + `json_serializable` for immutable models.
- Do not handwrite `==`, `hashCode`, `copyWith`, or constructors for model classes unless explicitly requested.
- If a new model is added, also update the corresponding `part` files and generator annotations.

### Layout
- Prefer `Row.spacing` and `Column.spacing` for uniform gaps.
- Do not insert `SizedBox(width/height)` between children unless:
  - the spacing is intentionally irregular, or
  - the gap is conditional / dynamic, or
  - compatibility with older Flutter SDK is required.

### Code Quality
- Keep widgets small and composable.
- Prefer const constructors when possible.
- Run formatter and analyzer after edits.
- When post-frame initialization is needed inside a `State`, prefer `LateInitMixin` + `lateInitState()` from `core/utils/useful_extension.dart` instead of calling `WidgetsBinding.instance.addPostFrameCallback` directly.

## UI Expectations
- Follow Material Design 3 principles:
  - expressive surfaces
  - rounded shapes
  - strong visual hierarchy
  - accessible spacing and touch targets
- The home screen should prioritize quick scanning of people and their latest todo context.
- The person detail page should make the profile section immediately visible before the todo list.
- Design should feel modern, clean, and optimized for everyday task tracking around real people.

## Output Standard
- Implementations should be pragmatic, maintainable, and easy to extend.
- Favor reusable widgets, typed models, and predictable state flow.
- Keep code generation workflows (`freezed`, Riverpod annotations if used) aligned with project conventions.
