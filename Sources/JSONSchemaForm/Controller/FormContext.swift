import SwiftUI

// MARK: - Form Controller Environment Key

/// Environment key for accessing the form controller from child views.
///
/// This allows field components to access the form controller for
/// retrieving field-level errors and other form state.
struct FormControllerKey: EnvironmentKey {
    static let defaultValue: JSONSchemaFormController? = nil
}

// MARK: - Property Key Order Environment Key

/// Environment key for passing property key ordering to child views.
///
/// Maps field ID paths (e.g. "root", "root_address") to ordered property key arrays
/// that reflect the original JSON schema property definition order.
struct PropertyKeyOrderKey: EnvironmentKey {
    static let defaultValue: [String: [String]]? = nil
}

extension EnvironmentValues {
    /// The form controller managing the current form's state and validation.
    ///
    /// Use this in field components to access field-level errors:
    /// ```swift
    /// @Environment(\.formController) private var formController
    ///
    /// var fieldErrors: [String]? {
    ///     formController?.errorsForField(id)
    /// }
    /// ```
    var formController: JSONSchemaFormController? {
        get { self[FormControllerKey.self] }
        set { self[FormControllerKey.self] = newValue }
    }

    /// Property key ordering extracted from the raw JSON schema.
    ///
    /// Maps field ID paths to ordered property key arrays, preserving the
    /// original JSON property definition order.
    var propertyKeyOrder: [String: [String]]? {
        get { self[PropertyKeyOrderKey.self] }
        set { self[PropertyKeyOrderKey.self] = newValue }
    }
}
