import Foundation

/// Result of preprocessing a schema, including extracted conditionals
public struct PreprocessedSchema: Sendable {
    public let jsonString: String
    public let conditionals: [ConditionalSchema]

    public init(jsonString: String, conditionals: [ConditionalSchema]) {
        self.jsonString = jsonString
        self.conditionals = conditionals
    }
}

/// Preprocesses JSON Schema strings before parsing to handle features
/// not supported by the swift-json-schema library:
/// - $ref resolution
/// - Missing type fields
/// - Type arrays (nullable types)
/// - Tuple arrays
/// - if/then/else conditionals (extracted for runtime evaluation)
public enum SchemaPreprocessor {

    /// Preprocess a JSON schema string and extract conditionals
    public static func preprocessWithConditionals(_ jsonString: String) throws -> PreprocessedSchema {
        guard let data = jsonString.data(using: .utf8) else {
            throw PreprocessorError.invalidJSON("Invalid UTF-8 string")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PreprocessorError.invalidJSON("Root must be a JSON object")
        }

        // Process the schema and collect conditionals
        var conditionals: [ConditionalSchema] = []
        let definitions = extractDefinitions(from: json)
        let processed = processSchemaWithConditionals(
            json,
            definitions: definitions,
            conditionals: &conditionals
        )

        // Convert back to JSON string
        let outputData = try JSONSerialization.data(withJSONObject: processed, options: [.sortedKeys])
        guard let outputString = String(data: outputData, encoding: .utf8) else {
            throw PreprocessorError.invalidJSON("Failed to encode processed schema")
        }

        return PreprocessedSchema(jsonString: outputString, conditionals: conditionals)
    }

    /// Preprocess a JSON schema string to make it compatible with swift-json-schema
    public static func preprocess(_ jsonString: String) throws -> String {
        guard let data = jsonString.data(using: .utf8) else {
            throw PreprocessorError.invalidJSON("Invalid UTF-8 string")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw PreprocessorError.invalidJSON("Root must be a JSON object")
        }

        // Process the schema
        let processed = processSchema(json, definitions: extractDefinitions(from: json))

        // Convert back to JSON string
        let outputData = try JSONSerialization.data(withJSONObject: processed, options: [.sortedKeys])
        guard let outputString = String(data: outputData, encoding: .utf8) else {
            throw PreprocessorError.invalidJSON("Failed to encode processed schema")
        }

        return outputString
    }

    /// Extract definitions from the schema (supports both "definitions" and "$defs")
    /// Also builds a map of $id URLs to their schemas
    private static func extractDefinitions(from schema: [String: Any]) -> [String: Any] {
        var definitions: [String: Any] = [:]

        if let defs = schema["definitions"] as? [String: Any] {
            definitions.merge(defs) { _, new in new }
        }

        if let defs = schema["$defs"] as? [String: Any] {
            for (key, value) in defs {
                definitions[key] = value

                // Also index by $id if present (for URI-based refs)
                if let defSchema = value as? [String: Any],
                   let id = defSchema["$id"] as? String {
                    definitions[id] = value

                    // Also index by path portion of the URI (e.g., "/schemas/mixins/integer")
                    if let url = URL(string: id), !url.path.isEmpty {
                        definitions[url.path] = value
                    }
                }
            }
        }

        return definitions
    }

