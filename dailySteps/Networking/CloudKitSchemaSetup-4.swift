//
//  CloudKitSchemaSetup.swift
//  Step Tracking App
//
//  CloudKit Schema Setup and Configuration
//

import CloudKit
import Foundation
import UIKit

// MARK: - CloudKit Configuration

/// Manages CloudKit container and database references
class CloudKitManager : ObservableObject {
    
    // MARK: - Singleton
    static let shared = CloudKitManager()
    
    // MARK: - Properties
    
    /// Main CloudKit container for the app
    let container: CKContainer
    
    /// Private database - stores user's personal data
    let privateDatabase: CKDatabase
    
    /// Public database - stores shared data like challenges and friend requests
    let publicDatabase: CKDatabase
    
    // Cache
        @Published var cachedChallenges: [CKRecord] = []
        private var lastFetchDate: Date?
        private let cacheExpirationInterval: TimeInterval = 300 // 5 minutes
        
    
    // MARK: - Initialization
    
    private init() {
        // Safely initialize container with error catching
        do {
            self.container = CKContainer(identifier: "iCloud.com.andrearamonroy.dailySteps")
            self.privateDatabase = container.privateCloudDatabase
            self.publicDatabase = container.publicCloudDatabase
            
            print("✅ CloudKit container initialized successfully")
        } catch {
            print("❌ CloudKit initialization failed: \(error)")
            fatalError("CloudKit setup failed")
        }
    }
    
    // MARK: - Account Status Check
    
    /// Check if user is signed into iCloud
    func checkAccountStatus(completion: @escaping (Bool, Error?) -> Void) {
        container.accountStatus { status, error in
            if let error = error {
                print("❌ CloudKit account error: \(error.localizedDescription)")
                completion(false, error)
                return
            }
            
            switch status {
            case .available:
                print("✅ CloudKit account available")
             
                
                completion(true, nil)
            case .noAccount:
                print("⚠️ No iCloud account")
                completion(false, NSError(domain: "CloudKit", code: 1, userInfo: [NSLocalizedDescriptionKey: "Please sign in to iCloud"]))
            case .restricted:
                print("⚠️ iCloud account restricted")
                completion(false, NSError(domain: "CloudKit", code: 2, userInfo: [NSLocalizedDescriptionKey: "iCloud access is restricted"]))
            case .couldNotDetermine:
                print("⚠️ Could not determine iCloud status")
                completion(false, NSError(domain: "CloudKit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Could not determine iCloud status"]))
            case .temporarilyUnavailable:
                print("⚠️ iCloud temporarily unavailable")
                completion(false, NSError(domain: "CloudKit", code: 4, userInfo: [NSLocalizedDescriptionKey: "iCloud is temporarily unavailable"]))
            @unknown default:
                completion(false, NSError(domain: "CloudKit", code: 5, userInfo: [NSLocalizedDescriptionKey: "Unknown iCloud status"]))
            }
        }
    }
}

// MARK: - Record Type Names (Constants)

/// String constants for CloudKit record types
/// These MUST match the record types you create in CloudKit Dashboard
struct RecordType {
    static let userProfile = "UserProfile"
    static let challenge = "Challenge"
    static let challengeEnrollment = "ChallengeEnrollment"
    static let friendRequest = "FriendRequest"
    static let dailyProgress = "DailyProgress"
    static let leaderboardEntry = "LeaderboardEntry"
}

// MARK: - Field Names (Constants)

/// String constants for record fields to avoid typos
struct FieldKey {
    
    // User fields
    struct UserProfile {
        static let username = "username"
        static let deviceID = "deviceID"
    }
    
    // Challenge fields
    struct Challenge {
        static let challengeID = "challengeID"
        static let name = "name"
        static let description = "description"
        static let targetSteps = "targetSteps"
        static let daysRequired = "daysRequired"
        static let duration = "duration"
        static let restDays = "restDays"
    }
    
