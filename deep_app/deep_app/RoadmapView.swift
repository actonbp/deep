import SwiftUI

struct RoadmapView: View {
    // Access the shared store
    @ObservedObject private var todoListStore = TodoListStore.shared
    
    // --- State for Zoom/Pan --- 
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0 // Store committed scale
    @State private var currentOffset: CGSize = .zero
    @State private var finalOffset: CGSize = .zero // Store committed offset
    // --------------------------
    
    // Consistent title styling
    let titleFontSize: CGFloat = 22 
    let sciFiFont = "Orbitron"

    var body: some View {
        NavigationView {
            // --- Replace List with ScrollView + Canvas --- 
            ScrollView([.horizontal, .vertical]) { // Allow both directions
                // Pass grouped data and settings to the Canvas View
                RoadmapCanvasView(groupedTasks: groupedTasks, 
                                  sortedTopLevelKeys: sortedTopLevelKeys,
                                  areCategoriesEnabled: areCategoriesEnabled,
                                  size: CGSize(width: 1000, height: 1500)) // Pass intended size
                .scaleEffect(currentScale) 
                .offset(currentOffset) 
                .frame(width: 1000, height: 1500) // Keep frame on the inner view
            }
            // --- Revised Gesture Logic --- 
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                           // Calculate new scale based on gesture value and previous final scale
                           currentScale = finalScale * value
                           // Clamp during gesture for immediate feedback
                           currentScale = max(0.5, min(currentScale, 3.0))
                        }
                        .onEnded { value in
                            // Commit the final scale
                            finalScale = currentScale
                        },
                    DragGesture()
                        .onChanged { value in
                            // Calculate new offset based on gesture translation and previous final offset
                            currentOffset.width = finalOffset.width + value.translation.width
                            currentOffset.height = finalOffset.height + value.translation.height
                        }
                        .onEnded { value in
                            // Commit the final offset
                            finalOffset = currentOffset
                        }
                )
            )
            // -----------------------------
            .navigationTitle("Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            // Apply consistent navigation bar styling
            .toolbarBackground(.indigo, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar) 
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Roadmap")
                        .font(.custom(sciFiFont, size: titleFontSize))
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.titleText)
                }
                // Potential future toolbar items (e.g., filter/sort)
            }
            .background(Color.theme.background.ignoresSafeArea())
            .foregroundColor(Color.theme.text)
        }
    }
    
    // --- Computed Property for Grouping --- 
    // --- MODIFIED to handle categories disabled ---
    private var groupedTasks: [String: [String?: [TodoItem]]] {
        let categoriesEnabled = UserDefaults.standard.bool(forKey: AppSettings.enableCategoriesKey)
        
        if categoriesEnabled {
            // Group by Category, then Project (existing logic)
            let defaultCategory = "(Uncategorized)"
            let groupedByCategory = Dictionary(grouping: todoListStore.items) { item in
                item.category ?? defaultCategory
            }
            
            var finalGrouped: [String: [String?: [TodoItem]]] = [:]
            for (category, itemsInCategory) in groupedByCategory {
                finalGrouped[category] = Dictionary(grouping: itemsInCategory) { item in
                    item.projectOrPath // Use optional String? as key
                }
            }
            return finalGrouped
        } else {
            // Categories Disabled: Group all under a single key, then by Project
            let allProjectsGrouped = Dictionary(grouping: todoListStore.items) { item in
                item.projectOrPath // Use optional String? as key
            }
            // Return a dictionary with one entry using a placeholder key
            return ["(All Projects)": allProjectsGrouped] 
        }
    }
    // -------------------------------------------
    
    // --- Computed Property for Sorted Top-Level Keys --- 
    private var sortedTopLevelKeys: [String] {
        return groupedTasks.keys.sorted()
    }
    // --------------------------------------------------
    
    // --- Computed Property to check if Categories are enabled ---
    private var areCategoriesEnabled: Bool {
        UserDefaults.standard.bool(forKey: AppSettings.enableCategoriesKey)
    }
    // -----------------------------------------------------------
}

// --- MODIFIED Canvas Drawing Logic (Reverting to Vertical Project Layout) ---
struct RoadmapCanvasView: View { 
    let groupedTasks: [String: [String?: [TodoItem]]]
    let sortedTopLevelKeys: [String]
    let areCategoriesEnabled: Bool
    let size: CGSize // Pass size from Canvas
    
    // --- REMOVED projectXOffsets State ---
    // @State private var projectXOffsets: [String: CGFloat] = [:] 
    // -----------------------------------