    /// Process a schema object recursively
    private static func processSchema(
        _ schema: [String: Any],
        definitions: [String: Any],
        visitedRefs: Set<String> = []
    ) -> [String: Any] {
        var result = schema

        // Handle $ref - resolve and inline the definition
        if let ref = schema["$ref"] as? String {
            // Check for circular reference
            if visitedRefs.contains(ref) {
                // Return a simple object schema to break the cycle
                var fallback: [String: Any] = ["type": "object"]
                if let title = schema["title"] as? String {
                    fallback["title"] = title
                }
                return fallback
            }

            if let resolved = resolveRef(ref, definitions: definitions) {
                // Track this ref to detect cycles
                var newVisited = visitedRefs
                newVisited.insert(ref)

                // Merge resolved schema with any local properties (like title)
                var merged = processSchema(resolved, definitions: definitions, visitedRefs: newVisited)
                // Keep local title/description if present
                if let title = schema["title"] as? String {
                    merged["title"] = title
                }
                if let description = schema["description"] as? String {
                    merged["description"] = description
                }
                return merged
            }
        }

        // Handle type arrays (nullable types like ["string", "null"])
        if let typeArray = schema["type"] as? [Any] {
            let types = typeArray.compactMap { $0 as? String }
            // Use first non-null type, or "string" as fallback
            let primaryType = types.first { $0 != "null" } ?? types.first ?? "string"
            result["type"] = primaryType
        }

        // Infer type if missing
        if result["type"] == nil && schema["$ref"] == nil {
            result["type"] = inferType(from: result)
        }

        // Handle complex enum values (convert objects to JSON strings)
        if let enumValues = result["enum"] as? [Any] {
            let simplifiedEnum = enumValues.map { value -> Any in
                if let dict = value as? [String: Any] {
                    // Convert object to JSON string representation
                    if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
                       let jsonString = String(data: data, encoding: .utf8) {
                        return jsonString
                    }
                    // Fallback: use "name" property if available
                    if let name = dict["name"] as? String {
                        return name
                    }
                    return "Object"
                }
                return value
            }
            result["enum"] = simplifiedEnum
        }

        // Process properties
        if var properties = result["properties"] as? [String: Any] {
            for (key, value) in properties {
                if let propSchema = value as? [String: Any] {
                    properties[key] = processSchema(propSchema, definitions: definitions, visitedRefs: visitedRefs)
                }
            }
            result["properties"] = properties
        }

        // Process items (for arrays)
        if let items = result["items"] {
            if let itemSchema = items as? [String: Any] {
                // Single items schema
                result["items"] = processSchema(itemSchema, definitions: definitions, visitedRefs: visitedRefs)
            } else if let itemsArray = items as? [[String: Any]] {
                // Tuple validation - convert to single schema (use first item)
                // Note: This is a simplification; full tuple support would need more work
                if let firstItem = itemsArray.first {
                    result["items"] = processSchema(firstItem, definitions: definitions, visitedRefs: visitedRefs)
                }
            }
        }

        // Process additionalItems
        if let additionalItems = result["additionalItems"] as? [String: Any] {
            result["additionalItems"] = processSchema(additionalItems, definitions: definitions, visitedRefs: visitedRefs)
        }

        // Process additionalProperties
        if let additionalProps = result["additionalProperties"] as? [String: Any] {
            result["additionalProperties"] = processSchema(additionalProps, definitions: definitions, visitedRefs: visitedRefs)
        }

        // Process oneOf
        if let oneOf = result["oneOf"] as? [[String: Any]] {
            result["oneOf"] = oneOf.map { processSchema($0, definitions: definitions, visitedRefs: visitedRefs) }
        }

        // Process anyOf
        if let anyOf = result["anyOf"] as? [[String: Any]] {
            result["anyOf"] = anyOf.map { processSchema($0, definitions: definitions, visitedRefs: visitedRefs) }
        }

        // Process allOf
        if let allOf = result["allOf"] as? [[String: Any]] {
            result["allOf"] = allOf.map { processSchema($0, definitions: definitions, visitedRefs: visitedRefs) }
        }

        // Process if/then/else (not fully supported, but process them)
        if let ifSchema = result["if"] as? [String: Any] {
            result["if"] = processSchema(ifSchema, definitions: definitions, visitedRefs: visitedRefs)
        }
        if let thenSchema = result["then"] as? [String: Any] {
            result["then"] = processSchema(thenSchema, definitions: definitions, visitedRefs: visitedRefs)
        }
        if let elseSchema = result["else"] as? [String: Any] {
            result["else"] = processSchema(elseSchema, definitions: definitions, visitedRefs: visitedRefs)
        }

        // Process dependencies - remove property dependencies (arrays) that swift-json-schema can't handle
        if let dependencies = result["dependencies"] as? [String: Any] {
            var cleanedDependencies: [String: Any] = [:]
            for (key, value) in dependencies {
                if let depSchema = value as? [String: Any] {
                    // Schema dependency - keep and process
                    cleanedDependencies[key] = processSchema(depSchema, definitions: definitions, visitedRefs: visitedRefs)
                }
                // Property dependencies (arrays like ["billing_address"]) are not supported by swift-json-schema
                // so we skip them rather than causing a parse error
            }
            if !cleanedDependencies.isEmpty {
                result["dependencies"] = cleanedDependencies
            } else {
                result.removeValue(forKey: "dependencies")
            }
        }

        // Remove definitions from output (they're now inlined)
        result.removeValue(forKey: "definitions")
        result.removeValue(forKey: "$defs")

        return result
    }