    // ChallengeEnrollment fields
    struct ChallengeEnrollment {
        static let userReference = "userReference"
        static let challengeReference = "challengeReference"
        static let enrollmentType = "enrollmentType"
        static let startDate = "startDate"
        static let endDate = "endDate"
        static let groupID = "groupID"
        static let isActive = "isActive"
    }
    
    // FriendRequest fields
    struct FriendRequest {
        static let senderUserID = "senderUserID"
        static let receiverUserID = "receiverUserID"
        static let status = "status"
        static let createdAt = "createdAt"
        static let groupID = "groupID"
    }
    
    // DailyProgress fields
    struct DailyProgress {
        static let userReference = "userReference"
        static let enrollmentReference = "enrollmentReference"
        static let date = "date"
        static let stepCount = "stepCount"
        static let goalMet = "goalMet"
    }
    
    // LeaderboardEntry fields
    struct LeaderboardEntry {
        static let groupID = "groupID"
        static let userID = "userID"
        static let username = "username"
        static let enrollmentReference = "enrollmentReference"
        static let totalSteps = "totalSteps"
        static let daysCompleted = "daysCompleted"
        static let lastUpdated = "lastUpdated"
    }
}

// MARK: - Record Creation Helpers

extension CloudKitManager {
    
    // MARK: - User Record
    
    /// Creates a new User record in private database
    /// - Parameters:
    ///   - username: Display name for the user
    ///   - deviceID: Unique device identifier
    /// - Returns: CKRecord ready to be saved
    func createUserRecord(username: String, deviceID: String) -> CKRecord {
        let record = CKRecord(recordType: RecordType.userProfile)
        record[FieldKey.UserProfile.username] = username as CKRecordValue
        record[FieldKey.UserProfile.deviceID] = deviceID as CKRecordValue
        return record
    }
    
    // MARK: - Challenge Record
    
    /// Creates a new Challenge record in public database
    /// - Parameters:
    ///   - challengeID: Unique identifier for the challenge
    ///   - name: Challenge name (e.g., "7K Everyday")
    ///   - description: Challenge description
    ///   - targetSteps: Daily step goal
    ///   - daysRequired: Array of day names ["Monday", "Tuesday"...] or ["Saturday", "Sunday"]
    ///   - duration: Challenge length in days
    /// - Returns: CKRecord ready to be saved
    func createChallengeRecord(
        challengeID: String,
        name: String,
        description: String,
        targetSteps: Int,
        daysRequired: [String],
        duration: Int,
        restDays: Int
    ) -> CKRecord {
        let record = CKRecord(recordType: RecordType.challenge)
        record[FieldKey.Challenge.challengeID] = challengeID as CKRecordValue
        record[FieldKey.Challenge.name] = name as CKRecordValue
        record[FieldKey.Challenge.description] = description as CKRecordValue
        record[FieldKey.Challenge.targetSteps] = targetSteps as CKRecordValue
        record[FieldKey.Challenge.daysRequired] = daysRequired as CKRecordValue
        record[FieldKey.Challenge.duration] = duration as CKRecordValue
        record[FieldKey.Challenge.restDays] = restDays as CKRecordValue
        return record
    }
    
    // MARK: - ChallengeEnrollment Record
    
