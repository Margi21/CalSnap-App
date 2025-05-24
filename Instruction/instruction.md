# CalSnap – Product Requirements Document (PRD)

**Draft Date:** 24 May 2025  
**Authors:** Core Mobile Team / AI Services Squad  

---

## 1 · Project Overview  
Build an iOS application named **CalSnap** that uses AI (OpenAI LLM with image analysis) to evaluate meals from user‑captured images.

### Key Objectives  
- Allow users to quickly capture an image of their meal.  
- Automatically analyze the image to extract ingredients, total calories, and a health score.  
- Provide a simple interface for users to edit the results before saving.  
- Display a historical view of daily nutrient intake and meal logs, allowing easy tracking.

### Target Platform  
- **iOS (iPhone)**

### Tech Stack & Dependencies  
| Layer | Choice |
|-------|--------|
| Frontend | **SwiftUI** |
| Architecture | **MVVM** |
| OS Services | AVFoundation / UIImagePickerController |
| Networking | URLSession |
| Database | Core Data (local) |
| Backend Services | OpenAI Vision API; optional custom backend |

---

## 2 · Problem Statement  
Manual calorie logging is slow, error‑prone, and discourages long‑term engagement.  
Existing apps frequently return free‑text that must be parsed on‑device, causing crashes and schema drift.  
CalSnap must guarantee **strict JSON** output so the iOS app can decode responses directly with `Codable`.

---

## 3 · Reason for Choosing OpenAI Structured Output  
| Criterion | Rationale |
|-----------|-----------|
| Deterministic JSON | `response_format.type = "json_schema"` forces the model to emit exactly the fields we expect. |
| Reduced Client Logic | No fragile regex parsing on the device. |
| Smaller Payloads | JSON object ≈ 40 % smaller than natural‑language replies. |
| Future‑Proof | We can evolve the schema server‑side without an App Store release. |
| Developer Velocity | Mobile and backend teams share a single schema contract. |

---

## 4 · Goals & Success Metrics  
| Goal | KPI / Target |
|------|--------------|
| **Fast logging** | ≤ 3 s P95 round‑trip (LTE) |
| **Schema compliance** | ≥ 99 % responses pass JSON‑schema validation |
| **User retention** | +15 % D30 retention vs manual logging cohort |

---

## 5 · Feature List & Functional Requirements  

| # | Feature | Functional Highlights |
|---|---------|-----------------------|
| **0** | **Splash Screen** | Branded launch screen ≤ 2 s, optional health quote. |
| **1** | **Capture Food Image** | Tap **Scan Food**, open camera, preview & retake. |
| **2** | **Analyze Food** | Call OpenAI Vision with schema; display ingredients, calories, health score. |
| **3** | **Edit & Confirm** | Inline editing with validation; save locally. |
| **4** | **View History** | Scrollable date selector; daily calorie summary; edit/delete meals. |

Detailed per‑feature requirements are listed below.

### 0 · Splash Screen  
*Functional*  
- Show branded splash via `LaunchScreen.storyboard`; fade to SwiftUI view if needed.  

*Non‑Functional*  
- 60 FPS; visible ≤ 2 s on normal launches.  

*Error Handling*  
- If startup takes > 2 s, show activity indicator.

### 1 · Capture Food Image  
*Functional*  
- **Scan Food** opens camera.  
- Allow retake before analysis.  

*Non‑Functional*  
- Handle camera permissions gracefully.  

*Error Handling*  
- Fallback view if camera unavailable or permission denied.  
- Error banner if image not recognised as food.

### 2 · Analyze Food  
*Functional*  
- Send image to OpenAI with JSON‑schema response.  
- Parse and show `title`, `ingredients`, `caloriesPerGram`, `totalCalories`, `healthScore`.  

*Non‑Functional*  
- Retry with exponential back‑off on timeouts.  

*Error Handling*  
- Show retry / manual entry option on failure.

### 3 · Edit & Confirm Results  
*Functional*  
- Tap any field to edit; numeric validation.  
- **Done** persists entry.  

*Non‑Functional*  
- UI updates in < 100 ms; atomic Core Data save.  

*Error Handling*  
- Error banner & retry on save failure.

### 4 · View History  
*Functional*  
- Horizontal calendar scroller; per‑day summary; detail sheet for each meal.  

*Non‑Functional*  
- Lazy fetch; offline cached via Core Data.  

*Error Handling*  
- Empty‑state with **Tap to Retry** on database error.

---

## 6 · Non‑Functional Requirements  
- Average end‑to‑end latency ≤ 3 s (P95).  
- Offline grace period with queued requests.  
- GDPR: image discarded after response; PII encrypted at rest.

---

## 7 · LLM API Specification  

### 7.1 Schema  
```jsonc
{
  "name": "FoodNutritionAnalysis",
  "schema": {
    "$schema": "http://json-schema.org/draft-07/schema#",
    "description": "Calorie and ingredient breakdown for a single food image.",
    "type": "object",
    "required": [
      "title",
      "description",
      "ingredients",
      "caloriesPerGram",
      "totalGrams",
      "totalCalories",
      "healthScore"
    ],
    "properties": {
      "title":           { "type": "string" },
      "description":     { "type": "string" },
      "ingredients":     { "type": "array",  "items": { "type": "string" } },
      "caloriesPerGram": { "type": "number" },
      "totalGrams":      { "type": "number" },
      "totalCalories":   { "type": "number" },
      "healthScore":     { "type": "integer", "minimum": 0, "maximum": 100 }
    }
  }
}
```

### 7.2 Request Example  
```bash
curl -v https://api.openai.com/v1/chat/completions -H "Authorization: Bearer YOUR_OPENAI_API_KEY" -H "Content-Type: application/json" -d '{
  "model": "gpt-4o-mini",
  "temperature": 0.2,
  "max_tokens": 400,
  "response_format": {
    "type": "json_schema",
    "json_schema": {
      "name": "FoodNutritionAnalysis",
      "schema": { ... }       // ← paste full JSON schema from 7.1
    }
  },
  "messages": [
    { "role": "system",
      "content": "You are an AI calories calculator. Reply strictly with JSON matching the provided schema."},
    { "role": "user",
      "content": [
        { "type": "text", "text": "Analyse this food image."},
        { "type": "image_url",
          "image_url": {
            "url": "data:image/jpeg;base64,{{BASE64_IMAGE}}",
            "detail": "high"
          }}
      ]}
  ]
}'
```

### 7.3 Sample Response  
```json
{
  "title": "Stir-Fried Noodles with Vegetables",
  "description": "A delicious serving of stir-fried noodles topped with green onions and red bell peppers.",
  "ingredients": [
    "egg noodles",
    "soy sauce",
    "vegetable oil",
    "green onions",
    "red bell peppers",
    "garlic",
    "ginger"
  ],
  "caloriesPerGram": 2.5,
  "totalGrams": 300,
  "totalCalories": 750,
  "healthScore": 6
}
```

---

## 8 · Risks & Mitigations  
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Schema drift | Decoding crashes | CI test hits API nightly & validates JSON. |
| High latency | Poor UX | Resize image ≤ 1024 px, keep‑alive, CDN. |
| Nutrition inaccuracies | User trust | Show confidence bar; allow edits. |

---

## 9 · Dependencies  
- OpenAI account & API key.  
- Core Data stack.  

---