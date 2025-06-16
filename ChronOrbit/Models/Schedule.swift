import Foundation

struct Schedule: Identifiable {
    let id = UUID()
    let title: String
    let start: Date
    let end: Date
}