    let projectPadding: CGFloat = 30 // Unused now

    // Drawing constants (Adjusted for vertical project layout)
    let categoryHeaderSpacing: CGFloat = 30
    let projectHeaderSpacing: CGFloat = 110 // Increased vertical spacing between project headers
    let projectHeaderIndent: CGFloat = 20 // Indent project headers under category (if enabled)
    let taskHorizontalSpacing: CGFloat = 75 
    let taskVerticalOffset: CGFloat = 8
    let milestoneRadius: CGFloat = 5
    let taskFontSize: Font = .caption2
    let doneColor = Color.green // Use green for completed tasks
    let todoColor = Color.secondary // Keep grey for pending tasks
    let lineStyle = StrokeStyle(lineWidth: 3.0, lineCap: .round)
    let headerX: CGFloat = 50 // X position for headers
    let headerPadding: CGFloat = 4
    let headerCornerRadius: CGFloat = 6
    let textRotationAngle = Angle(degrees: 45) // Angle for task text
    let textPaddingBelowDot: CGFloat = 8 // Padding between dot and start of text

    var body: some View {
        Canvas { context, canvasSize in
            var currentY: CGFloat = 50 // Tracks the vertical position

            for topLevelKey in sortedTopLevelKeys {
                // --- Draw Category Header (Conditional) ---
                if areCategoriesEnabled {
                    let headerPoint = CGPoint(x: headerX, y: currentY)
                    let categoryTitle = Text(topLevelKey).font(.title2).bold().foregroundColor(Color.theme.text)
                    let resolvedCategoryTitle = context.resolve(categoryTitle)
                    let categoryTitleSize = resolvedCategoryTitle.measure(in: canvasSize)
                    
                    // Draw background similar to project headers, but maybe different color
                    let categoryBackgroundRect = CGRect(x: headerPoint.x - headerPadding,
                                                        y: headerPoint.y - headerPadding,
                                                        width: categoryTitleSize.width + headerPadding * 2,
                                                        height: categoryTitleSize.height + headerPadding * 2)
                    context.fill(Path(roundedRect: categoryBackgroundRect, cornerRadius: headerCornerRadius), with: .color(Color(.systemGray4)))
                    
                    // Draw the text itself
                    context.draw(resolvedCategoryTitle, at: headerPoint, anchor: .topLeading)
                    
                    currentY += categoryTitleSize.height + headerPadding * 2 + categoryHeaderSpacing // Adjust spacing
                } else {
                     // If categories are disabled, add some initial top padding
                     currentY += categoryHeaderSpacing // Use the same spacing for consistency
                }
                // -----------------------------------------
                
                guard let projectsInGroup = groupedTasks[topLevelKey] else { continue }
                let sortedProjects = projectsInGroup.keys.sorted { $0 ?? "_" < $1 ?? "_" }
                
                // --- Loop through projects VERTICALLY --- 
                for projectOrPath in sortedProjects {
                    guard let tasks = projectsInGroup[projectOrPath], !tasks.isEmpty else { continue }
                    
                    // --- Determine Project Header X Position --- 
                    let projectX = areCategoriesEnabled ? headerX + projectHeaderIndent : headerX
                    // -----------------------------------------
                    
                    let projectTitle = projectOrPath ?? "(Unassigned Project)"
                    let projectHeaderPoint = CGPoint(x: projectX, y: currentY)
                    
                    // --- Draw Project Header with Background --- 
                    let resolvedProjectTitle = context.resolve(Text(projectTitle).font(.headline).foregroundColor(Color.theme.text))
                    let titleSize = resolvedProjectTitle.measure(in: canvasSize)
                    let backgroundRect = CGRect(x: projectHeaderPoint.x - headerPadding,
                                                y: projectHeaderPoint.y - headerPadding,
                                                width: titleSize.width + headerPadding * 2,
                                                height: titleSize.height + headerPadding * 2)
                    context.fill(Path(roundedRect: backgroundRect, cornerRadius: headerCornerRadius), with: .color(Color(.systemGray5)))
                    context.draw(resolvedProjectTitle, at: projectHeaderPoint, anchor: .topLeading)
                    // ------------------------------------------
                    
                    // Y position for the task dots/line (below header)
                    let taskY = currentY + titleSize.height + taskVerticalOffset 
                    
                    let sortedTasks = tasks.sorted { /* Priority Sort Logic */
                        guard let p1 = $0.priority else { return false } 
                        guard let p2 = $1.priority else { return true }  
                        return p1 < p2 
                    }

                    // --- Task Drawing Logic (Horizontal Extension) --- 
                    var taskX = projectX // Start tasks horizontally from the project header X
                    var previousTaskCenter: CGPoint? = nil
                    var previousTaskIsDone: Bool = false
                    var maxTaskTextY: CGFloat = taskY // Track lowest point reached by text in this row
                    
                    // --- REMOVE Stagger Text Variable --- 
                    // let textVerticalSeparation: CGFloat = 10 

                    // --- REMOVE enumerated() --- 
                    for item in sortedTasks { 
                        let taskCenter = CGPoint(x: taskX, y: taskY)
                        let milestonePath = Path(ellipseIn: CGRect(x: taskCenter.x - milestoneRadius, y: taskCenter.y - milestoneRadius, width: milestoneRadius * 2, height: milestoneRadius * 2))
                        let taskColor = item.isDone ? doneColor : todoColor
                        context.fill(milestonePath, with: .color(taskColor))

                        // --- Draw Inner Dot for Target Look ---
                        let innerDotRadius = milestoneRadius * 0.4
                        let innerDotPath = Path(ellipseIn: CGRect(x: taskCenter.x - innerDotRadius, y: taskCenter.y - innerDotRadius, width: innerDotRadius * 2, height: innerDotRadius * 2))
                        context.fill(innerDotPath, with: .color(.white))
                        // -------------------------------------

                        // --- Draw Task Text (Diagonally Rotated) ---
                        let textDrawPoint = CGPoint(x: taskCenter.x,
                                                  y: taskCenter.y + milestoneRadius + textPaddingBelowDot)

                        // Translate to origin, rotate, translate back
                        context.translateBy(x: textDrawPoint.x, y: textDrawPoint.y)
                        context.rotate(by: textRotationAngle)
                        context.translateBy(x: -textDrawPoint.x, y: -textDrawPoint.y)

                        let resolvedText = context.resolve(Text(item.text).font(taskFontSize).foregroundColor(Color.theme.text))
                        let textSize = resolvedText.measure(in: canvasSize) // Measure for layout
                        // Draw text at the original point, but the context is rotated
                        context.draw(resolvedText, at: textDrawPoint, anchor: .topLeading)

                        // --- IMPORTANT: Reset transformations --- 
                        // Apply inverse transformations in reverse order
                        context.translateBy(x: textDrawPoint.x, y: textDrawPoint.y)
                        context.rotate(by: -textRotationAngle)
                        context.translateBy(x: -textDrawPoint.x, y: -textDrawPoint.y)
                        // --------------------------------------

                        // --- Update Max Y --- 
                        // Estimate max Y based on unrotated position + buffer, refine if needed
                        maxTaskTextY = max(maxTaskTextY, textDrawPoint.y + textSize.height + textPaddingBelowDot * 2) // Add extra padding
                        // -------------------
                        
                        // --- Draw Horizontal Connecting Line --- 
                        if let previousCenter = previousTaskCenter {
                            var linePath = Path()
                            linePath.move(to: CGPoint(x: previousCenter.x + milestoneRadius, y: previousCenter.y))
                            linePath.addLine(to: CGPoint(x: taskCenter.x - milestoneRadius, y: taskCenter.y))
                            let lineColor = previousTaskIsDone ? doneColor : todoColor
                            context.stroke(linePath, with: .color(lineColor), style: lineStyle)
                        }
                        // -------------------------------------
                        
                        previousTaskCenter = taskCenter
                        previousTaskIsDone = item.isDone 
                        taskX += taskHorizontalSpacing // Move right for next task dot
                    }
                    // --- End Task Drawing --- 

                    // --- Update currentY for the NEXT project --- 
                    // Base it on the lowest point reached (header or task text) + spacing
                    currentY = max(currentY + titleSize.height, maxTaskTextY) + projectHeaderSpacing
                    // -------------------------------------------
                }
                // --- End Project Loop ---
                
                // Add a bit more space after a category group (if enabled)
                if areCategoriesEnabled { currentY += categoryHeaderSpacing * 0.5 }

            }
            // --- End Top Level Key Loop ---
        }
        // --- REMOVED onAppear reset logic as state was removed --- 
        // .onAppear { ... }
        // --------------------------------------------------------
    }
}
// ----------------------------------------------------------------------------

#Preview {
    // Provide dummy store for preview if needed
    RoadmapView()
        // .environmentObject(TodoListStore.shared) // Example if store needed deep state
} 