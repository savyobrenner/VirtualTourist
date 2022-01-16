//
//  GCDManager.swift
//  VirtualTourist
//
//  Created by Brenner on 16/01/22.
//

import Foundation

func performUIUpdatesOnMain(_ updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}

