/**
These are the example schemas from https://rjsf-team.github.io/react-jsonschema-form/
*/

let testSchema1 = """
    {
      "title": "A registration form",
      "description": "A simple form example.",
      "type": "object",
      "required": [
        "firstName",
        "lastName"
      ],
      "properties": {
        "firstName": {
          "type": "string",
          "title": "First name",
          "default": "Chuck"
        },
        "lastName": {
          "type": "string",
          "title": "Last name"
        },
        "age": {
          "type": "integer",
          "title": "Age"
        },
        "bio": {
          "type": "string",
          "title": "Bio"
        },
        "password": {
          "type": "string",
          "title": "Password",
          "minLength": 3
        },
        "telephone": {
          "type": "string",
          "title": "Telephone",
          "minLength": 10
        }
      }
    }
    """

let testSchema2 = """
    {}
    """

let testSchema3 = """
    {
      "title": "A list of tasks",
      "type": "object",
      "required": [
        "title"
      ],
      "properties": {
        "title": {
          "type": "string",
          "title": "Task list title"
        },
        "tasks": {
          "type": "array",
          "title": "Tasks",
          "items": {
            "type": "object",
            "required": [
              "title"
            ],
            "properties": {
              "title": {
                "type": "string",
                "title": "Title",
                "description": "A sample title"
              },
              "details": {
                "type": "string",
                "title": "Task details",
                "description": "Enter the task details"
              },
              "done": {
                "type": "boolean",
                "title": "Done?",
                "default": false
              }
            }
          }
        }
      }
    }
    """

let testSchema4 = """
    {
      "definitions": {
        "Thing": {
          "type": "object",
          "properties": {
            "name": {
              "type": "string",
              "default": "Default name"
            }
          }
        }
      },
      "type": "object",
      "properties": {
        "listOfStrings": {
          "type": "array",
          "title": "A list of strings",
          "items": {
            "type": "string",
            "default": "bazinga"
          }
        },
        "multipleChoicesList": {
          "type": "array",
          "title": "A multiple choices list",
          "items": {
            "type": "string",
            "enum": [
              "foo",
              "bar",
              "fuzz",
              "qux"
            ]
          },
          "uniqueItems": true
        },
        "fixedItemsList": {
          "type": "array",
          "title": "A list of fixed items",
          "items": [
            {
              "title": "A string value",
              "type": "string",
              "default": "lorem ipsum"
            },
            {
              "title": "a boolean value",
              "type": "boolean"
            }
          ],
          "additionalItems": {
            "title": "Additional item",
            "type": "number"
          }
        },
        "minItemsList": {
          "type": "array",
          "title": "A list with a minimal number of items",
          "minItems": 3,
          "items": {
            "$ref": "#/definitions/Thing"
          }
        },
        "defaultsAndMinItems": {
          "type": "array",
          "title": "List and item level defaults",
          "minItems": 5,
          "default": [
            "carp",
            "trout",
            "bream"
          ],
          "items": {
            "type": "string",
            "default": "unidentified"
          }
        },
        "nestedList": {
          "type": "array",
          "title": "Nested list",
          "items": {
            "type": "array",
            "title": "Inner list",
            "items": {
              "type": "string",
              "default": "lorem ipsum"
            }
          }
        },
        "unorderable": {
          "title": "Unorderable items",
          "type": "array",
          "items": {
            "type": "string",
            "default": "lorem ipsum"
          }
        },
        "copyable": {
          "title": "Copyable items",
          "type": "array",
          "items": {
            "type": "string",
            "default": "lorem ipsum"
          }
        },
        "unremovable": {
          "title": "Unremovable items",
          "type": "array",
          "items": {
            "type": "string",
            "default": "lorem ipsum"
          }
        },
        "noToolbar": {
          "title": "No add, remove and order buttons",
          "type": "array",
          "items": {
            "type": "string",
            "default": "lorem ipsum"
          }
        },
        "fixedNoToolbar": {
          "title": "Fixed array without buttons",
          "type": "array",
          "items": [
            {
              "title": "A number",
              "type": "number",
              "default": 42
            },
            {
              "title": "A boolean",
              "type": "boolean",
              "default": false
            }
          ],
          "additionalItems": {
            "title": "A string",
            "type": "string",
            "default": "lorem ipsum"
          }
        }
      }
    }
    """

