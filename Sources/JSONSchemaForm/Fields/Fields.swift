import SwiftUI
import JSONSchema

enum FieldType: String {
    case AnyOfField
    case ArrayField
    case BooleanField
    case NumberField
    case ObjectField
    case OneOfField
    case SchemaField
    case StringField
    case NullField
}

/// Provides the default set of field components for the registry.
/// Corresponds to the function exported by `components/fields/index.ts` in RJSF.
///
/// - Returns: A dictionary mapping field type names to their corresponding `FieldComponent` (AnyView wrapping the specific field view).
func getDefaultFields() -> [FieldType: FieldComponent] {
    return [
        .AnyOfField: AnyView(MultiSchemaField()), // Assuming MultiSchemaField handles AnyOf
        .ArrayField: AnyView(ArrayField()),
        .BooleanField: AnyView(BooleanField()),
        .NumberField: AnyView(NumberField()),
        .ObjectField: AnyView(ObjectField()),
        .OneOfField: AnyView(MultiSchemaField()), // Assuming MultiSchemaField handles OneOf
        .SchemaField: AnyView(SchemaField()),   // The main dispatcher field
        .StringField: AnyView(StringField()),
        .NullField: AnyView(NullField())
    ]
    // Note: The generic types <T, S, F> might be needed for the actual
    // Field implementations later, but placeholders don't require them yet.
    // The AnyView type erasure handles the different underlying View types.
} 