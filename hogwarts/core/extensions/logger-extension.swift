import os

extension Logger {
    private static let subsystem = "org.databayt.Hogwarts"

    static let app = Logger(subsystem: subsystem, category: "App")
    static let attendance = Logger(subsystem: subsystem, category: "Attendance")
    static let grades = Logger(subsystem: subsystem, category: "Grades")
    static let students = Logger(subsystem: subsystem, category: "Students")
    static let dashboard = Logger(subsystem: subsystem, category: "Dashboard")
    static let messages = Logger(subsystem: subsystem, category: "Messages")
    static let notifications = Logger(subsystem: subsystem, category: "Notifications")
    static let timetable = Logger(subsystem: subsystem, category: "Timetable")
    static let profile = Logger(subsystem: subsystem, category: "Profile")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let sync = Logger(subsystem: subsystem, category: "Sync")
    static let auth = Logger(subsystem: subsystem, category: "Auth")
}
