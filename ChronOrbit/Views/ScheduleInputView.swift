import SwiftUI
import UIKit

struct ScheduleInputView: View {
    @State private var title = ""
    @State private var start = Date()
    @State private var end = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    @State private var showMessage = false
    @State private var animate = false
    @State private var selectedDate = Date()

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("\u{1F4C5} スケジュール登録")
                    .font(.largeTitle.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "pencil")
                        TextField("例: 勉強", text: $title)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                    .shadow(radius: 1)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("\u{1F4C6} 日付選択")
                            .font(.headline)
                        DatePicker("", selection: $selectedDate, displayedComponents: .date)
                            .datePickerStyle(GraphicalDatePickerStyle())
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                            .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text("\u{1F552} 時間帯")
                            .font(.headline)

                        HStack(spacing: 12) {
                            VStack {
                                Text("開始").font(.caption)
                                DatePicker("", selection: $start, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }

                            Image(systemName: "arrowshape.right.fill")
                                .foregroundColor(.accentColor)
                                .font(.title3)

                            VStack {
                                Text("終了").font(.caption)
                                DatePicker("", selection: $end, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color(.systemGray6)))
                        .shadow(radius: 1)
                    }
                }
                .padding(.horizontal)

                Button(action: {
                    Task {
                        do {
                            try await SupabaseService.shared.insertSchedule(
                                title: title,
                                start: formatter.string(from: combine(date: selectedDate, time: start)),
                                end: formatter.string(from: combine(date: selectedDate, time: end))
                            )
                            withAnimation(.spring()) {
                                showMessage = true
                                animate = true
                            }
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)
                        } catch {
                            print("❌ Supabase登録失敗: \(error)")
                        }
                    }
                }) {
                    Label("登録する", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(radius: 2)
                }
                .padding(.horizontal)
                .alert(isPresented: $showMessage) {
                    Alert(
                        title: Text("☑️ 登録完了"),
                        message: Text("\(formatter.string(from: combine(date: selectedDate, time: start)))〜\(formatter.string(from: combine(date: selectedDate, time: end)))"),
                        dismissButton: .default(Text("OK"))
                    )
                }

                Spacer()
            }
            .padding(.top)
            
        }
        .tabItem {
            Label("カレンダー", systemImage: "calendar")
        }
    }

    func combine(date: Date, time: Date) -> Date {
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.year, .month, .day], from: date)
        let timeComponents = calendar.dateComponents([.hour, .minute, .second], from: time)

        var combined = DateComponents()
        combined.year = dateComponents.year
        combined.month = dateComponents.month
        combined.day = dateComponents.day
        combined.hour = timeComponents.hour
        combined.minute = timeComponents.minute
        combined.second = timeComponents.second

        return calendar.date(from: combined) ?? date
    }
}
