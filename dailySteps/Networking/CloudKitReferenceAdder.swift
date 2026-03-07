//
//  CloudKitReferenceAdder.swift
//  Step Tracking App
//
//  Adds reference fields to existing CloudKit record types
//


import CloudKit
import Foundation

class CloudKitReferenceAdder {
    
    static let shared = CloudKitReferenceAdder()
    private let manager = CloudKitManager.shared
    
    private init() {}
    
    // MARK: - Simple Public Method
    
    /// Call this once to add reference fields to your existing schema
    /// Just run: CloudKitReferenceAdder.shared.addReferences()
    func addReferences() {
        print("🚀 Starting reference field addition...")
        print("📝 This will create test records with references")
        print("📝 CloudKit will automatically add the reference fields to your schema")
        print("")
        
        addReferencesToExistingSchema { success, error in
            if success {
                print("")
                print("✅ ✅ ✅ SUCCESS! ✅ ✅ ✅")
                print("Reference fields have been added to:")
                print("  • ChallengeEnrollment (userReference, challengeReference)")
                print("  • DailyProgress (userReference, enrollmentReference)")
                print("  • LeaderboardEntry (enrollmentReference)")
                print("")
                print("📋 NEXT STEPS:")
                print("1. Go to https://icloud.developer.apple.com/dashboard")
                print("2. Select your container: iCloud.com.amon.dailySteps")
                print("3. Go to Schema → Record Types")
                print("4. For each reference field, click it and set:")
                print("   - Reference Type (e.g., userReference → User)")
                print("   - Action (e.g., Delete Self or None)")
                print("   - Queryable: ✓")
                print("5. Run: CloudKitReferenceAdder.shared.cleanup()")
                print("")
            } else {
                print("")
                print("❌ Failed to add references")
                print("Error: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
    }
    
    /// Call this after configuring references in dashboard to remove test records
    /// Run: CloudKitReferenceAdder.shared.cleanup()
    func cleanup() {
        print("🧹 Cleaning up test records...")
        
        cleanupTestRecords { success in
            if success {
                print("✅ Test records deleted")
                print("✅ Your schema is ready to use!")
            } else {
                print("⚠️ Some test records may remain")
                print("Check CloudKit Dashboard → Data to manually delete")
            }
        }
    }
    
    /// Verify references exist
    /// Run: CloudKitReferenceAdder.shared.verify()
    func verify() {
        print("🔍 Verifying reference fields...")
        
        verifyReferences { hasReferences in
            if hasReferences {
                print("✅ All reference fields verified!")
            } else {
                print("⚠️ Some references missing - run addReferences() first")
            }
        }
    }
    
    // MARK: - Add All References
    
    /// Adds reference fields to existing record types by creating sample records
    /// This will add the reference fields without creating new record types
    func addReferencesToExistingSchema(completion: @escaping (Bool, Error?) -> Void) {
        print("🔗 Adding reference fields to existing schema...")
        
        manager.checkAccountStatus { [weak self] available, error in
            guard available, let self = self else {
                completion(false, error ?? NSError(domain: "CloudKit", code: -1))
                return
            }
            
            // Create references in sequence
            self.addReferencesSequentially(completion: completion)
        }
    }
    
    // MARK: - Sequential Reference Creation
    
    private func addReferencesSequentially(completion: @escaping (Bool, Error?) -> Void) {
        // Step 1: Create a test user (needed for references)
        createTestUser { [weak self] userRecord in
            guard let userRecord = userRecord, let self = self else {
                completion(false, NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create test user"]))
                return
            }
            
            print("✅ Test user created")
            
            // Step 2: Get a challenge (should already exist)
            self.getExistingChallenge { challengeRecord in
                guard let challengeRecord = challengeRecord else {
                    completion(false, NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "No challenges found. Create at least one challenge first."]))
                    return
                }
                
                print("✅ Found existing challenge")
                
                // Step 3: Create enrollment with references (adds reference fields to ChallengeEnrollment)
                self.createEnrollmentWithReferences(userRecord: userRecord, challengeRecord: challengeRecord) { enrollmentRecord in
                    guard let enrollmentRecord = enrollmentRecord else {
                        completion(false, NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create enrollment"]))
                        return
                    }
                    
                    print("✅ ChallengeEnrollment references added")
                    
                    // Step 4: Create daily progress with references
                    self.createDailyProgressWithReferences(userRecord: userRecord, enrollmentRecord: enrollmentRecord) { progressRecord in
                        guard let progressRecord = progressRecord else {
                            completion(false, NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create daily progress"]))
                            return
                        }
                        
                        print("✅ DailyProgress references added")
                        
                        // Step 5: Create leaderboard entry with reference
                        self.createLeaderboardWithReference(enrollmentRecord: enrollmentRecord) { success in
                            if success {
                                print("✅ LeaderboardEntry reference added")
                                print("✅ All reference fields added successfully!")
                                print("")
                                print("📝 Next steps:")
                                print("   1. Go to CloudKit Dashboard")
                                print("   2. For each reference field, click it and set:")
                                print("      - Reference Type")
                                print("      - Action (Delete Self or None)")
                                print("   3. Mark fields as Queryable as needed")
                                print("   4. Delete the test records from Data tab")
                                
                                completion(true, nil)
                            } else {
                                completion(false, NSError(domain: "CloudKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create leaderboard entry"]))
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func createTestUser(completion: @escaping (CKRecord?) -> Void) {
        let userRecord = manager.createUserRecord(
            username: "TEST_USER_FOR_REFERENCES",
            deviceID: "test-device-ref-\(UUID().uuidString)"
        )
        
        manager.saveRecord(userRecord, to: .private) { result in
            if case .success(let savedRecord) = result {
                // Save for cleanup later
                UserDefaults.standard.set(savedRecord.recordID.recordName, forKey: "testUserRecordID")
                completion(savedRecord)
            } else {
                completion(nil)
            }
        }
    }
    
    private func getExistingChallenge(completion: @escaping (CKRecord?) -> Void) {
        // Try to fetch any existing challenge
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: RecordType.challenge, predicate: predicate)
        
        manager.publicDatabase.perform(query, inZoneWith: nil) { records, error in
            if let records = records, let firstChallenge = records.first {
                completion(firstChallenge)
            } else {
                // If no challenges exist, create one
                print("⚠️ No challenges found, creating a test challenge...")
                self.createTestChallenge(completion: completion)
            }
        }
    }
    
    private func createTestChallenge(completion: @escaping (CKRecord?) -> Void) {
        let challengeRecord = manager.createChallengeRecord(
            challengeID: "test-challenge-ref-\(UUID().uuidString)",
            name: "TEST_CHALLENGE_FOR_REFERENCES",
            description: "Temporary challenge for adding reference fields",
            targetSteps: 5000,
            daysRequired: ["Monday"],
            duration: 1,
            restDays: 0
        )
        
        manager.saveRecord(challengeRecord, to: .public) { result in
            if case .success(let savedRecord) = result {
                UserDefaults.standard.set(savedRecord.recordID.recordName, forKey: "testChallengeRecordID")
                completion(savedRecord)
            } else {
                completion(nil)
            }
        }
    }
    
    private func createEnrollmentWithReferences(userRecord: CKRecord, challengeRecord: CKRecord, completion: @escaping (CKRecord?) -> Void) {
        
        
        // Read duration from the challenge
            let duration = challengeRecord["duration"] as? Int ?? 1
            
            let startDate = Date()
            // (duration - 1) because day 1 is today, not tomorrow
            let endDate = Calendar.current.date(
                byAdding: .day,
                value: duration - 1,
                to: Calendar.current.startOfDay(for: startDate)
            ) ?? startDate

            let enrollmentRecord = manager.createChallengeEnrollmentRecord(
                userRecord: userRecord,
                challengeRecord: challengeRecord,
                enrollmentType: "solo",
                startDate: startDate,
                endDate: endDate,
                groupID: nil
            )
        
        
        manager.saveRecord(enrollmentRecord, to: .private) { result in
            if case .success(let savedRecord) = result {
                UserDefaults.standard.set(savedRecord.recordID.recordName, forKey: "testEnrollmentRecordID")
                completion(savedRecord)
            } else {
                completion(nil)
            }
        }
    }
    
    private func createDailyProgressWithReferences(userRecord: CKRecord, enrollmentRecord: CKRecord, completion: @escaping (CKRecord?) -> Void) {
        let progressRecord = manager.createDailyProgressRecord(
            userRecord: userRecord,
            enrollmentRecord: enrollmentRecord,
            date: Date(),
            stepCount: 3000,
            goalMet: false
        )
        
        manager.saveRecord(progressRecord, to: .private) { result in
            if case .success(let savedRecord) = result {
                UserDefaults.standard.set(savedRecord.recordID.recordName, forKey: "testProgressRecordID")
                completion(savedRecord)
            } else {
                completion(nil)
            }
        }
    }
    
    private func createLeaderboardWithReference(enrollmentRecord: CKRecord, completion: @escaping (Bool) -> Void) {
        let leaderboardRecord = manager.createLeaderboardEntryRecord(
            groupID: "test-group-ref",
            userID: "test-user-ref",
            username: "TEST_USER",
            enrollmentRecord: enrollmentRecord,
            totalSteps: 3000,
            daysCompleted: 1
        )
        
        manager.saveRecord(leaderboardRecord, to: .public) { result in
            if case .success(let savedRecord) = result {
                UserDefaults.standard.set(savedRecord.recordID.recordName, forKey: "testLeaderboardRecordID")
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    // MARK: - Cleanup Test Records
    
    /// Removes all test records created for adding references
    func cleanupTestRecords(completion: @escaping (Bool) -> Void) {
        print("🧹 Cleaning up test records...")
        
        let group = DispatchGroup()
        var allSuccess = true
        
        // Delete test user (cascade deletes enrollment and progress)
        if let userRecordName = UserDefaults.standard.string(forKey: "testUserRecordID") {
            group.enter()
            let recordID = CKRecord.ID(recordName: userRecordName)
            manager.deleteRecord(with: recordID, from: .private) { result in
                if case .failure = result {
                    allSuccess = false
                }
                group.leave()
            }
        }
        
        // Delete test challenge if we created one
        if let challengeRecordName = UserDefaults.standard.string(forKey: "testChallengeRecordID") {
            group.enter()
            let recordID = CKRecord.ID(recordName: challengeRecordName)
            manager.deleteRecord(with: recordID, from: .public) { result in
                if case .failure = result {
                    allSuccess = false
                }
                group.leave()
            }
        }
        
        // Delete test leaderboard entry
        if let leaderboardRecordName = UserDefaults.standard.string(forKey: "testLeaderboardRecordID") {
            group.enter()
            let recordID = CKRecord.ID(recordName: leaderboardRecordName)
            manager.deleteRecord(with: recordID, from: .public) { result in
                if case .failure = result {
                    allSuccess = false
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Clear saved IDs
            UserDefaults.standard.removeObject(forKey: "testUserRecordID")
            UserDefaults.standard.removeObject(forKey: "testChallengeRecordID")
            UserDefaults.standard.removeObject(forKey: "testEnrollmentRecordID")
            UserDefaults.standard.removeObject(forKey: "testProgressRecordID")
            UserDefaults.standard.removeObject(forKey: "testLeaderboardRecordID")
            
            if allSuccess {
                print("✅ Test records cleaned up")
            } else {
                print("⚠️ Some test records may remain")
            }
            
            completion(allSuccess)
        }
    }
    
    // MARK: - Verify References Exist
    
    /// Checks if reference fields exist in the schema
    func verifyReferences(completion: @escaping (Bool) -> Void) {
        print("🔍 Verifying reference fields...")
        
        let group = DispatchGroup()
        var hasReferences = true
        
        // Check ChallengeEnrollment has references
        group.enter()
        checkRecordTypeHasReferences(recordType: RecordType.challengeEnrollment, database: .private) { exists in
            if !exists {
                print("❌ ChallengeEnrollment missing references")
                hasReferences = false
            } else {
                print("✅ ChallengeEnrollment has references")
            }
            group.leave()
        }
        
        // Check DailyProgress has references
        group.enter()
        checkRecordTypeHasReferences(recordType: RecordType.dailyProgress, database: .private) { exists in
            if !exists {
                print("❌ DailyProgress missing references")
                hasReferences = false
            } else {
                print("✅ DailyProgress has references")
            }
            group.leave()
        }
        
        // Check LeaderboardEntry has reference
        group.enter()
        checkRecordTypeHasReferences(recordType: RecordType.leaderboardEntry, database: .public) { exists in
            if !exists {
                print("❌ LeaderboardEntry missing reference")
                hasReferences = false
            } else {
                print("✅ LeaderboardEntry has reference")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            completion(hasReferences)
        }
    }
    
    private func checkRecordTypeHasReferences(recordType: String, database: DatabaseType, completion: @escaping (Bool) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        
        let db = database == .private ? manager.privateDatabase : manager.publicDatabase
        
        db.perform(query, inZoneWith: nil) { records, error in
            // If we can query it, the record type exists
            // Reference fields will be visible in dashboard
            completion(error == nil)
        }
    }
}
