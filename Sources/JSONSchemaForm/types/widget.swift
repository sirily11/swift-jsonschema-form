import JSONSchema
import SwiftUI

public struct WidgetProps<T, S: JSONSchema, F> {
    /** The generated id for this widget, used to provide unique `name`s and `id`s for the HTML field elements rendered by widgets */
    var id: String
    /** The unique name of the field, usually derived from the name of the property in the JSONSchema; Provided in support of custom widgets.*/
    var name: String
    /** The JSONSchema sub-schema object for this widget */
    var schema: JSONSchema
    /** The uiSchema for this widget */
    var uiSchema: UISchema<T, S, F>
    /** The current value for this widget */
    var value: Binding<Any>
    /** The required status of this widget */
    var required: Bool?
    /** A boolean value stating if the widget is disabled */
    var disabled: Bool?
    /** A boolean value stating if the widget is read-only */
    var readonly: Bool?
    /** A boolean value stating if the widget is hiding its errors */
    var hideError: Bool?
    /** A boolean value stating if the widget should auto-focus */
    var autoFocus: Bool?
    /** The placeholder for the widget, if any */
    var placeholder: String?
    /** A map of UI Options passed as a prop to the component, including the optional `enumOptions`
     * which is a special case on top of `UIOptionsType` needed only by widgets
     */
    var options: UIOptions
    /** The `formContext` object that you passed to `Form` */
    var formContext: Any?
    /** The input blur event handler; call it with the widget id and value */
    var onBlur: (String, Any) -> Void
    /** The value change event handler; call it with the new value every time it changes */
    var onChange: (Any, ErrorSchema<T>?, String?) -> Void
    /** The input focus event handler; call it with the widget id and value */
    var onFocus: (String, Any) -> Void
    /** The computed label for this widget, as a string */
    var label: String
    /** A boolean value, if true, will cause the label to be hidden. This is useful for nested fields where you don't want
     * to clutter the UI. Customized via `label` in the `UiSchema`
     */
    var hideLabel: Bool?
    /** A boolean value stating if the widget can accept multiple values */
    var multiple: Bool?
    /** An array of strings listing all generated error messages from encountered errors for this widget */
    var rawErrors: [String]?
    /** The `registry` object */
    var registry: Registry<T, S, F>
}

public struct UIOptions {
    /** The enum options list for a type that supports them */
    var enumOptions: [EnumOption]?
    // Additional UIOptions properties would go here
}

public struct EnumOption {
    var label: String
    var value: Any
}
