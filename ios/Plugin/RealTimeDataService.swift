import Foundation
import FirebaseAuth
import FirebaseDatabase
import UserNotifications

class RealTimeDataService {
    private var databaseReference: DatabaseReference!
    private var groupCallListener: DatabaseHandle?
    private let dbDispatchQueue = DispatchQueue(label: "com.-Lifesherpa-iOS.realtimedb", qos: .default)

    deinit {
        removeListener()
    }

    func handleRealtimeListener(orgId: String, userId: String, roomName: String, abortCall: @escaping () -> Void) {
        let loggedInUserId: String
        guard let user = Auth.auth().currentUser else {
            print("Error: User not logged in.")
            abortCall()
            return
        }

        loggedInUserId = user.uid
        let realtimePath = "Realtime/\(orgId)/Users/\(loggedInUserId)/groupCallsInProgress/\(roomName)"
        print("Realtime Path: \(realtimePath)")

        dbDispatchQueue.async { [weak self] in
            guard let self = self else { return }

            self.databaseReference = Database.database().reference().child(realtimePath)

            self.groupCallListener = self.databaseReference?.observe(.value) { [weak self] snapshot in
                guard let self = self else { return }
                guard snapshot.exists(), let details = snapshot.value as? [String: Any] else {
                    self.removeListener()
                    DispatchQueue.main.async {
                        self.hideVideoCallConfirmation()
                        abortCall()
                    }
                    return
                }

                guard let groupCallDetails = RoomDetails(dictionary: details) else {
                    print("Error: Failed to parse RoomDetails.")
                    self.removeListener()
                    DispatchQueue.main.async {
                        self.hideVideoCallConfirmation()
                        abortCall()
                    }
                    return
                }

                if groupCallDetails.isGroup {
                    self.handleGroupVideoCall(details: groupCallDetails, userId: loggedInUserId) {
                        DispatchQueue.main.async {
                            abortCall()
                        }
                    }
                } else {
                    self.handleP2PVideoCall(details: groupCallDetails, userId: loggedInUserId) {
                        DispatchQueue.main.async {
                            abortCall()
                        }
                    }
                }
            }
        }
    }

    private func handleGroupVideoCall(details: RoomDetails, userId: String, callback: @escaping () -> Void) {
        guard let members = details.members, !members.isEmpty else { return }

        for user in members where user.userId == userId {
            if let status = user.status, ["cancel", "declined", "removed", "unanswered", "accepted"].contains(status) {
                callback()
                hideVideoCallConfirmation()
                return
            }
        }
    }

    private func handleP2PVideoCall(details: RoomDetails, userId: String, callback: @escaping () -> Void) {
        guard let members = details.members, !members.isEmpty else {
            callback() // handle the case where there are no members
             DispatchQueue.main.async {
                   self.hideVideoCallConfirmation()
             }
            return
        }

        for user in members where user.userId == userId {
            if let status = user.status, ["cancel", "declined", "removed", "unanswered", "accepted"].contains(status) {
                callback()
                DispatchQueue.main.async {
                    self.hideVideoCallConfirmation()
                }
                return
            }
        }
    }

    public func hideVideoCallConfirmation() {
        print("Hiding video call confirmation.")
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.removeDeliveredNotifications(withIdentifiers: ["2"])
        removeListener()
    }
    
    private func removeListener() {
        if let listener = self.groupCallListener, let dbRef = self.databaseReference {
            dbDispatchQueue.async {
                dbRef.removeObserver(withHandle: listener)
                DispatchQueue.main.async {
                    self.groupCallListener = nil
                    self.databaseReference = nil
                    print("Removed Firebase listener successfully.")
                }
            }
        } else {
            print("No active Firebase listener to remove or databaseReference is nil.")
        }
    }
}

// Model for Room Details
class RoomDetails {
    var isGroup: Bool
    var members: [User]?

    init?(dictionary: [String: Any]) {
        guard let isGroup = dictionary["group"] as? Bool else { return nil }
        self.isGroup = isGroup

        if let membersArray = dictionary["members"] as? [[String: Any]] {
            self.members = membersArray.compactMap { User(dictionary: $0) }
        } else {
            self.members = []
        }
    }
}

// Model for User Data
class User {
    var userId: String
    var status: String?

    init?(dictionary: [String: Any]) {
        guard let userId = dictionary["userId"] as? String, !userId.isEmpty else { return nil }
        self.userId = userId
        self.status = dictionary["status"] as? String
    }
}