let testSchema5 = """
    {
    "type": "object",
    "title": "Number fields & widgets",
    "properties": {
        "number": {
        "title": "Number",
        "type": "number"
        },
        "integer": {
        "title": "Integer",
        "type": "integer"
        },
        "numberEnum": {
        "type": "number",
        "title": "Number enum",
        "enum": [
            1,
            2,
            3
        ]
        },
        "numberEnumRadio": {
        "type": "number",
        "title": "Number enum",
        "enum": [
            1,
            2,
            3
        ]
        },
        "integerRange": {
        "title": "Integer range",
        "type": "integer",
        "minimum": -50,
        "maximum": 50
        },
        "integerRangeSteps": {
        "title": "Integer range (by 10)",
        "type": "integer",
        "minimum": 50,
        "maximum": 100,
        "multipleOf": 10
        }
    }
    }
    """

let testSchema6 = """
    {
    "definitions": {
        "address": {
        "type": "object",
        "properties": {
            "street_address": {
            "type": "string"
            },
            "city": {
            "type": "string"
            },
            "state": {
            "type": "string"
            }
        },
        "required": [
            "street_address",
            "city",
            "state"
        ]
        },
        "node": {
        "type": "object",
        "properties": {
            "name": {
            "type": "string"
            },
            "children": {
            "type": "array",
            "items": {
                "$ref": "#/definitions/node"
            }
            }
        }
        }
    },
    "type": "object",
    "properties": {
        "billing_address": {
        "title": "Billing address",
        "$ref": "#/definitions/address"
        },
        "shipping_address": {
        "title": "Shipping address",
        "$ref": "#/definitions/address"
        },
        "tree": {
        "title": "Recursive references",
        "$ref": "#/definitions/node"
        }
    }
    }
    """

let testSchema7 = """
    {
      "title": "Property dependencies",
      "description": "These samples are best viewed without live validation.",
      "type": "object",
      "properties": {
        "unidirectional": {
          "title": "Unidirectional",
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "credit_card": {
              "type": "number"
            },
            "billing_address": {
              "type": "string"
            }
          },
          "required": [
            "name"
          ],
          "dependencies": {
            "credit_card": [
              "billing_address"
            ]
          }
        },
        "bidirectional": {
          "title": "Bidirectional",
          "description": "Dependencies are not bidirectional, you can, of course, define the bidirectional dependencies explicitly.",
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "credit_card": {
              "type": "number"
            },
            "billing_address": {
              "type": "string"
            }
          },
          "required": [
            "name"
          ],
          "dependencies": {
            "credit_card": [
              "billing_address"
            ],
            "billing_address": [
              "credit_card"
            ]
          }
        }
      }
    }
    """

let testSchema8 = """

    {
      "title": "Schema dependencies",
      "description": "These samples are best viewed without live validation.",
      "type": "object",
      "properties": {
        "simple": {
          "title": "Simple",
          "type": "object",
          "properties": {
            "name": {
              "type": "string"
            },
            "credit_card": {
              "type": "number"
            }
          },
          "required": [
            "name"
          ],
          "dependencies": {
            "credit_card": {
              "properties": {
                "billing_address": {
                  "type": "string"
                }
              },
              "required": [
                "billing_address"
              ]
            }
          }
        },
        "conditional": {
          "title": "Conditional",
          "$ref": "#/definitions/person"
        },
        "arrayOfConditionals": {
          "title": "Array of conditionals",
          "type": "array",
          "items": {
            "$ref": "#/definitions/person"
          }
        },
        "fixedArrayOfConditionals": {
          "title": "Fixed array of conditionals",
          "type": "array",
          "items": [
            {
              "title": "Primary person",
              "$ref": "#/definitions/person"
            }
          ],
          "additionalItems": {
            "title": "Additional person",
            "$ref": "#/definitions/person"
          }
        }
      },
      "definitions": {
        "person": {
          "title": "Person",
          "type": "object",
          "properties": {
            "Do you have any pets?": {
              "type": "string",
              "enum": [
                "No",
                "Yes: One",
                "Yes: More than one"
              ],
              "default": "No"
            }
          },
          "required": [
            "Do you have any pets?"
          ],
          "dependencies": {
            "Do you have any pets?": {
              "oneOf": [
                {
                  "properties": {
                    "Do you have any pets?": {
                      "enum": [
                        "No"
                      ]
                    }
                  }
                },
                {
                  "properties": {
                    "Do you have any pets?": {
                      "enum": [
                        "Yes: One"
                      ]
                    },
                    "How old is your pet?": {
                      "type": "number"
                    }
                  },
                  "required": [
                    "How old is your pet?"
                  ]
                },
                {
                  "properties": {
                    "Do you have any pets?": {
                      "enum": [
                        "Yes: More than one"
                      ]
                    },
                    "Do you want to get rid of any?": {
                      "type": "boolean"
                    }
                  },
                  "required": [
                    "Do you want to get rid of any?"
                  ]
                }
              ]
            }
          }
        }
      }
    }
    """

