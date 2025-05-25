import CoreData
import SwiftUI

class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    private init() {
        print("Debug: Initializing CoreDataManager")
    }
    
    // MARK: - Core Data stack
    lazy var persistentContainer: NSPersistentContainer = {
        print("Debug: Setting up persistent container")
        
        let container = NSPersistentContainer(name: "CalSnap")
        
        // Configure persistent store
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            .first?.appendingPathComponent("CalSnap.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL!)
        container.persistentStoreDescriptions = [description]
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error {
                print("Debug: Core Data failed to load: \(error.localizedDescription)")
                fatalError("Failed to load Core Data stack: \(error)")
            }
            print("Debug: Core Data loaded successfully at \(storeDescription.url?.path ?? "unknown location")")
        }
        
        // Configure automatic merge policy
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Core Data operations
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
                print("Debug: Context saved successfully")
            } catch {
                print("Debug: Error saving context: \(error)")
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
    
    func createFood(from analysisResult: FoodProperties, imageData: Data?, date: Date? = nil) -> Food {
        print("Debug: Creating new food entry")
        let food = Food(context: viewContext)
        food.id = UUID()
        food.title = analysisResult.title
        food.proteinGrams = Int32(analysisResult.proteinGrams)
        food.carbsGrams = Int32(analysisResult.carbsGrams)
        food.fatsGrams = Int32(analysisResult.fatsGrams)
        food.healthScore = Int32(analysisResult.healthScore)
        food.totalCalories = Int32(analysisResult.totalCalories)
        food.ingredients = analysisResult.ingredients.map { $0.name }
        food.dateAdded = date ?? Date()
        food.imageData = imageData
        
        saveContext()
        print("Debug: Food entry created with ID: \(food.id?.uuidString ?? "unknown")")
        return food
    }
    
    func fetchFoods() -> [Food] {
        print("Debug: Fetching all food entries")
        let request: NSFetchRequest<Food> = Food.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Food.dateAdded, ascending: false)]
        
        do {
            let foods = try viewContext.fetch(request)
            print("Debug: Fetched \(foods.count) food entries")
            return foods
        } catch {
            print("Debug: Error fetching foods: \(error)")
            return []
        }
    }
    
    func deleteFood(_ food: Food) {
        print("Debug: Deleting food entry: \(food.id?.uuidString ?? "unknown")")
        viewContext.delete(food)
        saveContext()
    }
    
    /// Update an existing Food entry with new properties and image data (Rule: Core Data, DebugLogs, Comments, RuleEcho)
    func updateFood(_ food: Food, with properties: FoodProperties, imageData: Data?, date: Date? = nil) {
        print("Debug: Updating food entry: \(food.id?.uuidString ?? "unknown")")
        food.title = properties.title
        food.proteinGrams = Int32(properties.proteinGrams)
        food.carbsGrams = Int32(properties.carbsGrams)
        food.fatsGrams = Int32(properties.fatsGrams)
        food.healthScore = Int32(properties.healthScore)
        food.totalCalories = Int32(properties.totalCalories)
        food.ingredients = properties.ingredients.map { $0.name }
        food.dateAdded = date ?? food.dateAdded
        food.imageData = imageData ?? food.imageData
        saveContext()
        print("Debug: Food entry updated with ID: \(food.id?.uuidString ?? "unknown")")
    }
} 
