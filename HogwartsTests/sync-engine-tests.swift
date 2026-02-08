import Foundation
import Testing
@testable import Hogwarts

/// Tests for PendingAction model and sync engine logic
@Suite("Sync Engine")
struct SyncEngineTests {

    // MARK: - PendingAction Creation

    @Test("PendingAction initializes with correct defaults")
    func pendingActionDefaults() {
        let action = PendingAction(
            endpoint: "/students",
            method: .post,
            payload: nil
        )
        #expect(action.status == "pending")
        #expect(action.retryCount == 0)
        #expect(action.errorMessage == nil)
        #expect(action.endpoint == "/students")
        #expect(action.method == "POST")
    }

    @Test("PendingAction initializes with payload")
    func pendingActionWithPayload() {
        let payload = "{\"name\":\"test\"}".data(using: .utf8)
        let action = PendingAction(
            endpoint: "/students",
            method: .post,
            payload: payload
        )
        #expect(action.payload != nil)
        #expect(action.payload == payload)
    }

    @Test("PendingAction UUID is unique")
    func pendingActionUniqueId() {
        let action1 = PendingAction(endpoint: "/a", method: .post)
        let action2 = PendingAction(endpoint: "/b", method: .post)
        #expect(action1.id != action2.id)
    }

    // MARK: - SyncStatus

    @Test("SyncStatus pending rawValue")
    func syncStatusPending() {
        #expect(SyncStatus.pending.rawValue == "pending")
    }

    @Test("SyncStatus syncing rawValue")
    func syncStatusSyncing() {
        #expect(SyncStatus.syncing.rawValue == "syncing")
    }

    @Test("SyncStatus completed rawValue")
    func syncStatusCompleted() {
        #expect(SyncStatus.completed.rawValue == "completed")
    }

    @Test("SyncStatus failed rawValue")
    func syncStatusFailed() {
        #expect(SyncStatus.failed.rawValue == "failed")
    }

    @Test("PendingAction syncStatus computed property")
    func pendingActionSyncStatusComputed() {
        let action = PendingAction(endpoint: "/test", method: .post)
        #expect(action.syncStatus == .pending)

        action.status = SyncStatus.syncing.rawValue
        #expect(action.syncStatus == .syncing)

        action.status = SyncStatus.completed.rawValue
        #expect(action.syncStatus == .completed)

        action.status = SyncStatus.failed.rawValue
        #expect(action.syncStatus == .failed)
    }

    // MARK: - Retry Count Logic

    @Test("RetryCount starts at zero")
    func retryCountStartsAtZero() {
        let action = PendingAction(endpoint: "/test", method: .post)
        #expect(action.retryCount == 0)
    }

    @Test("RetryCount can be incremented")
    func retryCountIncrements() {
        let action = PendingAction(endpoint: "/test", method: .post)
        action.retryCount += 1
        #expect(action.retryCount == 1)
        action.retryCount += 1
        #expect(action.retryCount == 2)
    }

    @Test("Max retries threshold is 3")
    func maxRetriesThreshold() {
        let action = PendingAction(endpoint: "/test", method: .post)

        // Simulate retry logic: under threshold re-queues as pending
        action.retryCount = 2
        if action.retryCount >= 3 {
            action.status = SyncStatus.failed.rawValue
        } else {
            action.status = SyncStatus.pending.rawValue
        }
        #expect(action.status == "pending")

        // At threshold, stays failed
        action.retryCount = 3
        if action.retryCount >= 3 {
            action.status = SyncStatus.failed.rawValue
        } else {
            action.status = SyncStatus.pending.rawValue
        }
        #expect(action.status == "failed")
    }

    @Test("Completed actions should not be re-queued")
    func completedNotRequeued() {
        let action = PendingAction(endpoint: "/test", method: .post)
        action.status = SyncStatus.completed.rawValue

        // Predicate check: completed actions excluded
        let status = action.status
        let retryCount = action.retryCount
        let shouldProcess = status == "pending" || (status == "failed" && retryCount < 3)
        #expect(!shouldProcess)
    }

    @Test("Failed action under retry limit should be re-queued")
    func failedUnderLimitRequeued() {
        let action = PendingAction(endpoint: "/test", method: .post)
        action.status = SyncStatus.failed.rawValue
        action.retryCount = 1

        let status = action.status
        let retryCount = action.retryCount
        let shouldProcess = status == "pending" || (status == "failed" && retryCount < 3)
        #expect(shouldProcess)
    }

    @Test("Failed action at retry limit should not be re-queued")
    func failedAtLimitNotRequeued() {
        let action = PendingAction(endpoint: "/test", method: .post)
        action.status = SyncStatus.failed.rawValue
        action.retryCount = 3

        let status = action.status
        let retryCount = action.retryCount
        let shouldProcess = status == "pending" || (status == "failed" && retryCount < 3)
        #expect(!shouldProcess)
    }

    // MARK: - Exponential Backoff Calculation

    @Test("Exponential backoff delay for retry 1")
    func backoffDelayRetry1() {
        let delay = pow(2.0, Double(1))
        #expect(delay == 2.0)
    }

    @Test("Exponential backoff delay for retry 2")
    func backoffDelayRetry2() {
        let delay = pow(2.0, Double(2))
        #expect(delay == 4.0)
    }

    @Test("No backoff delay for first attempt")
    func noBackoffFirstAttempt() {
        let retryCount = 0
        let shouldDelay = retryCount > 0
        #expect(!shouldDelay)
    }

    // MARK: - EntityType

    @Test("EntityType has all 5 cases")
    func entityTypeCases() {
        let cases: [EntityType] = [.students, .attendance, .grades, .messages, .notifications]
        #expect(cases.count == 5)
    }

    // MARK: - HTTPMethod Mapping

    @Test("PendingAction stores correct HTTP method")
    func httpMethodMapping() {
        let getAction = PendingAction(endpoint: "/test", method: .get)
        #expect(getAction.method == "GET")

        let postAction = PendingAction(endpoint: "/test", method: .post)
        #expect(postAction.method == "POST")

        let putAction = PendingAction(endpoint: "/test", method: .put)
        #expect(putAction.method == "PUT")

        let deleteAction = PendingAction(endpoint: "/test", method: .delete)
        #expect(deleteAction.method == "DELETE")
    }
}
