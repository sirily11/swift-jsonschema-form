# JSONSchemaForm

A SwiftUI component for building forms from JSON Schema. This library provides a convenient way to generate dynamic forms based on a JSON Schema, with built-in validation and customization options.

## Features

- Generate forms automatically from JSON Schema
- Field validation based on schema constraints
- Custom validation support
- UI customization via uiSchema
- Support for all standard JSON Schema types:
  - String with various formats
  - Number/Integer with range validation
  - Boolean
  - Object (nested forms)
  - Array
- Error display and handling
- Form submission and data change events

## Installation

### Swift Package Manager

Add the package to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/JSONSchemaForm.git", .upToNextMajor(from: "1.0.0"))
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["JSONSchemaForm"]),
]
```

Or add it through Xcode:
1. Go to File > Swift Packages > Add Package Dependency
2. Enter the repository URL: `https://github.com/yourusername/JSONSchemaForm.git`
3. Choose the version you want

## Usage

### Basic Example

```swift
import SwiftUI
import JSONSchema
import JSONSchemaForm

struct ContentView: View {
    // Define your JSON Schema
    let schema: JSONSchema = .object(
        properties: [
            "name": .string(description: "Full name"),
            "email": .string(format: "email", description: "Email address"),
            "age": .integer(minimum: 18, description: "Age (must be 18 or older)"),
            "agreeToTerms": .boolean(description: "I agree to the terms and conditions")
        ],
        required: ["name", "email", "agreeToTerms"]
    )
    
    // Initial form data (optional)
    @State private var formData: [String: Any]? = nil
    
    var body: some View {
        VStack {
            // Render the form
            JSONSchemaForm(
                schema: schema,
                formData: formData,
                onChange: { newData in
                    // Handle data changes
                    if let data = newData as? [String: Any] {
                        self.formData = data
                    }
                },
                onSubmit: { data in
                    // Handle form submission
                    if let formData = data as? [String: Any] {
                        print("Form submitted with data: \(formData)")
                    }
                },
                onError: { errors in
                    // Handle validation errors
                    print("Validation errors: \(errors)")
                }
            )
        }
        .padding()
    }
}
```

### Customizing UI with uiSchema

Use a `uiSchema` to customize the appearance and behavior of form fields:

```swift
let uiSchema: [String: Any] = [
    "name": [
        "ui:autofocus": true,
        "ui:placeholder": "Enter your full name"
    ],
    "email": [
        "ui:placeholder": "email@example.com"
    ],
    "age": [
        "ui:widget": "updown"  // Use an up/down control instead of a text field
    ],
    "agreeToTerms": [
        "ui:widget": "radio"  // Use radio buttons instead of a checkbox
    ]
]

// Then in your view:
JSONSchemaForm(
    schema: schema,
    uiSchema: uiSchema,
    formData: formData,
    // ... other props
)
```

### Custom Validation

You can add custom validation logic that goes beyond JSON Schema validation:

```swift
let customValidate: (Any?, inout [String: Any]) -> Void = { formData, errorSchema in
    // Make sure we have form data as a dictionary
    guard let data = formData as? [String: Any] else { return }
    
    // Custom validation for name field
    if let name = data["name"] as? String {
        if name.count < 5 {
            if errorSchema["name"] == nil {
                errorSchema["name"] = ["__errors": ["Name must be at least 5 characters"]]
            } else if var nameErrors = errorSchema["name"] as? [String: Any] {
                if nameErrors["__errors"] == nil {
                    nameErrors["__errors"] = ["Name must be at least 5 characters"]
                } else if var errors = nameErrors["__errors"] as? [String] {
                    errors.append("Name must be at least 5 characters")
                    nameErrors["__errors"] = errors
                }
                errorSchema["name"] = nameErrors
            }
        }
    }
    
    // Add more custom validation as needed
}

// Then in your view:
JSONSchemaForm(
    schema: schema,
    uiSchema: uiSchema,
    formData: formData,
    customValidate: customValidate,
    // ... other props
)
```

### Advanced Schema Example

Create more complex forms with nested objects, arrays, and conditional logic:

```swift
let advancedSchema: JSONSchema = .object(
    properties: [
        "personalInfo": .object(
            properties: [
                "name": .string(),
                "email": .string(format: "email")
            ],
            required: ["name", "email"]
        ),
        "address": .object(
            properties: [
                "street": .string(),
                "city": .string(),
                "state": .enum(values: [
                    .string("CA"),
                    .string("NY"),
                    .string("TX")
                ]),
                "zipCode": .string(pattern: "^\\d{5}$")
            ],
            required: ["street", "city", "state", "zipCode"]
        ),
        "phoneNumbers": .array(
            items: .object(
                properties: [
                    "type": .enum(values: [.string("home"), .string("work"), .string("mobile")]),
                    "number": .string(pattern: "^\\d{3}-\\d{3}-\\d{4}$")
                ],
                required: ["type", "number"]
            ),
            minItems: 1
        )
    ],
    required: ["personalInfo"]
)
```

## Available Props

The `JSONSchemaForm` component accepts the following properties:

| Property | Type | Description |
|----------|------|-------------|
| `schema` | `JSONSchema` | The JSON Schema that defines the form structure (required) |
| `uiSchema` | `[String: Any]?` | Customization options for form appearance and behavior |
| `formData` | `Any?` | Initial data for the form |
| `onChange` | `((Any?) -> Void)?` | Called when form data changes |
| `onSubmit` | `((Any?) -> Void)?` | Called when form is submitted successfully |
| `onError` | `(([ValidationError]) -> Void)?` | Called when validation errors occur on submit |
| `formContext` | `[String: Any]?` | Context data passed to all fields |
| `liveValidate` | `Bool` | Whether to validate as the user types (default: false) |
| `showErrorList` | `Bool` | Whether to show error summary at the top (default: true) |
| `transformErrors` | `(([ValidationError]) -> [ValidationError])?` | Function to transform validation errors |
| `disabled` | `Bool` | Whether the entire form is disabled (default: false) |
| `readonly` | `Bool` | Whether the entire form is read-only (default: false) |
| `customValidate` | `((Any?, inout [String: Any]) -> Void)?` | Custom validation function |
| `idPrefix` | `String` | Prefix for form field IDs (default: "root") |
| `idSeparator` | `String` | Separator for nested field IDs (default: "_") |

## UI Schema Options

The `uiSchema` object lets you customize how the form is rendered:

### Global Options

- `ui:readonly`: Make all fields read-only
- `ui:disabled`: Disable all fields
- `ui:classNames`: Add custom CSS class names to the form

### Field-specific Options

For each field in your schema, you can specify:

- `ui:widget`: Override the default widget (e.g., "textarea", "select", "radio", "password")
- `ui:placeholder`: Add placeholder text to input fields
- `ui:autofocus`: Automatically focus on this field when the form loads
- `ui:help`: Help text to display below the field
- `ui:title`: Custom title for the field
- `ui:description`: Custom description for the field
- `ui:options`: Additional widget-specific options

## License

This project is available under the MIT License. See the LICENSE file for more info.
