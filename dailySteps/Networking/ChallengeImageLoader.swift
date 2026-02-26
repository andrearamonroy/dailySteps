//
//  ChallengeImageLoader.swift
//  dailySteps
//
//  Created by Andrea on 2/26/26.
//

import Foundation
import CloudKit
import SwiftUI

class ChallengeImageCache {
    static let shared = ChallengeImageCache()
    private var cache: [String: UIImage] = [:]
    
    func image(for challengeID: String) -> UIImage? {
        cache[challengeID]
    }
    
    func store(_ image: UIImage, for challengeID: String) {
        cache[challengeID] = image
    }
}

struct ChallengeIconView: View {
    let challenge: CKRecord
    @State private var image: UIImage? = nil
    
    var fallbackIconName: String {
        challenge.challengeIconName // your existing logic as fallback
    }
    
    var body: some View {
        Group {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                // Fallback to asset catalog while loading
                Image(fallbackIconName)
                    .resizable()
                    .scaledToFit()
            }
        }
        .onAppear {
            loadIcon()
        }
    }
    
    private func loadIcon() {
        guard let challengeID = challenge["challengeID"] as? String else { return }
        
        // Check cache first
        if let cached = ChallengeImageCache.shared.image(for: challengeID) {
            self.image = cached
            return
        }
        
        // Load from CloudKit asset
        guard let asset = challenge["iconImage"] as? CKAsset,
              let url = asset.fileURL,
              let data = try? Data(contentsOf: url),
              let uiImage = UIImage(data: data) else { return }
        
        ChallengeImageCache.shared.store(uiImage, for: challengeID)
        self.image = uiImage
    }
}