    /// Creates a new ChallengeEnrollment record in private database
    /// - Parameters:
    ///   - userRecord: Reference to the User record
    ///   - challengeRecord: Reference to the Challenge record
    ///   - enrollmentType: "solo" or "friends"
    ///   - startDate: When the challenge starts
    ///   - endDate: When the challenge ends
    ///   - groupID: Optional group ID for friend challenges
    /// - Returns: CKRecord ready to be saved
    func createChallengeEnrollmentRecord(
        userRecord: CKRecord,
        challengeRecord: CKRecord,
        enrollmentType: String,
        startDate: Date,
        endDate: Date,
        groupID: String?
    ) -> CKRecord {
        let record = CKRecord(recordType: RecordType.challengeEnrollment)
        
        // Create references to other records
        let userReference = CKRecord.Reference(record: userRecord, action: .deleteSelf)
        let challengeReference = CKRecord.Reference(record: challengeRecord, action: .none)
        
        record[FieldKey.ChallengeEnrollment.userReference] = userReference as CKRecordValue
        record[FieldKey.ChallengeEnrollment.challengeReference] = challengeReference as CKRecordValue
        record[FieldKey.ChallengeEnrollment.enrollmentType] = enrollmentType as CKRecordValue
        record[FieldKey.ChallengeEnrollment.startDate] = startDate as CKRecordValue
        record[FieldKey.ChallengeEnrollment.endDate] = endDate as CKRecordValue
        record[FieldKey.ChallengeEnrollment.isActive] = 1 as CKRecordValue // 1 = active
        
        if let groupID = groupID {
            record[FieldKey.ChallengeEnrollment.groupID] = groupID as CKRecordValue
        }
        
        return record
    }
    
    // MARK: - FriendRequest Record
    
    /// Creates a new FriendRequest record in public database
    /// - Parameters:
    ///   - senderUserID: ID of user sending request
    ///   - receiverUserID: ID of user receiving request
    /// - Returns: CKRecord ready to be saved
    func createFriendRequestRecord(
        senderUserID: String,
        receiverUserID: String
    ) -> CKRecord {
        let record = CKRecord(recordType: RecordType.friendRequest)
        record[FieldKey.FriendRequest.senderUserID] = senderUserID as CKRecordValue
        record[FieldKey.FriendRequest.receiverUserID] = receiverUserID as CKRecordValue
        record[FieldKey.FriendRequest.status] = "pending" as CKRecordValue
        record[FieldKey.FriendRequest.createdAt] = Date() as CKRecordValue
        return record
    }
    
    // MARK: - DailyProgress Record
    
    /// Creates a new DailyProgress record in private database
    /// - Parameters:
    ///   - userRecord: Reference to the User record
    ///   - enrollmentRecord: Reference to the ChallengeEnrollment record
    ///   - date: The date for this progress
    ///   - stepCount: Steps achieved on this date
    ///   - goalMet: Whether daily goal was met (1 = yes, 0 = no)
    /// - Returns: CKRecord ready to be saved
    func createDailyProgressRecord(
        userRecord: CKRecord,
        enrollmentRecord: CKRecord,
        date: Date,
        stepCount: Int,
        goalMet: Bool
    ) -> CKRecord {
        let record = CKRecord(recordType: RecordType.dailyProgress)
        
        let userReference = CKRecord.Reference(record: userRecord, action: .deleteSelf)
        let enrollmentReference = CKRecord.Reference(record: enrollmentRecord, action: .deleteSelf)
        
        record[FieldKey.DailyProgress.userReference] = userReference as CKRecordValue
        record[FieldKey.DailyProgress.enrollmentReference] = enrollmentReference as CKRecordValue
        record[FieldKey.DailyProgress.date] = date as CKRecordValue
        record[FieldKey.DailyProgress.stepCount] = stepCount as CKRecordValue
        record[FieldKey.DailyProgress.goalMet] = (goalMet ? 1 : 0) as CKRecordValue
        
        return record
    }
    
    // MARK: - LeaderboardEntry Record
    
