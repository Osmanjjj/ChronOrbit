import SwiftUI
import UIKit
import EventKit

struct ScheduleInputView: View {
    @State private var title = ""
    @State private var start = Date()
    @State private var end = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
    @State private var showAlert = false
    @State private var selectedDate = Date()
    @State private var schedules: [Schedule] = []
    @State private var currentTime = Date()
    @State private var showPieChart = false
    @State private var selectedSchedule: Schedule?

    private let formatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return f
    }()

    var body: some View {
        VStack(spacing: 24) {
            ScrollView {
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
                            let schedule = Schedule(title: title, start: combine(date: selectedDate, time: start), end: combine(date: selectedDate, time: end))
                            try await SupabaseService.shared.insertSchedule(
                                title: schedule.title,
                                start: formatter.string(from: schedule.start),
                                end: formatter.string(from: schedule.end)
                            )
                            schedules.append(schedule)
                            showAlert = true
                            let generator = UINotificationFeedbackGenerator()
                            generator.notificationOccurred(.success)

                            addToAppleCalendar(title: schedule.title, startDate: schedule.start, endDate: schedule.end)
                            addToReminders(title: schedule.title, dueDate: schedule.start)
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
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("✅ 登録完了"), message: Text("\(formatter.string(from: combine(date: selectedDate, time: start)))〜\(formatter.string(from: combine(date: selectedDate, time: end)))"), dismissButton: .default(Text("OK")))
                }
            }

            Button(action: {
                withAnimation {
                    showPieChart.toggle()
                }
            }) {
                Label("円グラフ表示", systemImage: "chart.pie.fill")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            if showPieChart {
                PieChartView(schedules: schedules, currentTime: currentTime, onTapSchedule: { tapped in
                    selectedSchedule = tapped
                })
                .frame(height: 400)
                .padding(.bottom)
                .sheet(item: $selectedSchedule) { schedule in
                    VStack(spacing: 16) {
                        Text("\(schedule.title)")
                            .font(.title2)
                        Text("開始: \(formatter.string(from: schedule.start))")
                        Text("終了: \(formatter.string(from: schedule.end))")
                    }
                    .padding()
                }
            }
        }
        .padding(.top)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
                currentTime = Date()
            }
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

    func addToAppleCalendar(title: String, startDate: Date, endDate: Date) {
        let eventStore = EKEventStore()
        eventStore.requestFullAccessToEvents { granted, error in
            if granted && error == nil {
                let event = EKEvent(eventStore: eventStore)
                event.title = title
                event.startDate = startDate
                event.endDate = endDate
                event.calendar = eventStore.defaultCalendarForNewEvents

                let alarm = EKAlarm(relativeOffset: -300)
                event.addAlarm(alarm)

                do {
                    try eventStore.save(event, span: .thisEvent)
                    print("✅ カレンダーに登録されました")
                } catch let err {
                    print("❌ カレンダー登録失敗: \(err)")
                }
            } else {
                print("❌ カレンダーの使用が許可されていません")
            }
        }
    }

    func addToReminders(title: String, dueDate: Date) {
        let eventStore = EKEventStore()
        eventStore.requestFullAccessToReminders { granted, error in
            if granted && error == nil {
                let reminder = EKReminder(eventStore: eventStore)
                reminder.title = title
                reminder.calendar = eventStore.defaultCalendarForNewReminders()
                reminder.dueDateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: dueDate)

                do {
                    try eventStore.save(reminder, commit: true)
                    print("✅ リマインダーに登録されました")
                } catch let err {
                    print("❌ リマインダー登録失敗: \(err)")
                }
            } else {
                print("❌ リマインダーの使用が許可されていません")
            }
        }
    }
}
