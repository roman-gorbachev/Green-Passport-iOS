import FirebaseFirestore

enum FirestoreCollections {
    private static let root = "apps/greenpassport"

    static func users(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/users")
    }

    static func tasks(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/tasks")
    }

    static func taskProgress(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/taskProgress")
    }

    static func shopItems(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/shopItems")
    }

    static func purchases(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/purchases")
    }

    static func mapPoints(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/mapPoints")
    }

    static func events(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/events")
    }

    static func eventAttendance(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/eventAttendance")
    }

    static func eventRegistrations(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/eventRegistrations")
    }

    static func posts(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/posts")
    }

    static func groups(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/groups")
    }

    static func chatMessages(_ firestore: Firestore, chatId: String) -> CollectionReference {
        return firestore.collection("\(root)/chats/\(chatId)/messages")
    }

    static func ecoTips(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/ecoTips")
    }

    static func ecoTipReads(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/ecoTipReads")
    }

    static func feedback(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/feedback")
    }

    static func surveys(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/surveys")
    }

    static func surveyAnswers(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/surveyAnswers")
    }

    static func favoriteTasks(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/favoriteTasks")
    }

    static func bookmarkedTips(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/bookmarkedTips")
    }

    static func taskSubmissions(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/taskSubmissions")
    }

    static func chatSettings(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/chatSettings")
    }

    static func reports(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/reports")
    }

    static func games(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/games")
    }

    static func admins(_ firestore: Firestore) -> CollectionReference {
        return firestore.collection("\(root)/admins")
    }
}