    /// Creates a new LeaderboardEntry record in public database
    /// - Parameters:
    ///   - groupID: Group identifier for friend challenges
    ///   - userID: User identifier
    ///   - username: Display name
    ///   - enrollmentRecord: Reference to ChallengeEnrollment
    ///   - totalSteps: Running total of steps
    ///   - daysCompleted: Number of days goal was met
    /// - Returns: CKRecord ready to be saved
    func createLeaderboardEntryRecord(
        groupID: String,
        userID: String,
        username: String,
        enrollmentRecord: CKRecord,
        totalSteps: Int,
        daysCompleted: Int
    ) -> CKRecord {
        let record = CKRecord(recordType: RecordType.leaderboardEntry)
        
        let enrollmentReference = CKRecord.Reference(record: enrollmentRecord, action: .deleteSelf)
        
        record[FieldKey.LeaderboardEntry.groupID] = groupID as CKRecordValue
        record[FieldKey.LeaderboardEntry.userID] = userID as CKRecordValue
        record[FieldKey.LeaderboardEntry.username] = username as CKRecordValue
        record[FieldKey.LeaderboardEntry.enrollmentReference] = enrollmentReference as CKRecordValue
        record[FieldKey.LeaderboardEntry.totalSteps] = totalSteps as CKRecordValue
        record[FieldKey.LeaderboardEntry.daysCompleted] = daysCompleted as CKRecordValue
        record[FieldKey.LeaderboardEntry.lastUpdated] = Date() as CKRecordValue
        
        return record
    }
}

// MARK: - Save and Fetch Helpers

extension CloudKitManager {
    
    // MARK: - Save Record
    
    /// Saves a record to the appropriate database
    /// - Parameters:
    ///   - record: The CKRecord to save
    ///   - database: The database to save to (.private or .public)
    ///   - completion: Callback with saved record or error
    func saveRecord(
        _ record: CKRecord,
        to database: DatabaseType,
        completion: @escaping (Result<CKRecord, Error>) -> Void
    ) {
        let db = database == .private ? privateDatabase : publicDatabase
        
        db.save(record) { savedRecord, error in
            if let error = error {
                print("❌ Error saving \(record.recordType): \(error.localizedDescription)")
                completion(.failure(error))
            } else if let savedRecord = savedRecord {
                print("✅ Saved \(record.recordType) successfully")
                completion(.success(savedRecord))
            }
        }
    }
    
    // MARK: - Fetch Record by ID
    
    /// Fetches a record by its ID
    /// - Parameters:
    ///   - recordID: The CKRecord.ID to fetch
    ///   - database: The database to fetch from
    ///   - completion: Callback with fetched record or error
    func fetchRecord(
        with recordID: CKRecord.ID,
        from database: DatabaseType,
        completion: @escaping (Result<CKRecord, Error>) -> Void
    ) {
        let db = database == .private ? privateDatabase : publicDatabase
        
        db.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                print("❌ Error fetching record: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let record = record {
                print("✅ Fetched record successfully")
                completion(.success(record))
            }
        }
    }
    
    // MARK: - Delete Record
    
    /// Deletes a record from the database
    /// - Parameters:
    ///   - recordID: The CKRecord.ID to delete
    ///   - database: The database to delete from
    ///   - completion: Callback with deleted record ID or error
    func deleteRecord(
        with recordID: CKRecord.ID,
        from database: DatabaseType,
        completion: @escaping (Result<CKRecord.ID, Error>) -> Void
    ) {
        let db = database == .private ? privateDatabase : publicDatabase
        
        db.delete(withRecordID: recordID) { deletedID, error in
            if let error = error {
                print("❌ Error deleting record: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let deletedID = deletedID {
                print("✅ Deleted record successfully")
                completion(.success(deletedID))
            }
        }
    }
}

// MARK: - Helper Enums

/// Database type enum for clarity
enum DatabaseType {
    case `private`
    case `public`
}

// MARK: - Example Usage and Testing

#if DEBUG
extension CloudKitManager {
    
