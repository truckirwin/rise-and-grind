import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appViewModel: AppViewModel
    
    private func openLinkedInJobs() {
        if let url = URL(string: "https://www.linkedin.com/jobs/") {
            UIApplication.shared.open(url)
        }
    }
    
    private func openLinkedInMessages() {
        if let url = URL(string: "https://www.linkedin.com/messaging/") {
            UIApplication.shared.open(url)
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // App Title with Profile
                    HStack {
                        Text("Rise and Grind!")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Spacer()
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 35, height: 35)
                            .overlay(
                                Text("J")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )
                    }
                    .padding(.horizontal)
                    
                    // Progress Rings
                    HStack(spacing: 20) {
                        ProgressRing(
                            value: 0,
                            label: "Tasks",
                            color: .blue
                        )
                        
                        ProgressRing(
                            value: 7,
                            label: "Day Streak",
                            color: .orange
                        )
                        
                        ProgressRing(
                            value: "L3",
                            label: "Level",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Quick Actions
                    HStack(spacing: 12) {
                        QuickActionCard(
                            icon: "envelope.fill",
                            label: "Applications",
                            color: .green
                        ) {
                            openLinkedInJobs()
                        }
                        
                        QuickActionCard(
                            icon: "message.fill",
                            label: "Interviews",
                            color: .orange
                        ) {
                            openLinkedInMessages()
                        }
                        
                        QuickActionCard(
                            icon: "brain.head.profile",
                            label: "Skills",
                            color: .purple
                        ) {
                            // Navigate to Learning tab
                        }
                    }
                    .padding(.horizontal)
                    
                    // Let's Go! Featured Message (REPLACES MOTIVATION SECTION)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.blue)
                            Text("Let's Go!")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.blue)
                            Spacer()
                            Button(action: {
                                // Show a random motivational message
                                let randomMessage = DemoVideoScripts.getRandomScript()
                                appViewModel.showAnimatedTextMessage(randomMessage)
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundColor(.blue)
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Rise Up, Job Hunter!")
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            Text("WAKE THE F*CK UP, FUTURE CEO! That last job didn't work out? SO F*CKING WHAT! Today's the day you turn rejection into REDIRECTION!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .lineLimit(3)
                            
                            Text("Tap for full message ➜")
                                .font(.caption)
                                .foregroundColor(.blue)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                        .onTapGesture {
                            // Show the "Rise Up, Job Hunter" message
                            if let message = DemoVideoScripts.demoScripts.first(where: { $0.id == "rise_up_job_hunter" }) {
                                appViewModel.showAnimatedTextMessage(message)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Let's Go! Action Buttons
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "bolt.fill")
                                .foregroundColor(.blue)
                            Text("Let's Go!")
                                .font(.headline)
                                .fontWeight(.bold)
                        }
                        
                        VStack(spacing: 8) {
                            HStack(spacing: 12) {
                                LetsGoButton(
                                    icon: "sunrise.fill",
                                    label: "Morning Power",
                                    subtitle: "Rise & dominate",
                                    color: .orange
                                ) {
                                    let morningMessages = DemoVideoScripts.getMorningDemos()
                                    if let message = morningMessages.randomElement() {
                                        appViewModel.showAnimatedTextMessage(message)
                                    }
                                }
                                
                                LetsGoButton(
                                    icon: "bolt.circle.fill",
                                    label: "Midday Push",
                                    subtitle: "Keep momentum",
                                    color: .blue
                                ) {
                                    let middayMessages = DemoVideoScripts.getMiddayDemos()
                                    if let message = middayMessages.randomElement() {
                                        appViewModel.showAnimatedTextMessage(message)
                                    }
                                }
                            }
                            
                            HStack(spacing: 12) {
                                LetsGoButton(
                                    icon: "flame.fill",
                                    label: "Afternoon Fire",
                                    subtitle: "Final stretch",
                                    color: .red
                                ) {
                                    let afternoonMessages = DemoVideoScripts.getAfternoonDemos()
                                    if let message = afternoonMessages.randomElement() {
                                        appViewModel.showAnimatedTextMessage(message)
                                    }
                                }
                                
                                LetsGoButton(
                                    icon: "star.fill",
                                    label: "Victory Lap",
                                    subtitle: "Celebrate wins",
                                    color: .purple
                                ) {
                                    let eveningMessages = DemoVideoScripts.getEveningDemos()
                                    if let message = eveningMessages.randomElement() {
                                        appViewModel.showAnimatedTextMessage(message)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer(minLength: 80)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Supporting Views

struct ProgressRing: View {
    let value: Any
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 8)
                    .frame(width: 60, height: 60)
                
                Circle()
                    .trim(from: 0, to: 0.7)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 60, height: 60)
                    .rotationEffect(.degrees(-90))
                
                Text("\(value)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.primary)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LetsGoButton: View {
    let icon: String
    let label: String
    let subtitle: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(label)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(color.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppViewModel())
} 