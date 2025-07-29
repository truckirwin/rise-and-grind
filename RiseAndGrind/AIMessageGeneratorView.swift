import SwiftUI
import Foundation

// MARK: - AI Message Generator View
struct AIMessageGeneratorView: View {
    // Slider states
    @State private var intensity: Double = 50
    @State private var languageClean: Double = 50
    @State private var humorStyle: Double = 50
    @State private var actionOrientation: Double = 50
    @State private var messageLength: Double = 50
    @State private var musicStyle: Double = 50
    @State private var visualStyle: Double = 50
    
    // Input and output states
    @State private var userInput: String = ""
    @State private var generatedMessage: String = ""
    @State private var isGenerating: Bool = false
    @State private var messageStyle: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Match your app's background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                            
                            Text("AI Message Generator")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                            
                            Text("Customize your perfect motivational message")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        .padding(.top)
                        
                        // User Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("What do you need motivation for?")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextField("e.g., waking up early, starting a workout routine...", text: $userInput, axis: .vertical)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .lineLimit(3...6)
                        }
                        .padding(.horizontal)
                        
                        // Slider Controls
                        VStack(spacing: 20) {
                            AISliderRow(title: "Intensity", value: $intensity, 
                                    leftLabel: "😌 Chill", rightLabel: "💪 Drill Sergeant")
                            
                            AISliderRow(title: "Language Style", value: $languageClean,
                                    leftLabel: "🤬 Raw", rightLabel: "😇 Clean")
                            
                            AISliderRow(title: "Humor Level", value: $humorStyle,
                                    leftLabel: "😐 Serious", rightLabel: "😂 Funny")
                            
                            AISliderRow(title: "Approach", value: $actionOrientation,
                                    leftLabel: "🧘 Mindful", rightLabel: "⚡ Action")
                            
                            AISliderRow(title: "Message Length", value: $messageLength,
                                    leftLabel: "💬 Quote", rightLabel: "📜 Speech")
                            
                            AISliderRow(title: "Music Style", value: $musicStyle,
                                    leftLabel: "🎵 Chill", rightLabel: "🎸 Rock")
                            
                            AISliderRow(title: "Visual Style", value: $visualStyle,
                                    leftLabel: "🖼️ Still", rightLabel: "🎬 Video")
                        }
                        .padding(.horizontal)
                        
                        // Generate Button
                        Button(action: generateMessage) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.8)
                                    Text("Generating...")
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generate My Message")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(userInput.isEmpty ? Color.gray : Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .font(.headline)
                        }
                        .disabled(userInput.isEmpty || isGenerating)
                        .padding(.horizontal)
                        
                        // Generated Message Display
                        if !generatedMessage.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Your Personalized Message")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.horizontal)
                                
                                VStack(spacing: 12) {
                                    // Message Card
                                    Text(generatedMessage)
                                        .padding()
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .font(.body)
                                        .lineSpacing(4)
                                    
                                    // Metadata
                                    HStack {
                                        VStack {
                                            Text("Style")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(messageStyle.capitalized)
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack {
                                            Text("Intensity")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text("\(Int(intensity))%")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                        
                                        Spacer()
                                        
                                        VStack {
                                            Text("Length")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Text(messageLength > 50 ? "Long" : "Short")
                                                .font(.caption2)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.white)
                                        }
                                    }
                                    .padding(.horizontal, 8)
                                }
                                .padding(.horizontal)
                            }
                        }
                        
                        Spacer(minLength: 20)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func generateMessage() {
        guard !userInput.isEmpty else { return }
        
        isGenerating = true
        
        // Simulate processing delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let style = determineMessageStyle()
            messageStyle = style
            generatedMessage = createMessage(style: style, topic: userInput)
            isGenerating = false
        }
    }
    
    private func determineMessageStyle() -> String {
        if intensity > 80 {
            return languageClean < 30 ? "Ultra Intense" : "Drill Sergeant"
        } else if intensity < 30 {
            return "Zen & Mindful"
        } else if humorStyle > 60 {
            return languageClean > 70 ? "Motivational Comedy" : "Raw Comedy"
        } else {
            return "Rise & Grind"
        }
    }
    
    private func createMessage(style: String, topic: String) -> String {
        let templates = [
            "Ultra Intense": "🔥 TIME TO ABSOLUTELY DOMINATE \(topic.uppercased())! No excuses, no delays, just pure RELENTLESS ACTION! Your future self is watching - make them proud!",
            
            "Drill Sergeant": "⚡ LISTEN UP! \(topic.capitalized) isn't just a goal - it's your MISSION! Stop making excuses and START MAKING MOVES! Discipline equals freedom!",
            
            "Zen & Mindful": "🧘‍♀️ Take a deep breath and center yourself. Your journey with \(topic) is unfolding perfectly. Trust the process, honor your growth, and remember - every step forward is sacred progress.",
            
            "Motivational Comedy": "😂 So you want to master \(topic)? That's like trying to fold a fitted sheet while riding a unicycle - seems impossible, but hey, at least you'll have some interesting stories to tell! You've got this!",
            
            "Raw Comedy": "😄 Alright, let's talk about \(topic). It's tough, it's going to kick your butt, but you know what? You're tougher! Time to show \(topic) who's boss!",
            
            "Rise & Grind": "💪 TODAY IS THE DAY you take control of \(topic)! No more 'tomorrow' - no more 'when I'm ready' - TODAY is when you start building the life you deserve! Let's GO!"
        ]
        
        return templates[style] ?? "🚀 You've got this! \(topic.capitalized) is just another challenge to conquer. Believe in yourself and take that first step!"
    }
}

// MARK: - Supporting Views

struct AISliderRow: View {
    let title: String
    @Binding var value: Double
    let leftLabel: String
    let rightLabel: String
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(value))")
                    .font(.subheadline)
                    .foregroundColor(.orange)
                    .fontWeight(.semibold)
            }
            
            HStack {
                Text(leftLabel)
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Text(rightLabel)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Slider(value: $value, in: 0...100)
                .accentColor(.orange)
        }
    }
}

// MARK: - Preview
struct AIMessageGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        AIMessageGeneratorView()
    }
} 