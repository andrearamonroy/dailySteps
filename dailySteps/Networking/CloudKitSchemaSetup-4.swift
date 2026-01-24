//
//  CloudKitSchemaSetup.swift
//  Step Tracking App
//
//  CloudKit Schema Setup and Configuration
//

import CloudKit
import Foundation

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
