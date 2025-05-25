# CalSnap - Food Nutrition Analysis App

A SwiftUI-based iOS application for analyzing food nutrition using computer vision and AI.

## Features

### Core Features
- 📸 Food Image Capture & Analysis
- 🔍 Real-time Nutrition Analysis using OpenAI Vision
- 📊 Macro Tracking (Protein, Carbs, Fats)
- 📅 Daily Food Journal
- 📈 Nutrition History
- ✏️ Edit & Update Food Entries

### UI Components
- Interactive Date Picker
- Daily Calories Summary Card
- Macro Distribution Cards
- Recently Eaten Food List
- Food Analysis Sheet
- Macro Editor

## Architecture

### MVVM Architecture
- **Views**: SwiftUI views for UI components
- **ViewModels**: Observable classes for business logic
- **Models**: Core Data entities and response models

### Key Components

#### ViewModels
- `FoodScannerViewModel`: Manages camera, food list, and date selection
- `FoodAnalysisViewModel`: Handles food analysis and results

#### Services
- `FoodAnalysisService`: Integrates with OpenAI for food analysis
- `CoreDataManager`: Manages persistent storage

#### Models
##### Core Data Entities
- `Food`
  - `id`: UUID
  - `title`: String
  - `proteinGrams`: Int32
  - `carbsGrams`: Int32
  - `fatsGrams`: Int32
  - `healthScore`: Int32
  - `ingredients`: [String]
  - `totalCalories`: Int32
  - `imageData`: Binary
  - `dateAdded`: Date

##### Response Models
- `FoodAnalysisResponse`
- `FoodProperties`
- `Ingredient`

## Features Directory Structure
```
CalSnap/
├── Features/
│   └── FoodScanner/
│       ├── Views/
│       │   ├── FoodScannerView.swift
│       │   ├── FoodAnalysisView.swift
│       │   ├── MacroEditorView.swift
│       │   └── Components/
│       ├── ViewModels/
│       │   ├── FoodScannerViewModel.swift
│       │   └── FoodAnalysisViewModel.swift
│       ├── Models/
│       │   └── ChatCompletionModels.swift
│       └── Services/
│           └── FoodAnalysisService.swift
├── Core/
│   └── CoreDataManager.swift
└── Models/
    └── Food.xcdatamodeld
```

## Debug Logging
- Camera state tracking
- Core Data operations
- API calls and responses
- Analysis progress
- Error handling 

## State Management
- `@Observable` for ViewModels
- `@Published` for reactive updates
- Core Data for persistence
- Environment injection for dependencies

## UI/UX Features
- Modern SwiftUI interface
- Dynamic type support
- Dark mode compatibility
- Gesture-based interactions
- Loading states & error handling
- Smooth animations
- Bottom sheet presentations 