let testSchema9 = """

    {
      "title": "A customizable registration form",
      "description": "A simple form with additional properties example.",
      "type": "object",
      "required": [
        "firstName",
        "lastName"
      ],
      "additionalProperties": {
        "type": "string"
      },
      "properties": {
        "firstName": {
          "type": "string",
          "title": "First name"
        },
        "lastName": {
          "type": "string",
          "title": "Last name"
        }
      }
    }
    """

let testSchema10 = """
    {
    "title": "A customizable registration form",
    "description": "A simple form with pattern properties example.",
    "type": "object",
    "required": [
        "firstName",
        "lastName"
    ],
    "properties": {
        "firstName": {
        "type": "string",
        "title": "First name"
        },
        "lastName": {
        "type": "string",
        "title": "Last name"
        }
    },
    "patternProperties": {
        "^[a-z][a-zA-Z]+$": {
        "type": "string"
        }
    }
    }
    """

let testSchema11 = """
    {
      "type": "object",
      "properties": {
        "age": {
          "type": "integer",
          "title": "Age"
        },
        "items": {
          "type": "array",
          "items": {
            "type": "object",
            "anyOf": [
              {
                "properties": {
                  "foo": {
                    "type": "string"
                  }
                }
              },
              {
                "properties": {
                  "bar": {
                    "type": "string"
                  }
                }
              }
            ]
          }
        }
      },
      "anyOf": [
        {
          "title": "First method of identification",
          "properties": {
            "firstName": {
              "type": "string",
              "title": "First name",
              "default": "Chuck"
            },
            "lastName": {
              "type": "string",
              "title": "Last name"
            }
          }
        },
        {
          "title": "Second method of identification",
          "properties": {
            "idCode": {
              "type": "string",
              "title": "ID code"
            }
          }
        }
      ]
    }
    """

let testSchema12 = """
    {
      "type": "object",
      "oneOf": [
        {
          "properties": {
            "lorem": {
              "type": "string"
            }
          },
          "required": [
            "lorem"
          ]
        },
        {
          "properties": {
            "ipsum": {
              "type": "string"
            }
          },
          "required": [
            "ipsum"
          ]
        }
      ]
    }
    """

let testSchema13 = """

    {
      "type": "object",
      "allOf": [
        {
          "properties": {
            "lorem": {
              "type": [
                "string",
                "boolean"
              ],
              "default": true
            }
          }
        },
        {
          "properties": {
            "lorem": {
              "type": "boolean"
            },
            "ipsum": {
              "type": "string"
            }
          }
        }
      ]
    }
    """

let testSchema14 = """
    {
      "type": "object",
      "properties": {
        "animal": {
          "enum": [
            "Cat",
            "Fish"
          ]
        }
      },
      "allOf": [
        {
          "if": {
            "properties": {
              "animal": {
                "const": "Cat"
              }
            }
          },
          "then": {
            "properties": {
              "food": {
                "type": "string",
                "enum": [
                  "meat",
                  "grass",
                  "fish"
                ]
              }
            },
            "required": [
              "food"
            ]
          }
        },
        {
          "if": {
            "properties": {
              "animal": {
                "const": "Fish"
              }
            }
          },
          "then": {
            "properties": {
              "food": {
                "type": "string",
                "enum": [
                  "insect",
                  "worms"
                ]
              },
              "water": {
                "type": "string",
                "enum": [
                  "lake",
                  "sea"
                ]
              }
            },
            "required": [
              "food",
              "water"
            ]
          }
        },
        {
          "required": [
            "animal"
          ]
        }
      ]
    }
    """

