import SwiftUI
import WidgetKit

@main
struct PTVonWidgetBundle: WidgetBundle {
    var body: some Widget {
        DepartureLiveActivity()
        DeparturesWidget()
    }
}
