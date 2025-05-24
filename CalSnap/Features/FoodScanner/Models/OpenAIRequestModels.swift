import Foundation

struct OpenAIRequest: Codable {
    let model: String
    let temperature: Double
    let maxTokens: Int
    let responseFormat: ResponseFormat
    let messages: [RequestMessage]
    
    enum CodingKeys: String, CodingKey {
        case model, temperature, messages
        case maxTokens = "max_tokens"
        case responseFormat = "response_format"
    }
}

struct ResponseFormat: Codable {
    let type: String
    let jsonSchema: JsonSchemaWrapper
    
    enum CodingKeys: String, CodingKey {
        case type
        case jsonSchema = "json_schema"
    }
}

struct JsonSchemaWrapper: Codable {
    let name: String
    let schema: Schema
}

struct Schema: Codable {
    let schema: String
    let description: String
    let type: String
    let required: [String]
    let properties: NutritionProperties
}

struct NutritionProperties: Codable {
    let title: Property
    let proteinGrams: Property
    let carbsGrams: Property
    let fatsGrams: Property
    let healthScore: IntegerProperty
    let ingredients: IngredientsArrayProperty
    let dishCount: IntegerProperty
    let totalCalories: Property
}

struct Property: Codable {
    let type: String
}

struct IntegerProperty: Codable {
    let type: String
    let minimum: Int?
    let maximum: Int?
}

struct IngredientsArrayProperty: Codable {
    let type: String
    let items: IngredientItemSchema
}

struct IngredientItemSchema: Codable {
    let type: String
    let required: [String]
    let properties: IngredientProperties
}

struct IngredientProperties: Codable {
    let name: Property
    let calories: Property
}

struct RequestMessage: Codable {
    let role: String
    let content: MessageContent
}

enum MessageContent: Codable {
    case text(String)
    case array([ContentItem])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let text = try? container.decode(String.self) {
            self = .text(text)
        } else if let array = try? container.decode([ContentItem].self) {
            self = .array(array)
        } else {
            throw DecodingError.typeMismatch(
                MessageContent.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for MessageContent")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .text(let text):
            try container.encode(text)
        case .array(let array):
            try container.encode(array)
        }
    }
}

struct ContentItem: Codable {
    let type: String
    let text: String?
    let imageUrl: ImageURL?
    
    enum CodingKeys: String, CodingKey {
        case type, text
        case imageUrl = "image_url"
    }
}

struct ImageURL: Codable {
    let url: String
    let detail: String
} 