    /// Resolve a $ref to its definition
    private static func resolveRef(_ ref: String, definitions: [String: Any]) -> [String: Any]? {
        // Handle local references like "#/definitions/Thing" or "#/$defs/Thing"
        if ref.hasPrefix("#/definitions/") {
            let name = String(ref.dropFirst("#/definitions/".count))
            return definitions[name] as? [String: Any]
        }

        if ref.hasPrefix("#/$defs/") {
            let name = String(ref.dropFirst("#/$defs/".count))
            return definitions[name] as? [String: Any]
        }

        // Handle URI path refs like "/schemas/mixins/integer"
        if ref.hasPrefix("/") {
            return definitions[ref] as? [String: Any]
        }

        // Handle full URL refs
        if ref.hasPrefix("http://") || ref.hasPrefix("https://") {
            // Try full URL first
            if let resolved = definitions[ref] as? [String: Any] {
                return resolved
            }
            // Try path portion
            if let url = URL(string: ref), !url.path.isEmpty {
                return definitions[url.path] as? [String: Any]
            }
        }

        // Try direct lookup (for keys like "nonNegativeInteger")
        return definitions[ref] as? [String: Any]
    }

    /// Infer the type from schema contents
    private static func inferType(from schema: [String: Any]) -> String {
        // If it has properties, it's an object
        if schema["properties"] != nil || schema["additionalProperties"] != nil || schema["patternProperties"] != nil {
            return "object"
        }

        // If it has items, it's an array
        if schema["items"] != nil || schema["additionalItems"] != nil {
            return "array"
        }

        // If it has string-specific keywords
        if schema["minLength"] != nil || schema["maxLength"] != nil || schema["pattern"] != nil {
            return "string"
        }

        // If it has number-specific keywords
        if schema["minimum"] != nil || schema["maximum"] != nil || schema["multipleOf"] != nil {
            return "number"
        }

        // If it has oneOf/anyOf/allOf, don't add type (library handles these)
        if schema["oneOf"] != nil || schema["anyOf"] != nil || schema["allOf"] != nil {
            // Return object as default - the combinators will override
            return "object"
        }

        // Default to object for empty schemas
        return "object"
    }

