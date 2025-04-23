import SwiftUI

/// A structure holding the various button components used within the form.
/// Corresponds to the `ButtonTemplates` export in RJSF.
typealias ButtonComponent = AnyView // Use AnyView for flexibility

struct ButtonTemplates {
    var submitButton: ButtonComponent
    var addButton: ButtonComponent
    var copyButton: ButtonComponent
    var moveDownButton: ButtonComponent
    var moveUpButton: ButtonComponent
    var removeButton: ButtonComponent
}

/// Provides the default set of button templates.
/// Corresponds to the function exported by `components/templates/ButtonTemplates/index.ts`.
///
/// - Returns: A `ButtonTemplates` struct containing default button views.
func getDefaultButtonTemplates() -> ButtonTemplates {
    return ButtonTemplates(
        submitButton: AnyView(SubmitButton()),
        addButton: AnyView(AddButton()),
        copyButton: AnyView(CopyButton()),
        moveDownButton: AnyView(MoveDownButton()),
        moveUpButton: AnyView(MoveUpButton()),
        removeButton: AnyView(RemoveButton())
    )
} 