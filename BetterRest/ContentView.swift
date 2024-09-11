import CoreML
import SwiftUI

struct ContentView: View {
    // State variables to hold the user's input and calculated bedtime
    @State private var sleepAmount = 8.0  // Default sleep amount set to 8 hours
    @State private var wakeUp = defaultWakeTime  // Default wake up time
    @State private var coffeeAmount = 0  // Default coffee amount is 0 cups
    @State private var recommendedBedtime = ""  // Recommended bedtime, initially empty
    
    // Static variable to set a default wake-up time (7:00 AM)
    static var defaultWakeTime: Date {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? .now
    }
    
    // The main view body
    var body: some View {
        NavigationStack {
            Form {
                // Section for wake-up time selection
                Section("When do you want to wake up") {
                    DatePicker("Please enter a time", selection: $wakeUp, displayedComponents: .hourAndMinute)
                        .labelsHidden()  // Hide the label for a cleaner look
                        .onChange(of: wakeUp) { newValue in calculateBedTime()
                        }  // Call calculateBedTime when wake-up time changes
                }
                
                // Section for desired sleep amount selection
                Section("Desired amount of sleep") {
                    Stepper("\(sleepAmount.formatted()) hours", value: $sleepAmount, in: 4...12, step: 0.25)
                        .onChange(of: sleepAmount) { newValue in calculateBedTime()
                        }  // Call calculateBedTime when sleep amount changes
                }
                
                // Section for daily coffee intake selection
                Section("Daily coffee intake") {
                    Picker("^[\(coffeeAmount) cup](inflect: true)", selection: $coffeeAmount) {
                        ForEach(0..<21) { number in  // Allow the user to choose between 0 and 20 cups of coffee
                            Text("\(number)")  // Display each number as a text item in the picker
                        }
                    }
                    .pickerStyle(.navigationLink)  // Use a navigation link picker style for better UX
                    .onChange(of: coffeeAmount) { newValue in calculateBedTime()
                    }  // Call calculateBedTime when coffee intake changes
                }
                
                // Section to display the recommended bedtime dynamically
                Section {
                    Text("Your ideal bedtime is \(recommendedBedtime)")  // Display the calculated bedtime
                        .font(.title3)  // Use the title3 font for emphasis
                        .foregroundColor(.blue)  // Set the text color to blue
                        .padding()  // Add some padding around the text
                }
            }
            .navigationTitle("BetterRest")  // Set the navigation title
            .navigationBarTitleDisplayMode(.inline)  // Display the title inline
        }
        .onAppear(perform: calculateBedTime)  // Calculate bedtime when the view appears
    }
    
    // Function to calculate the recommended bedtime using CoreML
    func calculateBedTime() {
        do {
            let config = MLModelConfiguration()  // Create a configuration for the ML model
            let model = try SleepCalculator(configuration: config)  // Initialize the SleepCalculator model
            
            // Get the hour and minute components from the selected wake-up time
            let components = Calendar.current.dateComponents([.hour, .minute], from: wakeUp)
            let hour = (components.hour ?? 0) * 60 * 60  // Convert hours to seconds
            let minute = (components.minute ?? 0) * 60  // Convert minutes to seconds
            
            // Make a prediction using the model
            let prediction = try model.prediction(wake: Double(hour + minute), estimatedSleep: sleepAmount, coffee: Double(coffeeAmount))
            
            // Calculate the ideal bedtime by subtracting the predicted sleep duration from the wake-up time
            let sleepTime = wakeUp - prediction.actualSleep
            
            // Update the recommended bedtime as a formatted string
            recommendedBedtime = sleepTime.formatted(date: .omitted, time: .shortened)
        } catch {
            // Handle any errors by setting the recommended bedtime to an error message
            recommendedBedtime = "Error calculating bedtime"
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()  // Show a preview of the ContentView
    }
}