    /// Process a schema object recursively and extract conditionals
    private static func processSchemaWithConditionals(
        _ schema: [String: Any],
        definitions: [String: Any],
        visitedRefs: Set<String> = [],
        conditionals: inout [ConditionalSchema]
    ) -> [String: Any] {
        var result = schema

        // Handle $ref - resolve and inline the definition
        if let ref = schema["$ref"] as? String {
            // Check for circular reference
            if visitedRefs.contains(ref) {
                // Return a simple object schema to break the cycle
                var fallback: [String: Any] = ["type": "object"]
                if let title = schema["title"] as? String {
                    fallback["title"] = title
                }
                return fallback
            }

            if let resolved = resolveRef(ref, definitions: definitions) {
                // Track this ref to detect cycles
                var newVisited = visitedRefs
                newVisited.insert(ref)

                // Merge resolved schema with any local properties (like title)
                var merged = processSchemaWithConditionals(
                    resolved,
                    definitions: definitions,
                    visitedRefs: newVisited,
                    conditionals: &conditionals
                )
                // Keep local title/description if present
                if let title = schema["title"] as? String {
                    merged["title"] = title
                }
                if let description = schema["description"] as? String {
                    merged["description"] = description
                }
                return merged
            }
        }

        // Handle type arrays (nullable types like ["string", "null"])
        if let typeArray = schema["type"] as? [Any] {
            let types = typeArray.compactMap { $0 as? String }
            // Use first non-null type, or "string" as fallback
            let primaryType = types.first { $0 != "null" } ?? types.first ?? "string"
            result["type"] = primaryType
        }

        // Infer type if missing
        if result["type"] == nil && schema["$ref"] == nil {
            result["type"] = inferType(from: result)
        }

        // Handle complex enum values (convert objects to JSON strings)
        if let enumValues = result["enum"] as? [Any] {
            let simplifiedEnum = enumValues.map { value -> Any in
                if let dict = value as? [String: Any] {
                    // Convert object to JSON string representation
                    if let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
                       let jsonString = String(data: data, encoding: .utf8) {
                        return jsonString
                    }
                    // Fallback: use "name" property if available
                    if let name = dict["name"] as? String {
                        return name
                    }
                    return "Object"
                }
                return value
            }
            result["enum"] = simplifiedEnum
        }

        // Process properties
        if var properties = result["properties"] as? [String: Any] {
            for (key, value) in properties {
                if let propSchema = value as? [String: Any] {
                    properties[key] = processSchemaWithConditionals(
                        propSchema,
                        definitions: definitions,
                        visitedRefs: visitedRefs,
                        conditionals: &conditionals
                    )
                }
            }
            result["properties"] = properties
        }

        // Process items (for arrays)
        if let items = result["items"] {
            if let itemSchema = items as? [String: Any] {
                // Single items schema
                result["items"] = processSchemaWithConditionals(
                    itemSchema,
                    definitions: definitions,
                    visitedRefs: visitedRefs,
                    conditionals: &conditionals
                )
            } else if let itemsArray = items as? [[String: Any]] {
                // Tuple validation - convert to single schema (use first item)
                if let firstItem = itemsArray.first {
                    result["items"] = processSchemaWithConditionals(
                        firstItem,
                        definitions: definitions,
                        visitedRefs: visitedRefs,
                        conditionals: &conditionals
                    )
                }
            }
        }

        // Process additionalItems
        if let additionalItems = result["additionalItems"] as? [String: Any] {
            result["additionalItems"] = processSchemaWithConditionals(
                additionalItems,
                definitions: definitions,
                visitedRefs: visitedRefs,
                conditionals: &conditionals
            )
        }

        // Process additionalProperties
        if let additionalProps = result["additionalProperties"] as? [String: Any] {
            result["additionalProperties"] = processSchemaWithConditionals(
                additionalProps,
                definitions: definitions,
                visitedRefs: visitedRefs,
                conditionals: &conditionals
            )
        }

        // Process oneOf
        if let oneOf = result["oneOf"] as? [[String: Any]] {
            result["oneOf"] = oneOf.map {
                processSchemaWithConditionals(
                    $0,
                    definitions: definitions,
                    visitedRefs: visitedRefs,
                    conditionals: &conditionals
                )
            }
        }

        // Process anyOf
        if let anyOf = result["anyOf"] as? [[String: Any]] {
            result["anyOf"] = anyOf.map {
                processSchemaWithConditionals(
                    $0,
                    definitions: definitions,
                    visitedRefs: visitedRefs,
                    conditionals: &conditionals
                )
            }
        }

        // Process allOf - extract if/then/else conditionals
        if let allOf = result["allOf"] as? [[String: Any]] {
            var cleanedAllOf: [[String: Any]] = []
            var hasConditionals = false

            for subSchema in allOf {
                // Check if this sub-schema contains if/then/else
                if let ifCondition = subSchema["if"] as? [String: Any] {
                    hasConditionals = true

                    // Extract the conditional
                    let processedCondition = processSchemaWithConditionals(
                        ifCondition,
                        definitions: definitions,
                        visitedRefs: visitedRefs,
                        conditionals: &conditionals
                    )

                    var processedThen: [String: Any]?
                    if let thenSchema = subSchema["then"] as? [String: Any] {
                        processedThen = processSchemaWithConditionals(
                            thenSchema,
                            definitions: definitions,
                            visitedRefs: visitedRefs,
                            conditionals: &conditionals
                        )
                    }

                    var processedElse: [String: Any]?
                    if let elseSchema = subSchema["else"] as? [String: Any] {
                        processedElse = processSchemaWithConditionals(
                            elseSchema,
                            definitions: definitions,
                            visitedRefs: visitedRefs,
                            conditionals: &conditionals
                        )
                    }

                    // Add to conditionals array
                    let conditional = ConditionalSchema(
                        condition: processedCondition,
                        thenSchema: processedThen,
                        elseSchema: processedElse
                    )
                    conditionals.append(conditional)

                    // Don't add this sub-schema to cleanedAllOf (we've extracted it)
                } else {
                    // Regular allOf sub-schema - process and keep it
                    let processed = processSchemaWithConditionals(
                        subSchema,
                        definitions: definitions,
                        visitedRefs: visitedRefs,
                        conditionals: &conditionals
                    )
                    cleanedAllOf.append(processed)
                }
            }

            // If we extracted conditionals, merge root-level properties into the first allOf schema
            // This ensures properties are accessible when the schema is parsed as type 'allOf'
            if hasConditionals, let rootProperties = result["properties"] as? [String: Any] {
                if cleanedAllOf.isEmpty {
                    // Create a new schema with the root properties
                    var baseSchema: [String: Any] = ["type": "object", "properties": rootProperties]
                    if let required = result["required"] as? [String] {
                        baseSchema["required"] = required
                    }
                    cleanedAllOf.insert(baseSchema, at: 0)
                } else {
                    // Merge root properties into the first allOf schema
                    var firstSchema = cleanedAllOf[0]
                    if var existingProps = firstSchema["properties"] as? [String: Any] {
                        for (key, value) in rootProperties {
                            if existingProps[key] == nil {
                                existingProps[key] = value
                            }
                        }
                        firstSchema["properties"] = existingProps
                    } else {
                        firstSchema["properties"] = rootProperties
                    }
                    if firstSchema["type"] == nil {
                        firstSchema["type"] = "object"
                    }
                    cleanedAllOf[0] = firstSchema
                }
                // Remove root-level properties since they're now in allOf
                result.removeValue(forKey: "properties")
            }

            // Update allOf with cleaned schemas (without if/then/else)
            if cleanedAllOf.isEmpty {
                result.removeValue(forKey: "allOf")
            } else {
                result["allOf"] = cleanedAllOf
            }
        }

        // Process top-level if/then/else (not inside allOf)
        if let ifCondition = result["if"] as? [String: Any] {
            let processedCondition = processSchemaWithConditionals(
                ifCondition,
                definitions: definitions,
                visitedRefs: visitedRefs,
                conditionals: &conditionals
            )

            var processedThen: [String: Any]?
            if let thenSchema = result["then"] as? [String: Any] {
                processedThen = processSchemaWithConditionals(
                    thenSchema,
                    definitions: definitions,
                    visitedRefs: visitedRefs,
                    conditionals: &conditionals
                )
            }

            var processedElse: [String: Any]?
            if let elseSchema = result["else"] as? [String: Any] {
                processedElse = processSchemaWithConditionals(
                    elseSchema,
                    definitions: definitions,
                    visitedRefs: visitedRefs,
                    conditionals: &conditionals
                )
            }

            // Add to conditionals array
            let conditional = ConditionalSchema(
                condition: processedCondition,
                thenSchema: processedThen,
                elseSchema: processedElse
            )
            conditionals.append(conditional)

            // Remove if/then/else from result (they're now in conditionals)
            result.removeValue(forKey: "if")
            result.removeValue(forKey: "then")
            result.removeValue(forKey: "else")
        }

        // Process dependencies
        if let dependencies = result["dependencies"] as? [String: Any] {
            var cleanedDependencies: [String: Any] = [:]
            for (key, value) in dependencies {
                if let depSchema = value as? [String: Any] {
                    // Schema dependency - keep and process
                    cleanedDependencies[key] = processSchemaWithConditionals(
                        depSchema,
                        definitions: definitions,
                        visitedRefs: visitedRefs,
                        conditionals: &conditionals
                    )
                }
            }
            if !cleanedDependencies.isEmpty {
                result["dependencies"] = cleanedDependencies
            } else {
                result.removeValue(forKey: "dependencies")
            }
        }

        // Remove definitions from output (they're now inlined)
        result.removeValue(forKey: "definitions")
        result.removeValue(forKey: "$defs")

        return result
    }

    enum PreprocessorError: Error {
        case invalidJSON(String)
    }
}
