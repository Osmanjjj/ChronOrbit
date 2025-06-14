import SwiftUI

struct ScheduleInputView: View {
    @State private var title = ""
    @State private var start = Calendar.current.date(bySettingHour: 8, minute: 0, second: 0, of: Date())!
    @State private var end   = Calendar.current.date(bySettingHour: 10, minute: 0, second: 0, of: Date())!
    @State private var message = ""

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section("タイトル") {
                    TextField("例: 勉強", text: $title)
                }

                Section("時間帯") {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("開始").font(.caption).foregroundColor(.secondary)
                            DatePicker("", selection: $start, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                        Spacer()
                        Image(systemName: "arrowshape.right.fill")
                            .foregroundColor(.accentColor)
                        Spacer()
                        VStack(alignment: .leading) {
                            Text("終了").font(.caption).foregroundColor(.secondary)
                            DatePicker("", selection: $end, displayedComponents: .hourAndMinute)
                                .labelsHidden()
                        }
                    }
                }

                Section {
                    Button("登録する") { register() }
                        .frame(maxWidth: .infinity)
                }

                if !message.isEmpty {
                    Section { Text(message).foregroundColor(.secondary) }
                }
            }
            .navigationTitle("スケジュール登録")
        }
    }

    private func register() {
        Task {
            do {
                let s = formatter.string(from: start)
                let e = formatter.string(from: end)
                try await SupabaseService.shared.insertSchedule(
                    title: title.isEmpty ? "タイトル未入力" : title,
                    start: s,
                    end: e
                )
                message = "✅ 登録完了 \(s) – \(e)"
                title = ""
            } catch {
                message = "❌ \(error.localizedDescription)"
            }
        }
    }
}
