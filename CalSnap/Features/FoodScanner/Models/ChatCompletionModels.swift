import Foundation

// MARK: - Chat Completion Response Models
public struct ChatCompletionResponse: Codable {
    public let id: String
    public let object: String
    public let created: Int
    public let model: String
    public let choices: [Choice]
    public let usage: Usage
    public let serviceTier: String
    public let systemFingerprint: String
    
    public init(
        id: String,
        object: String,
        created: Int,
        model: String,
        choices: [Choice],
        usage: Usage,
        serviceTier: String,
        systemFingerprint: String
    ) {
        self.id = id
        self.object = object
        self.created = created
        self.model = model
        self.choices = choices
        self.usage = usage
        self.serviceTier = serviceTier
        self.systemFingerprint = systemFingerprint
    }

    enum CodingKeys: String, CodingKey {
        case id, object, created, model, choices, usage
        case serviceTier = "service_tier"
        case systemFingerprint = "system_fingerprint"
    }
}

public struct Choice: Codable {
    public let index: Int
    public let message: Message
    public let logprobs: Logprobs?
    public let finishReason: String?
    
    public init(
        index: Int,
        message: Message,
        logprobs: Logprobs? = nil,
        finishReason: String? = nil
    ) {
        self.index = index
        self.message = message
        self.logprobs = logprobs
        self.finishReason = finishReason
    }

    enum CodingKeys: String, CodingKey {
        case index, message, logprobs
        case finishReason = "finish_reason"
    }
}

public struct Message: Codable {
    public let role: String
    public let content: String?
    public let refusal: String?
    public let annotations: [Annotation]
    
    public init(
        role: String,
        content: String? = nil,
        refusal: String? = nil,
        annotations: [Annotation] = []
    ) {
        self.role = role
        self.content = content
        self.refusal = refusal
        self.annotations = annotations
    }
}

public struct Annotation: Codable {
    // Empty for now, will be expanded as needed
    public init() {}
}

public struct Logprobs: Codable {
    // Will be expanded when logprobs are used
    public init() {}
}

public struct Usage: Codable {
    public let promptTokens: Int
    public let completionTokens: Int
    public let totalTokens: Int
    public let promptTokensDetails: TokenDetails
    public let completionTokensDetails: TokenDetails
    
    public init(
        promptTokens: Int,
        completionTokens: Int,
        totalTokens: Int,
        promptTokensDetails: TokenDetails,
        completionTokensDetails: TokenDetails
    ) {
        self.promptTokens = promptTokens
        self.completionTokens = completionTokens
        self.totalTokens = totalTokens
        self.promptTokensDetails = promptTokensDetails
        self.completionTokensDetails = completionTokensDetails
    }

    enum CodingKeys: String, CodingKey {
        case promptTokens = "prompt_tokens"
        case completionTokens = "completion_tokens"
        case totalTokens = "total_tokens"
        case promptTokensDetails = "prompt_tokens_details"
        case completionTokensDetails = "completion_tokens_details"
    }
}

public struct TokenDetails: Codable {
    public let cachedTokens: Int?
    public let audioTokens: Int
    public let reasoningTokens: Int?
    public let acceptedPredictionTokens: Int?
    public let rejectedPredictionTokens: Int?
    
    public init(
        cachedTokens: Int? = nil,
        audioTokens: Int,
        reasoningTokens: Int? = nil,
        acceptedPredictionTokens: Int? = nil,
        rejectedPredictionTokens: Int? = nil
    ) {
        self.cachedTokens = cachedTokens
        self.audioTokens = audioTokens
        self.reasoningTokens = reasoningTokens
        self.acceptedPredictionTokens = acceptedPredictionTokens
        self.rejectedPredictionTokens = rejectedPredictionTokens
    }

    enum CodingKeys: String, CodingKey {
        case cachedTokens = "cached_tokens"
        case audioTokens = "audio_tokens"
        case reasoningTokens = "reasoning_tokens"
        case acceptedPredictionTokens = "accepted_prediction_tokens"
        case rejectedPredictionTokens = "rejected_prediction_tokens"
    }
}

public struct Ingredient: Codable {
    public let name: String
    public let calories: Int
    public init(name: String, calories: Int) {
        self.name = name
        self.calories = calories
    }
}

public struct FoodProperties: Codable {
    public var title: String
    public var proteinGrams: Int
    public var carbsGrams: Int
    public var fatsGrams: Int
    public var healthScore: Int
    public var ingredients: [Ingredient]
    public var dishCount: Int
    public var totalCalories: Int
    public init(title: String, proteinGrams: Int, carbsGrams: Int, fatsGrams: Int, healthScore: Int, ingredients: [Ingredient], dishCount: Int, totalCalories: Int) {
        self.title = title
        self.proteinGrams = proteinGrams
        self.carbsGrams = carbsGrams
        self.fatsGrams = fatsGrams
        self.healthScore = healthScore
        self.ingredients = ingredients
        self.dishCount = dishCount
        self.totalCalories = totalCalories
    }
}

public struct FoodAnalysisResponse: Codable {
    public var description: String?
    public var type: String?
    public var properties: FoodProperties
    public init(description: String?, type: String?, properties: FoodProperties) {
        self.description = description
        self.type = type
        self.properties = properties
    }
}