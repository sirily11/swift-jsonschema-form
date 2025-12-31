import SwiftUI

// MARK: - Form Controller Environment Key

/// Environment key for accessing the form controller from child views.
///
/// This allows field components to access the form controller for
/// retrieving field-level errors and other form state.
struct FormControllerKey: EnvironmentKey {
    static let defaultValue: JSONSchemaFormController? = nil
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
}
