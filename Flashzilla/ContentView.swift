//
//  ContentView.swift
//  Flashzilla
//
//  Created by Rishav Gupta on 03/07/23.
//

import CoreHaptics
import SwiftUI

func withOptionalAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    if UIAccessibility.isReduceMotionEnabled {
        return try body()
    } else {
        return try withAnimation(animation, body)
    }
}

struct ContentView: View {
    @State private var currentAmount = Angle.zero //0.0
    @State private var finalAmount = Angle.zero //1.0
    
    @State private var offset = CGSize.zero
    @State private var isDragging = false
    
    @State private var engine: CHHapticEngine?
    
    let timer = Timer.publish(every: 1, tolerance: 0.5, on: .main, in: .common).autoconnect()
    @State private var counter = 0
    
    @Environment(\.scenePhase) var scenePhase
    
    @Environment(\.accessibilityDifferentiateWithoutColor) var differentiateWithoutColor
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @Environment(\.accessibilityReduceTransparency) var reduceTransparancy
    
    @State private var scale = 1.0
    
    var body: some View {
        let dragGesture = DragGesture()
            .onChanged { value in
                offset = value.translation
            }
            .onEnded { _ in
                withAnimation {
                    offset = .zero
                    isDragging = false
                }
            }
        
        let pressedGesture = LongPressGesture()
            .onChanged { value in
                withAnimation {
                    isDragging = true
                }
            }
        
        let combined = pressedGesture.sequenced(before: dragGesture)
        
        VStack {
            Text("Hello, world!")
//                .onLongPressGesture(minimumDuration: 1) {
//                    print("Long Pressed!")
//                } onPressingChanged: { inProgress in
//                    print("In progress \(inProgress)")
//                }
//                .scaleEffect(finalAmount + currentAmount)
                .rotationEffect(currentAmount + finalAmount)
                .gesture(
//                    MagnificationGesture()
                    RotationGesture()
                        .onChanged { amount in
                            currentAmount = amount // - 1
                        }
                        .onEnded { amount in
                            finalAmount += currentAmount
                            currentAmount = .zero //0
                        }
                )
            
            Circle()
                .fill(.red)
                .frame(width: 64, height: 64)
                .scaleEffect(isDragging ? 1.5 : 1)
                .offset(offset)
                .gesture(combined)
                .onAppear(perform: prepareHaptics)
                .onTapGesture(perform: complexSuccess)
            
            ZStack {
                Rectangle()
                    .fill(.blue)
                    .frame(width: 300, height: 300)
                    .onTapGesture {
                        print("Rectangle Tapped")
                    }
                
                Circle()
                    .fill(.red)
                    .frame(width: 300, height: 300)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        print("Circle Tapped")
                    }
//                    .allowsHitTesting(true)
            }
            
            VStack {
                Text("hello")
                Spacer().frame(height: 100)
                Text("world")
                    .scaleEffect(scale)
                    .onTapGesture {
                        withOptionalAnimation {
                            scale *= 1.5
                        }
                    }
            }
            .contentShape(Rectangle()) // whole area becomes tappable
            .onTapGesture {
                print("Hello world tapped")
            }

        }
        .onReceive(timer) { time in
            if counter == 5 {
                timer.upstream.connect().cancel()
            } else {
                print("The time is now \(time)")
            }
            
            counter += 1
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                print("Active")
            } else if newPhase == .inactive {
                print("Inactive")
            } else if newPhase == .background {
                print("Background")
            }
        }
//        .highPriorityGesture(
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    print("VStack Tapped")
                }
        )
    }
    
    func simpleSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("There was an error creating the engine \(error.localizedDescription)")
        }
    }
    
    func complexSuccess() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        
        var events = [CHHapticEvent]()
        
        for i in stride(from: 0, to: 1, by: 0.1) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(i))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(i))
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: i)
            events.append(event)
        }
        
        for i in stride(from: 0, to: 1, by: 0.1) {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: Float(1 - i))
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: Float(1 - i))
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 1 + i)
            events.append(event)
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0)
        } catch {
            print("Failed to play pattern \(error.localizedDescription)")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
