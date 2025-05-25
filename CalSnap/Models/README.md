# Core Data Model

This directory contains the Core Data model for the CalSnap app.

## Model Structure

### Food Entity
- `id`: UUID - Unique identifier for the food entry
- `title`: String - Name of the food
- `proteinGrams`: Int32 - Protein content in grams
- `carbsGrams`: Int32 - Carbohydrate content in grams
- `fatsGrams`: Int32 - Fat content in grams
- `healthScore`: Int32 - Health score from 0-100
- `ingredients`: [String] - Array of ingredient names
- `totalCalories`: Int32 - Total calorie content
- `imageData`: Binary - The food image data
- `dateAdded`: Date - When the entry was created

## Usage
The Core Data stack is managed by `CoreDataManager` in `Core/CoreDataManager.swift`. 
The manager provides methods for:
- Creating new food entries
- Fetching existing entries
- Deleting entries
- Saving context changes

## Debug Logging
Debug logs are included throughout the Core Data operations to help track:
- Model initialization
- Persistent store loading
- CRUD operations
- Error handling 