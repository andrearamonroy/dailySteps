//
//  dailyStepsWidgetLiveActivity.swift
//  dailyStepsWidget
//
//  Created by Andrea Monroy on 12/30/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct dailyStepsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct dailyStepsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: dailyStepsWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension dailyStepsWidgetAttributes {
    fileprivate static var preview: dailyStepsWidgetAttributes {
        dailyStepsWidgetAttributes(name: "World")
    }
}

extension dailyStepsWidgetAttributes.ContentState {
    fileprivate static var smiley: dailyStepsWidgetAttributes.ContentState {
        dailyStepsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: dailyStepsWidgetAttributes.ContentState {
         dailyStepsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: dailyStepsWidgetAttributes.preview) {
   dailyStepsWidgetLiveActivity()
} contentStates: {
    dailyStepsWidgetAttributes.ContentState.smiley
    dailyStepsWidgetAttributes.ContentState.starEyes
}
