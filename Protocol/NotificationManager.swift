import Foundation
import UserNotifications
import SwiftData

final class NotificationManager: NSObject, @unchecked Sendable {
    static let shared = NotificationManager()

    // MARK: - Permission

    func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    // MARK: - Per-protocol, per-slot enabled

    func slotEnabled(for protocolID: UUID, slot: ProtocolSlot) -> Bool {
        UserDefaults.standard.object(forKey: slotEnabledKey(protocolID, slot: slot)) as? Bool ?? true
    }

    func setSlotEnabled(_ enabled: Bool, for protocolID: UUID, slot: ProtocolSlot) {
        UserDefaults.standard.set(enabled, forKey: slotEnabledKey(protocolID, slot: slot))
    }

    // MARK: - Per-protocol, per-slot time

    func time(for protocolID: UUID, slot: ProtocolSlot) -> DateComponents {
        let defaults = UserDefaults.standard
        let hour = defaults.object(forKey: hourKey(protocolID, slot: slot)) as? Int ?? defaultHour(for: slot)
        let minute = defaults.object(forKey: minuteKey(protocolID, slot: slot)) as? Int ?? 0
        return DateComponents(hour: hour, minute: minute)
    }

    func setTime(_ components: DateComponents, for protocolID: UUID, slot: ProtocolSlot) {
        UserDefaults.standard.set(components.hour ?? 0, forKey: hourKey(protocolID, slot: slot))
        UserDefaults.standard.set(components.minute ?? 0, forKey: minuteKey(protocolID, slot: slot))
    }

    // MARK: - Date helpers

    func date(from components: DateComponents) -> Date {
        Calendar.current.date(from: DateComponents(hour: components.hour ?? 8, minute: components.minute ?? 0)) ?? Date()
    }

    func components(from date: Date) -> DateComponents {
        Calendar.current.dateComponents([.hour, .minute], from: date)
    }

    // MARK: - Scheduling

    func rescheduleAll(activeProtocols: [ProtocolPlan], logs: [ProtocolLog]) {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        for plan in activeProtocols {
            guard plan.isActive else { continue }
            guard let version = plan.currentVersion else { continue }

            let allItems = version.items ?? []

            for slot in ProtocolSlot.allCases {
                guard allItems.contains(where: { $0.slot == slot }) else { continue }
                guard slotEnabled(for: plan.id, slot: slot) else { continue }

                let isLogged = logs.contains { log in
                    log.protocolID == plan.id &&
                    log.slot == slot &&
                    calendar.isDate(log.date, inSameDayAs: today) &&
                    (log.status == .completed || log.status == .skipped || log.status == .missed)
                }
                if isLogged { continue }

                let timeComps = time(for: plan.id, slot: slot)
                var trigger = DateComponents()
                trigger.hour = timeComps.hour ?? defaultHour(for: slot)
                trigger.minute = timeComps.minute ?? 0

                if let fireDate = calendar.nextDate(after: now.addingTimeInterval(-1), matching: trigger, matchingPolicy: .nextTime) {
                    guard fireDate > now else { continue }
                }

                let content = UNMutableNotificationContent()
                content.title = "\(plan.name) — \(slot.rawValue)"
                content.body = "Time to take your \(slot.rawValue.lowercased()) supplements"
                content.sound = .default

                let request = UNNotificationRequest(
                    identifier: notificationID(for: plan.id, slot: slot),
                    content: content,
                    trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: false)
                )

                center.add(request) { error in
                    if let error { print("Notif error \(plan.name)/\(slot.rawValue): \(error)") }
                }
            }
        }
    }

    func cancelNotifications(for protocolID: UUID) {
        let ids = ProtocolSlot.allCases.map { notificationID(for: protocolID, slot: $0) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private

    private func notificationID(for protocolID: UUID, slot: ProtocolSlot) -> String {
        "protocol_\(protocolID.uuidString)_\(slot.rawValue.lowercased())"
    }

    private func slotEnabledKey(_ protocolID: UUID, slot: ProtocolSlot) -> String {
        "notif_slot_\(protocolID.uuidString)_\(slot.rawValue.lowercased())_enabled"
    }

    private func hourKey(_ protocolID: UUID, slot: ProtocolSlot) -> String {
        "notif_\(protocolID.uuidString)_\(slot.rawValue.lowercased())_hour"
    }

    private func minuteKey(_ protocolID: UUID, slot: ProtocolSlot) -> String {
        "notif_\(protocolID.uuidString)_\(slot.rawValue.lowercased())_minute"
    }

    private func defaultHour(for slot: ProtocolSlot) -> Int {
        switch slot {
        case .morning: return 8
        case .daytime: return 14
        case .night: return 18
        }
    }
}
