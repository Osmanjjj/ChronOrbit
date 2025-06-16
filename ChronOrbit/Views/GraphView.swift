import SwiftUI

struct PieChartView: View {
    let schedules: [Schedule]
    let currentTime: Date
    let onTapSchedule: (Schedule) -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(Array(schedules.enumerated()), id: \.offset) { index, schedule in
                    let totalMinutes = 24 * 60
                    let startMinutes = Calendar.current.component(.hour, from: schedule.start) * 60 + Calendar.current.component(.minute, from: schedule.start)
                    let endMinutes = Calendar.current.component(.hour, from: schedule.end) * 60 + Calendar.current.component(.minute, from: schedule.end)
                    let angleStart = Angle(degrees: Double(startMinutes) / Double(totalMinutes) * 360)
                    let angleEnd = Angle(degrees: Double(endMinutes) / Double(totalMinutes) * 360)

                    let isCurrent = currentTime >= schedule.start && currentTime <= schedule.end

                    PieSlice(startAngle: angleStart, endAngle: angleEnd)
                        .fill(Color(hue: Double(index) / Double(schedules.count), saturation: 0.7, brightness: 0.9))
                        .overlay(
                            isCurrent ? PieSlice(startAngle: angleStart, endAngle: angleEnd)
                                .stroke(Color.red, lineWidth: 4) : nil
                        )
                        .onTapGesture {
                            onTapSchedule(schedule)
                        }
                }

                Circle()
                    .fill(Color.white)
                    .frame(width: geometry.size.width * 0.4, height: geometry.size.width * 0.4)

                VStack {
                    if let current = schedules.first(where: { currentTime >= $0.start && currentTime <= $0.end }) {
                        Text(current.title)
                            .font(.headline)
                        let minutesLeft = Int(current.end.timeIntervalSince(currentTime) / 60)
                        Text("あと\(minutesLeft)分")
                            .font(.caption)
                    } else {
                        Text("現在予定なし")
                            .font(.caption)
                    }

                    Text("\u{1F551}")
                        .font(.title2)
                    Text(DateFormatter.localizedString(from: currentTime, dateStyle: .none, timeStyle: .short))
                        .font(.caption)
                }
            }
        }
    }
}

struct PieSlice: Shape {
    let startAngle: Angle
    let endAngle: Angle

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        path.move(to: center)
        path.addArc(center: center, radius: rect.width / 2, startAngle: startAngle - Angle(degrees: 90), endAngle: endAngle - Angle(degrees: 90), clockwise: false)
        path.closeSubpath()
        return path
    }
}
