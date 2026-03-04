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
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!

        for plan in activeProtocols {
            guard plan.isActive else { continue }
            guard let version = plan.currentVersion else { continue }

            let allItems = version.items ?? []

            for slot in ProtocolSlot.allCases {
                guard allItems.contains(where: { $0.slot == slot }) else { continue }
                guard slotEnabled(for: plan.id, slot: slot) else { continue }

                let timeComps = time(for: plan.id, slot: slot)
                let hour = timeComps.hour ?? defaultHour(for: slot)
                let minute = timeComps.minute ?? 0

                // --- Schedule for TODAY (if not logged and time hasn't passed) ---
                let isTodayLogged = logs.contains { log in
                    log.protocolID == plan.id &&
                    log.slot == slot &&
                    calendar.isDate(log.date, inSameDayAs: today) &&
                    (log.status == .completed || log.status == .skipped || log.status == .missed)
                }

                if !isTodayLogged {
                    var todayTrigger = calendar.dateComponents([.year, .month, .day], from: today)
                    todayTrigger.hour = hour
                    todayTrigger.minute = minute

                    if let fireDate = calendar.date(from: todayTrigger), fireDate > now {
                        scheduleNotification(
                            center: center,
                            id: notificationID(for: plan.id, slot: slot, date: today),
                            title: "\(plan.name) — \(slot.rawValue)",
                            body: "Time to take your \(slot.rawValue.lowercased()) supplements",
                            trigger: todayTrigger
                        )
                    }
                }

                // --- Always schedule for TOMORROW ---
                let isTomorrowLogged = logs.contains { log in
                    log.protocolID == plan.id &&
                    log.slot == slot &&
                    calendar.isDate(log.date, inSameDayAs: tomorrow) &&
                    (log.status == .completed || log.status == .skipped || log.status == .missed)
                }

                if !isTomorrowLogged {
                    var tomorrowTrigger = calendar.dateComponents([.year, .month, .day], from: tomorrow)
                    tomorrowTrigger.hour = hour
                    tomorrowTrigger.minute = minute

                    scheduleNotification(
                        center: center,
                        id: notificationID(for: plan.id, slot: slot, date: tomorrow),
                        title: "\(plan.name) — \(slot.rawValue)",
                        body: "Time to take your \(slot.rawValue.lowercased()) supplements",
                        trigger: tomorrowTrigger
                    )
                }
            }
        }
    }

    private func scheduleNotification(center: UNUserNotificationCenter, id: String, title: String, body: String, trigger: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: id,
            content: content,
            trigger: UNCalendarNotificationTrigger(dateMatching: trigger, repeats: false)
        )

        center.add(request) { error in
            if let error { print("Notif error \(id): \(error)") }
        }
    }

    func cancelNotifications(for protocolID: UUID) {
        let center = UNUserNotificationCenter.current()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        var ids: [String] = []
        for slot in ProtocolSlot.allCases {
            ids.append(notificationID(for: protocolID, slot: slot, date: today))
            ids.append(notificationID(for: protocolID, slot: slot, date: tomorrow))
        }
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Private

    private func notificationID(for protocolID: UUID, slot: ProtocolSlot, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateStr = formatter.string(from: date)
        return "protocol_\(protocolID.uuidString)_\(slot.rawValue.lowercased())_\(dateStr)"
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
