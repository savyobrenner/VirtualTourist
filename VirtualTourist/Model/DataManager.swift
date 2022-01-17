//
//  DataManager.swift
//  VirtualTourist
//
//  Created by Brenner on 16/01/22.
//

import Foundation
import CoreData

class DataManager {
    
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    init(modelName: String) {
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func load(completion: (()->Void)? = nil) {
        persistentContainer.loadPersistentStores { (storeDescription, error) in
            guard error == nil else {
                fatalError(error?.localizedDescription ?? "")
            }
            completion?()
        }
    }
}

