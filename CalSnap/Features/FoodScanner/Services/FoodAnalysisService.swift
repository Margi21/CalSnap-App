import Foundation

enum FoodAnalysisError: Error {
    case invalidImage
    case networkError(Error)
    case invalidResponse
    case decodingError
    case apiError(String)
}

@Observable
final class FoodAnalysisService {
    private let openAIAPIKey: String =
        "API_key"
    private let openAIEndpoint = "https://api.openai.com/v1/chat/completions"

    func analyzeFood(image: Data) async throws -> FoodAnalysisResponse {
        print("Debug: Starting food analysis")

        // Convert image to base64
        let base64Image = image.base64EncodedString()
        print("Debug: Image converted to base64")

        // Create the request body
        let request = OpenAIRequest(
            model: "gpt-4o-mini",
            temperature: 0.2,
            maxTokens: 400,
            responseFormat: ResponseFormat(
                type: "json_schema",
                jsonSchema: JsonSchemaWrapper(
                    name: "FoodNutritionAnalysis",
                    schema: Schema(
                        schema: "http://json-schema.org/draft-07/schema#",
                        description: "Detailed macro and calorie breakdown for a food dish",
                        type: "object",
                        required: [
                            "title",
                            "proteinGrams",
                            "carbsGrams",
                            "fatsGrams",
                            "healthScore",
                            "ingredients",
                            "dishCount",
                            "totalCalories"
                        ],
                        properties: NutritionProperties(
                            title: Property(type: "string"),
                            proteinGrams: Property(type: "integer"),
                            carbsGrams: Property(type: "integer"),
                            fatsGrams: Property(type: "integer"),
                            healthScore: IntegerProperty(type: "integer", minimum: 0, maximum: 100),
                            ingredients: IngredientsArrayProperty(
                                type: "array",
                                items: IngredientItemSchema(
                                    type: "object",
                                    required: ["name", "calories"],
                                    properties: IngredientProperties(
                                        name: Property(type: "string"),
                                        calories: Property(type: "number")
                                    )
                                )
                            ),
                            dishCount: IntegerProperty(type: "integer", minimum: nil, maximum: nil),
                            totalCalories: Property(type: "integer")
                        )
                    )
                )
            ),
            messages: [
                RequestMessage(
                    role: "system",
                    content: .text(
                        "You are an AI food analyzer. Analyze the image and provide detailed nutritional information in JSON format."
                    )
                ),
                RequestMessage(
                    role: "user",
                    content: .array([
                        ContentItem(
                            type: "text",
                            text:
                                "Analyze this food image and list all visible food items with their estimated calories.",
                            imageUrl: nil
                        ),
                        ContentItem(
                            type: "image_url",
                            text: nil,
                            imageUrl: ImageURL(
                                url: "data:image/jpeg;base64,\(base64Image)",
                                detail: "high"
                            )
                        ),
                    ])
                ),
            ]
        )

        // Create URLRequest
        var urlRequest = URLRequest(url: URL(string: openAIEndpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = 30

        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let dummyResponse = """
{
    "id": "chatcmpl-BanMQNEdG1cxf0ffcJzpHYfmx0LOt",
    "object": "chat.completion",
    "created": 1748109250,
    "model": "gpt-4o-mini-2024-07-18",
    "choices": [
        {
            "index": 0,
            "message": {
                "role": "assistant",
                "content": "{\\"description\\":\\"Detailed macro and calorie breakdown for a food dish.\\",\\"type\\":\\"object\\",\\"properties\\":{\\"title\\":\\"Seared Tuna Bowl with Vegetables and Rice\\",\\"proteinGrams\\":35,\\"carbsGrams\\":50,\\"fatsGrams\\":20,\\"healthScore\\":8,\\"ingredients\\":[{\\"name\\":\\"Seared Tuna\\",\\"calories\\":200},{\\"name\\":\\"Brown Rice\\",\\"calories\\":150},{\\"name\\":\\"Corn\\",\\"calories\\":70},{\\"name\\":\\"Snap Peas\\",\\"calories\\":30},{\\"name\\":\\"Grilled Asparagus\\",\\"calories\\":40},{\\"name\\":\\"Avocado\\",\\"calories\\":160},{\\"name\\":\\"Sesame Seeds\\",\\"calories\\":50},{\\"name\\":\\"Soft Boiled Egg\\",\\"calories\\":70},{\\"name\\":\\"Green Onions\\",\\"calories\\":10}],\\"dishCount\\":1,\\"totalCalories\\":780}}",
                "refusal": null,
                "annotations": []
            },
            "logprobs": null,
            "finish_reason": "stop"
        }
    ],
    "usage": {
        "prompt_tokens": 14322,
        "completion_tokens": 167,
        "total_tokens": 14489,
        "prompt_tokens_details": {
            "cached_tokens": 0,
            "audio_tokens": 0
        },
        "completion_tokens_details": {
            "reasoning_tokens": 0,
            "audio_tokens": 0,
            "accepted_prediction_tokens": 0,
            "rejected_prediction_tokens": 0
        }
    },
    "service_tier": "default",
    "system_fingerprint": "fp_92e0377081"
}
"""
            // Convert dummy response to Data
            guard let dummyData = dummyResponse.data(using: .utf8) else {
                throw FoodAnalysisError.invalidResponse
            }
            
            print("Debug: Using dummy response data")
            
            // Use dummy data instead of making API call
            let openAIResponse = try JSONDecoder().decode(ChatCompletionResponse.self, from: dummyData)
            
            guard let content = openAIResponse.choices.first?.message.content else {
                print("Debug: No content in choices")
                throw FoodAnalysisError.invalidResponse
            }

            print("Debug: Response content:")
            print(content)

            // Try to parse the content as JSON
            do {
                // Extract the JSON string from the markdown code block if present
                let jsonString: String
                if content.contains("```json") && content.contains("```") {
                    let pattern = "```json\\n(.+?)\\n```"
                    let regex = try NSRegularExpression(
                        pattern: pattern, options: [.dotMatchesLineSeparators])
                    let range = NSRange(content.startIndex..., in: content)

                    if let match = regex.firstMatch(in: content, options: [], range: range),
                        let jsonRange = Range(match.range(at: 1), in: content)
                    {
                        jsonString = String(content[jsonRange])
                    } else {
                        jsonString = content
                    }
                } else {
                    jsonString = content
                }

                print("Debug: Extracted JSON string:")
                print(jsonString)

                let jsonData = jsonString.data(using: .utf8) ?? Data()
                let json = try JSONSerialization.jsonObject(with: jsonData, options: [])
                let finalData = try JSONSerialization.data(
                    withJSONObject: json, options: .prettyPrinted)
                let analysisResponse = try JSONDecoder().decode(
                    FoodAnalysisResponse.self, from: finalData)
                print("Debug: Successfully parsed analysis response")
                return analysisResponse
            } catch {
                print("Debug: JSON parsing error: \(error)")
                throw FoodAnalysisError.decodingError
            }

        } catch {
            print("Debug: Error details: \(error)")
            if let decodingError = error as? DecodingError {
                print("Debug: Decoding error details:")
                switch decodingError {
                case .keyNotFound(let key, let context):
                    print("Debug: Missing key: \(key) at path: \(context.codingPath)")
                case .valueNotFound(let type, let context):
                    print("Debug: Missing value of type \(type) at path: \(context.codingPath)")
                case .typeMismatch(let type, let context):
                    print("Debug: Type mismatch: expected \(type) at path: \(context.codingPath)")
                default:
                    print("Debug: Other decoding error: \(decodingError)")
                }
            }
            if let urlError = error as? URLError {
                print("Debug: URLError code: \(urlError.code.rawValue)")
                print("Debug: URLError description: \(urlError.localizedDescription)")
            }
            if let analysisError = error as? FoodAnalysisError {
                throw analysisError
            }
            throw FoodAnalysisError.networkError(error)
        }
    }
}