let testSchema15 = """
    {
      "title": "Null field example",
      "description": "A short form with a null field",
      "type": "object",
      "required": [
        "firstName"
      ],
      "properties": {
        "helpText": {
          "title": "A null field",
          "description": "Null fields like this are great for adding extra information",
          "type": "null"
        },
        "firstName": {
          "type": "string",
          "title": "A regular string field",
          "default": "Chuck"
        }
      }
    }
    """

let testSchema16 = """
    {
      "definitions": {
        "locations": {
          "enum": [
            {
              "name": "New York",
              "lat": 40,
              "lon": 74
            },
            {
              "name": "Amsterdam",
              "lat": 52,
              "lon": 5
            },
            {
              "name": "Hong Kong",
              "lat": 22,
              "lon": 114
            }
          ]
        }
      },
      "type": "object",
      "properties": {
        "location": {
          "title": "Location",
          "$ref": "#/definitions/locations"
        },
        "locationRadio": {
          "title": "Location Radio",
          "$ref": "#/definitions/locations"
        },
        "multiSelect": {
          "title": "Locations",
          "type": "array",
          "uniqueItems": true,
          "items": {
            "$ref": "#/definitions/locations"
          }
        },
        "checkboxes": {
          "title": "Locations Checkboxes",
          "type": "array",
          "uniqueItems": true,
          "items": {
            "$ref": "#/definitions/locations"
          }
        }
      }
    }
    """

let testSchema17 = """

    {
      "title": "A registration form (nullable)",
      "description": "A simple form example using nullable types",
      "type": "object",
      "required": [
        "firstName",
        "lastName"
      ],
      "properties": {
        "firstName": {
          "type": "string",
          "title": "First name",
          "default": "Chuck"
        },
        "lastName": {
          "type": "string",
          "title": "Last name"
        },
        "age": {
          "type": [
            "integer",
            "null"
          ],
          "title": "Age"
        },
        "bio": {
          "type": [
            "string",
            "null"
          ],
          "title": "Bio"
        },
        "password": {
          "type": "string",
          "title": "Password",
          "minLength": 3
        },
        "telephone": {
          "type": "string",
          "title": "Telephone",
          "minLength": 10
        }
      }
    }
    """

let testSchema18 = """
    {
      "title": "Schema default properties",
      "type": "object",
      "properties": {
        "valuesInFormData": {
          "title": "Values in form data",
          "$ref": "#/definitions/defaultsExample"
        },
        "noValuesInFormData": {
          "title": "No values in form data",
          "$ref": "#/definitions/defaultsExample"
        }
      },
      "definitions": {
        "defaultsExample": {
          "type": "object",
          "properties": {
            "scalar": {
              "title": "Scalar",
              "type": "string",
              "default": "scalar default"
            },
            "array": {
              "title": "Array",
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "nested": {
                    "title": "Nested array",
                    "type": "string",
                    "default": "nested array default"
                  }
                }
              }
            },
            "object": {
              "title": "Object",
              "type": "object",
              "properties": {
                "nested": {
                  "title": "Nested object",
                  "type": "string",
                  "default": "nested object default"
                }
              }
            }
          }
        }
      }
    }
    """

let testSchema19 = """
    {
      "$id": "https://jsonschema.dev/schemas/examples/non-negative-integer-bundle",
      "$schema": "https://json-schema.org/draft/2020-12/schema",
      "description": "Must be a non-negative integer",
      "$defs": {
        "https://jsonschema.dev/schemas/mixins/integer": {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$id": "https://jsonschema.dev/schemas/mixins/integer",
          "description": "Must be an integer",
          "type": "integer"
        },
        "https://jsonschema.dev/schemas/mixins/non-negative": {
          "$schema": "https://json-schema.org/draft/2020-12/schema",
          "$id": "https://jsonschema.dev/schemas/mixins/non-negative",
          "description": "Not allowed to be negative",
          "minimum": 0
        },
        "nonNegativeInteger": {
          "allOf": [
            {
              "$ref": "/schemas/mixins/integer"
            },
            {
              "$ref": "/schemas/mixins/non-negative"
            }
          ]
        }
      },
      "properties": {
        "num": {
          "$ref": "#/$defs/nonNegativeInteger"
        }
      }
    }
    """