    /// Example: Create and save a challenge (run this once to populate public database)
    func createSampleChallenges() {
        checkAccountStatus { [weak self] available, error in
            guard available, let self = self else {
                print("❌ CloudKit not available")
                return
            }
            
            // Challenge 1: 7K Everyday
            let challenge1 = self.createChallengeRecord(
                challengeID: "7k-everyday",
                name: "7K Everyday",
                description: "Walk 7,000 steps every day for a week",
                targetSteps: 7000,
                daysRequired: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"],
                duration: 7,
                restDays: 0
            )
            
            // Challenge 2: Weekend Warrior
            let challenge2 = self.createChallengeRecord(
                challengeID: "weekend-warrior",
                name: "Weekend Warrior",
                description: "Hit 12,000 steps on Saturday and Sunday",
                targetSteps: 12000,
                daysRequired: ["Saturday", "Sunday"],
                duration: 2,
                restDays: 0
            )
            
            // Challenge 3: 10K Monday
            let challenge3 = self.createChallengeRecord(
                challengeID: "10k-monday",
                name: "10K Monday",
                description: "Start your week strong with 10,000 steps",
                targetSteps: 10000,
                daysRequired: ["Monday"],
                duration: 1,
                restDays: 0
            )
            
            // Save challenges to public database
            self.saveRecord(challenge1, to: .public) { result in
                if case .success = result {
                    print("✅ Created '7K Everyday' challenge")
                }
            }
            
            self.saveRecord(challenge2, to: .public) { result in
                if case .success = result {
                    print("✅ Created 'Weekend Warrior' challenge")
                }
            }
            
            self.saveRecord(challenge3, to: .public) { result in
                if case .success = result {
                    print("✅ Created '10K Monday' challenge")
                }
            }
        }
    }
}
#endif
extension CloudKitManager {
    
    // Get current device ID
    private func getCurrentDeviceID() -> String {
        if let savedDeviceID = UserDefaults.standard.string(forKey: FieldKey.UserProfile.deviceID) {
            return savedDeviceID
        }
        let newDeviceID = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        UserDefaults.standard.set(newDeviceID, forKey: FieldKey.UserProfile.deviceID)
        return newDeviceID
    }
    
    // Check if user has an active challenge (simplified - no User record needed)
    func hasActiveChallenge(completion: @escaping (Result<Bool, Error>) -> Void) {
        let deviceID = getCurrentDeviceID()
        let predicate = NSPredicate(format: "deviceID == %@ AND \(FieldKey.ChallengeEnrollment.isActive) == YES", deviceID)
        let query = CKQuery(recordType: "ChallengeEnrollment", predicate: predicate)
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
            } else {
                let hasActive = !(records?.isEmpty ?? true)
                completion(.success(hasActive))
            }
        }
    }
    
}
extension CloudKitManager {
    
    /// Reference to HealthManager (set this from MainViewModel)
    private static var healthManager: HealthManager?
    
    static func setHealthManager(_ manager: HealthManager) {
        healthManager = manager
    }
    
    /// Gets step count for a specific date range from HealthKit
    private func getStepCount(
        for startDate: Date,
        to endDate: Date,
        completion: @escaping (Int) -> Void
    ) {
        guard let healthManager = CloudKitManager.healthManager else {
            print("⚠️ HealthManager not set in CloudKitManager")
            completion(0)
            return
        }
        
        healthManager.getSteps(from: startDate, to: endDate, completion: completion)
    }
    
