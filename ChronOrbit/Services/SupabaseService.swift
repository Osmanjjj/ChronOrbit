import Supabase

final class SupabaseService {
    static let shared = SupabaseService()
    let client: SupabaseClient

    private init() {
        client = SupabaseClient(
            supabaseURL: Secrets.supabaseURL,
            supabaseKey: Secrets.supabaseAnonKey
        )
    }

    // INSERT 用 DTO
    struct ScheduleInsert: Codable {
        let title: String
        let start_time: String
        let end_time: String
    }

    /// スケジュールを 1 件登録
    func insertSchedule(title: String,
                        start: String,
                        end: String) async throws {

        let data = ScheduleInsert(title: title,
                                  start_time: start,
                                  end_time: end)

        try await client
            .from("schedules")
            .insert(data)
            .execute()
    }
}
