# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
# Build the package
swift build

# Run tests
swift test

# Run a specific test
swift test --filter JSONSchemaFormStringTests

# Clean build artifacts
swift package clean
```

## Architecture

This is a SwiftUI library for rendering dynamic forms from JSON Schema, inspired by react-jsonschema-form (RJSF). It requires Swift 6.0, macOS 15+, and iOS 17+.

### Core Components

**JSONSchemaForm** ([JSONSchemaForm.swift](Sources/JSONSchemaForm/JSONSchemaForm.swift)) - Main entry point. Takes a `JSONSchema`, optional `uiSchema`, and `Binding<FormData>`. Handles form state, validation, and submission.

**FormData** ([Types/FormData.swift](Sources/JSONSchemaForm/Types/FormData.swift)) - Type-safe enum representing form values:
- `.object(properties: [String: FormData])` - nested objects
- `.array(items: [FormData])` - arrays
- `.string(String)`, `.number(Double)`, `.boolean(Bool)`, `.null` - primitives

**Field Protocol** ([Fields/Fields.swift](Sources/JSONSchemaForm/Fields/Fields.swift)) - All field types implement `Field: View, Sendable`. Requires `schema`, `propertyName`, and computes `fieldTitle`.

**SchemaField** ([Fields/SchemaField.swift](Sources/JSONSchemaForm/Fields/SchemaField.swift)) - Router component that dispatches to appropriate field based on `schema.type`:
- `StringField`, `NumberField`, `BooleanField` - primitive types
- `ObjectField` - nested object schemas
- `ArrayField` - array schemas with add/remove functionality
- `EnumField` - selection from enum values

**Templates** ([Templates/](Sources/JSONSchemaForm/Templates/)) - Layout components wrapping fields. `FieldTemplate` provides the standard label/description/errors structure.

### Key Patterns

- Fields receive `Binding<FormData>` and update parent state through binding chain
- `uiSchema` dictionary customizes field rendering (widget type, placeholders, help text)
- Validation runs on submit (or live if `liveValidate: true`) using [Utils/Validation.swift](Sources/JSONSchemaForm/Utils/Validation.swift)

### Dependencies

- **swift-json-schema** (sirily11/swift-json-schema) - JSON Schema types and parsing
- **swift-collections** - OrderedDictionary for property ordering
- **ViewInspector** (test only) - SwiftUI view testing

## Testing

Tests use ViewInspector to inspect SwiftUI view hierarchy. Test files are in `Sources/JSONSchemaFormTests/`. Pattern:
```swift
let form = JSONSchemaForm(schema: schema, formData: binding)
let textField = try form.inspect().find(viewWithId: "root_fieldname").textField()
let value = try textField.input()
```