    /// Fetches the user's current active enrollment and its associated challenge
    func fetchActiveEnrollment(completion: @escaping (Result<(CKRecord, CKRecord), Error>) -> Void) {
        let deviceID = getCurrentDeviceID()
        
        // Query for active enrollment for this device
        let predicate = NSPredicate(format: "deviceID == %@ AND isActive == YES", deviceID)
        let query = CKQuery(recordType: "ChallengeEnrollment", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        publicDatabase.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching active enrollment: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let enrollment = records?.first else {
                let noEnrollmentError = NSError(
                    domain: "CloudKit",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "No active enrollment found"]
                )
                completion(.failure(noEnrollmentError))
                return
            }
            
            // Check if we should end this challenge due to missed goal
            self.checkAndEndChallengeIfNeeded(enrollment: enrollment) { shouldContinue in
                if !shouldContinue {
                    // Challenge was ended, return failure
                    let endedError = NSError(
                        domain: "CloudKit",
                        code: -2,
                        userInfo: [NSLocalizedDescriptionKey: "Challenge ended due to missed goal"]
                    )
                    completion(.failure(endedError))
                    return
                }
                
                // Fetch the associated challenge
                if let challengeReference = enrollment["challengeReference"] as? CKRecord.Reference {
                    self.publicDatabase.fetch(withRecordID: challengeReference.recordID) { challenge, error in
                        if let error = error {
                            print("❌ Error fetching challenge: \(error.localizedDescription)")
                            completion(.failure(error))
                        } else if let challenge = challenge {
                            print("✅ Fetched active challenge and enrollment")
                            completion(.success((challenge, enrollment)))
                        }
                    }
                } else {
                    let noChallengeError = NSError(
                        domain: "CloudKit",
                        code: -3,
                        userInfo: [NSLocalizedDescriptionKey: "No challenge reference found"]
                    )
                    completion(.failure(noChallengeError))
                }
            }
        }
    }
    
    /// Checks if the challenge should be ended due to a missed daily goal
    private func checkAndEndChallengeIfNeeded(
        enrollment: CKRecord,
        completion: @escaping (Bool) -> Void
    ) {
        guard let startDate = enrollment["startDate"] as? Date,
              let challengeRef = enrollment["challengeReference"] as? CKRecord.Reference,
              let lastCompletedDate = enrollment["lastCompletedDate"] as? Date? else {
            // First day or can't check - continue
            completion(true)
            return
        }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let enrollmentStartDay = calendar.startOfDay(for: startDate)
        
        // If enrolled today, don't check yet
        if calendar.isDate(enrollmentStartDay, inSameDayAs: today) {
            completion(true)
            return
        }
        
        // Check if there's a gap between last completed date and today
        if let lastCompleted = lastCompletedDate {
            let daysSinceLastCompleted = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastCompleted), to: today).day ?? 0
            
            // If more than 1 day gap (meaning they missed yesterday), end challenge
            if daysSinceLastCompleted > 1 {
                print("❌ Gap detected: \(daysSinceLastCompleted) days since last completion. Ending challenge.")
                self.endChallenge(enrollment: enrollment) { _ in
                    completion(false)
                }
                return
            }
        }
        
        // Fetch the challenge to get target steps
        publicDatabase.fetch(withRecordID: challengeRef.recordID) { [weak self] challenge, error in
            guard let self = self,
                  let challenge = challenge,
                  let targetSteps = challenge["targetSteps"] as? Int else {
                completion(true)
                return
            }
            
            // Check yesterday's steps
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            let yesterdayStart = calendar.startOfDay(for: yesterday)
            let yesterdayEnd = calendar.date(byAdding: .day, value: 1, to: yesterdayStart)!
            
            // Get yesterday's step count from HealthKit
            self.getStepCount(for: yesterdayStart, to: yesterdayEnd) { steps in
                if steps < targetSteps {
                    // Missed goal yesterday - end the challenge
                    print("❌ Goal not met yesterday (\(steps)/\(targetSteps) steps). Ending challenge.")
                    self.endChallenge(enrollment: enrollment) { _ in
                        completion(false)
                    }
                } else {
                    // Goal was met, but update last completed date if needed
                    print("✅ Yesterday's goal met (\(steps)/\(targetSteps) steps)")
                    
                    // Update last completed date to yesterday if it wasn't updated
                    if lastCompletedDate == nil || !calendar.isDate(lastCompletedDate!, inSameDayAs: yesterday) {
                        enrollment["lastCompletedDate"] = yesterday as CKRecordValue
                        let currentStreak = (enrollment["currentStreak"] as? Int) ?? 0
                        enrollment["currentStreak"] = (currentStreak + 1) as CKRecordValue
                        
                        self.publicDatabase.save(enrollment) { _, _ in
                            completion(true)
                        }
                    } else {
                        completion(true)
                    }
                }
            }
        }
    }
    

    // In CloudKitManager, after ending a challenge:
    func endChallenge(
        enrollment: CKRecord,
        reason: String = "replaced",
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        enrollment["isActive"] = false as CKRecordValue
        enrollment["endedAt"] = Date() as CKRecordValue
        enrollment["endReason"] = reason as CKRecordValue
        
        publicDatabase.save(enrollment) { savedRecord, error in
            if let error = error {
                print("❌ Error ending challenge: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("✅ Challenge ended successfully (reason: \(reason))")
                
                // Post notification to refresh StepView
                NotificationCenter.default.post(name: NSNotification.Name("ChallengeEnded"), object: nil)
                
                completion(.success(()))
            }
        }
    }
        
    //KEEP
        /// Updated enrollInChallenge to not check for active challenges (handled in UI)
        func enrollInChallenge(
            challenge: CKRecord,
            enrollmentType: String,
            groupID: String? = nil,
            completion: @escaping (Result<CKRecord, Error>) -> Void
        ) {
            let deviceID = getCurrentDeviceID()
            let username = UserDefaults.standard.string(forKey: FieldKey.UserProfile.username) ?? "Anonymous"
            
            let enrollmentRecord = CKRecord(recordType: "ChallengeEnrollment")
            
            enrollmentRecord["deviceID"] = deviceID as CKRecordValue
            enrollmentRecord["username"] = username as CKRecordValue
            enrollmentRecord["challengeReference"] = CKRecord.Reference(
                record: challenge,
                action: .deleteSelf
            ) as CKRecordValue
            enrollmentRecord["enrollmentType"] = enrollmentType as CKRecordValue
            enrollmentRecord["startDate"] = Date() as CKRecordValue
            enrollmentRecord["currentStreak"] = 0 as CKRecordValue
            enrollmentRecord["totalDaysCompleted"] = 0 as CKRecordValue
            
            if let duration = challenge["duration"] as? Int {
                let endDate = Calendar.current.date(byAdding: .day, value: duration, to: Date())
                enrollmentRecord["expectedEndDate"] = endDate as! any CKRecordValue as CKRecordValue
            }
            
            if let groupID = groupID {
                enrollmentRecord["groupID"] = groupID as CKRecordValue
            }
            
            enrollmentRecord["isActive"] = true as CKRecordValue
            
            print("📝 Creating enrollment for user: \(username) with deviceID: \(deviceID)")
            
            saveRecord(enrollmentRecord, to: .public) { result in
                completion(result)
            }
        }
    
   
        /// Update today's progress when goal is reached
        func updateTodayProgress(stepCount: Int, completion: @escaping (Result<Void, Error>) -> Void) {
            fetchActiveEnrollment { [weak self] result in
                guard let self = self else { return }
                
                switch result {
                case .success(let (challenge, enrollment)):
                    guard let targetSteps = challenge["targetSteps"] as? Int,
                          let duration = challenge["duration"] as? Int else {
                        completion(.failure(NSError(
                            domain: "CloudKit",
                            code: -1,
                            userInfo: [NSLocalizedDescriptionKey: "Invalid challenge data"]
                        )))
                        return
                    }
                    
                    // Only update if goal is met today
                    if stepCount >= targetSteps {
                        let today = Calendar.current.startOfDay(for: Date())
                        let lastCompleted = enrollment["lastCompletedDate"] as? Date
                        
                        // Only update if we haven't already marked today as complete
                        if lastCompleted == nil || !Calendar.current.isDate(lastCompleted!, inSameDayAs: today) {
                            let currentStreak = (enrollment["currentStreak"] as? Int) ?? 0
                            let totalDays = (enrollment["totalDaysCompleted"] as? Int) ?? 0
                            let newTotalDays = totalDays + 1
                            
                            enrollment["currentStreak"] = (currentStreak + 1) as CKRecordValue
                            enrollment["totalDaysCompleted"] = newTotalDays as CKRecordValue
                            enrollment["lastCompletedDate"] = today as CKRecordValue
                            
                            // Check if challenge is now completed
                            if newTotalDays >= duration {
                                enrollment["isActive"] = false as CKRecordValue
                                enrollment["endedAt"] = Date() as CKRecordValue
                                enrollment["endReason"] = "completed" as CKRecordValue
                                print("🎉 Challenge completed! \(newTotalDays)/\(duration) days")
                            }
                            
                            self.publicDatabase.save(enrollment) { _, error in
                                if let error = error {
                                    completion(.failure(error))
                                } else {
                                    print("✅ Updated challenge progress: \(newTotalDays)/\(duration) days, streak \(currentStreak + 1)")
                                    completion(.success(()))
                                }
                            }
                        } else {
                            // Already updated today
                            completion(.success(()))
                        }
                    } else {
                        // Goal not met yet
                        completion(.success(()))
                    }
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    
}
extension CloudKitManager {
    /// Fetches all enrollments (active and completed) for the current user
    func fetchAllEnrollments(completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let deviceID = getCurrentDeviceID()
        
        let predicate = NSPredicate(format: "deviceID == %@", deviceID)
        let query = CKQuery(recordType: "ChallengeEnrollment", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        publicDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                print("❌ Error fetching enrollments: \(error.localizedDescription)")
                completion(.failure(error))
            } else if let records = records {
                print("✅ Fetched \(records.count) enrollments")
                completion(.success(records))
            }
        }
    }
}
extension CloudKitManager {
    /// Fetches all enrollments with their full challenge details
    func fetchAllEnrollmentsWithChallengeDetails(completion: @escaping (Result<[EnrollmentWithChallenge], Error>) -> Void) {
        let deviceID = getCurrentDeviceID()
        
        let predicate = NSPredicate(format: "deviceID == %@", deviceID)
        let query = CKQuery(recordType: "ChallengeEnrollment", predicate: predicate)
        query.sortDescriptors = [NSSortDescriptor(key: "startDate", ascending: false)]
        
        publicDatabase.perform(query, inZoneWith: nil) { [weak self] records, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error fetching enrollments: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let enrollments = records, !enrollments.isEmpty else {
                print("ℹ️ No enrollments found")
                completion(.success([]))
                return
            }
            
            print("📥 Fetched \(enrollments.count) enrollment records")
            
            // Fetch challenge details for each enrollment
            let group = DispatchGroup()
            var enrichedEnrollments: [EnrollmentWithChallenge] = []
            
            for enrollment in enrollments {
                group.enter()
                
                guard let challengeRef = enrollment["challengeReference"] as? CKRecord.Reference else {
                    print("⚠️ No challenge reference for enrollment")
                    group.leave()
                    continue
                }
                
                self.publicDatabase.fetch(withRecordID: challengeRef.recordID) { challenge, error in
                    defer { group.leave() }
                    
                    if let error = error {
                        print("❌ Error fetching challenge: \(error.localizedDescription)")
                        return
                    }
                    
                    guard let challenge = challenge else {
                        print("⚠️ Challenge not found")
                        return
                    }
                    
                    let enriched = EnrollmentWithChallenge(from: enrollment, challenge: challenge)
                    enrichedEnrollments.append(enriched)
                    
                    print("✅ Enriched enrollment: \(enriched.challengeName), active: \(enriched.isActive)")
                }
            }
            
            group.notify(queue: .main) {
                print("✅ Total enriched enrollments: \(enrichedEnrollments.count)")
                completion(.success(enrichedEnrollments))
            }
        }
    }
}

// MARK: - Challenge Icon Helper
extension CKRecord {
    var challengeIconName: String {
        guard let challengeID = self["challengeID"] as? String else {
            return "challenge-10k-daily"
        }
        
        let id = challengeID.lowercased()
        if id.contains("10k") || id.contains("daily") {
            return "challenge-10k-daily"
        } else if id.contains("weekend") {
            return "challenge-weekend-warrior"
        } else if id.contains("marathon") {
            return "challenge-marathon"
        } else if id.contains("peak") {
            return "challenge-peak-performance"
        } else if id.contains("social") {
            return "challenge-social"
        } else if id.contains("streak") {
            return "challenge-streak"
        } else {
            return "challenge-10k-daily"
        }
    }
}
