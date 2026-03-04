import Foundation
import SwiftData

@Model
final class DailyCheckIn {
    var id: UUID = UUID()
    var date: Date = Date()
    var mood: Int = 3
    var energy: Int = 3
    var sleep: Int = 3
    var note: String = ""
    var createdAt: Date = Date()

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        mood: Int,
        energy: Int,
        sleep: Int,
        note: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.date = date
        self.mood = mood
        self.energy = energy
        self.sleep = sleep
        self.note = note
        self.createdAt = createdAt
    }
}
