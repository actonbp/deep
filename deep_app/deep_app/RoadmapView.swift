import SwiftUI

struct RoadmapView: View {
    // Access the shared store
    @ObservedObject private var todoListStore = TodoListStore.shared
    
    // State for Zoom/Pan
    @State private var currentScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    @State private var currentOffset: CGSize = .zero
    @State private var finalOffset: CGSize = .zero
    
    // Consistent title styling
    let titleFontSize: CGFloat = 22 
    let sciFiFont = "Orbitron"

    var body: some View {
        NavigationView {
            // Gamified Island Map
            ScrollView([.horizontal, .vertical]) {
                GameMapCanvasView(
                    projects: projectIslands,
                    size: CGSize(width: 1400, height: 900)
                )
                .scaleEffect(currentScale)
                .offset(currentOffset)
                .frame(width: 1400, height: 900)
            }
            .background(
                // Sky background gradient
                LinearGradient(
                    gradient: Gradient(colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .gesture(
                SimultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                           currentScale = finalScale * value
                           currentScale = max(0.5, min(currentScale, 3.0))
                        }
                        .onEnded { value in
                            finalScale = currentScale
                        },
                    DragGesture()
                        .onChanged { value in
                            currentOffset.width = finalOffset.width + value.translation.width
                            currentOffset.height = finalOffset.height + value.translation.height
                        }
                        .onEnded { value in
                            finalOffset = currentOffset
                        }
                )
            )
            .navigationTitle("Roadmap")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.indigo, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar) 
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Quest Map")
                        .font(.custom(sciFiFont, size: titleFontSize))
                        .fontWeight(.bold)
                        .foregroundColor(Color.theme.titleText)
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    // Reset zoom button
                    Button {
                        withAnimation(.smooth) {
                            currentScale = 1.0
                            finalScale = 1.0
                            currentOffset = .zero
                            finalOffset = .zero
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color.theme.titleText)
                    }
                }
            }
        }
    }
    
    // Convert tasks into project islands
    private var projectIslands: [ProjectIsland] {
        let groupedByProject = Dictionary(grouping: todoListStore.items) { item in
            item.projectOrPath ?? "Unassigned"
        }
        
        var islands: [ProjectIsland] = []
        var yOffset: CGFloat = 100
        var xOffset: CGFloat = 200
        
        for (projectName, tasks) in groupedByProject {
            // Determine project type from first task
            let projectType = tasks.first?.projectType ?? .personal
            
            // Calculate progress
            let completedTasks = tasks.filter { $0.isDone }.count
            let totalTasks = tasks.count
            let progress = totalTasks > 0 ? Double(completedTasks) / Double(totalTasks) : 0.0
            
            // Calculate level based on number of tasks
            let level = min(5, max(1, totalTasks / 3))
            
            // Calculate XP (10 points per completed task)
            let xp = completedTasks * 10
            
            // Check for achievements
            let hasAchievement = completedTasks >= 5 || progress >= 0.8
            
            let island = ProjectIsland(
                id: UUID(),
                title: projectName,
                type: projectType,
                position: CGPoint(x: xOffset, y: yOffset),
                tasks: tasks,
                level: level,
                xp: xp,
                progress: progress,
                hasAchievement: hasAchievement
            )
            
            islands.append(island)
            
            // Position next island
            xOffset += 300
            if xOffset > 1100 {
                xOffset = 200
                yOffset += 250
            }
        }
        
        return islands
    }
}

// MARK: - Project Island Model
struct ProjectIsland: Identifiable {
    let id: UUID
    let title: String
    let type: ProjectType
    let position: CGPoint
    let tasks: [TodoItem]
    let level: Int
    let xp: Int
    let progress: Double
    let hasAchievement: Bool
}

// MARK: - Game Map Canvas
struct GameMapCanvasView: View {
    let projects: [ProjectIsland]
    let size: CGSize
    
    var body: some View {
        ZStack {
            // Background islands
            ForEach(projects) { project in
                ProjectIslandView(island: project)
            }
            
            // Connecting bridges
            ForEach(Array(projects.enumerated()), id: \.element.id) { index, project in
                if index > 0 {
                    BridgeView(
                        from: projects[index - 1].position,
                        to: project.position
                    )
                }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

// MARK: - Project Island View
struct ProjectIslandView: View {
    let island: ProjectIsland
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Achievement badge
            if island.hasAchievement {
                Text("🌟")
                    .font(.title)
                    .offset(y: -10)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(), value: isAnimating)
            }
            
            // Main island
            VStack(spacing: 12) {
                // Header with icon and title
                HStack {
                    Text(island.type.icon)
                        .font(.title)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(island.title)
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Lv \(island.level)")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(8)
                    }
                    
                    Spacer()
                }
                
                // Quest dots (tasks)
                LazyVGrid(columns: Array(repeating: GridItem(.fixed(16), spacing: 4), count: 8), spacing: 4) {
                    ForEach(Array(island.tasks.enumerated()), id: \.element.id) { index, task in
                        Circle()
                            .fill(task.isDone ? Color.green : Color.white.opacity(0.6))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Circle()
                                    .stroke(island.typeColor, lineWidth: 2)
                            )
                            .overlay(
                                // Checkmark for completed tasks
                                Group {
                                    if task.isDone {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 6, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            )
                    }
                }
                .padding(.vertical, 4)
                
                // Stats
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Text("⚡")
                        Text("\(island.tasks.filter { $0.isDone }.count)/\(island.tasks.count)")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    
                    HStack(spacing: 4) {
                        Text("💎")
                        Text("\(island.xp) XP")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    
                    Spacer()
                }
                .foregroundColor(.secondary)
            }
            .padding(20)
            .background(
                // Island gradient background
                LinearGradient(
                    gradient: Gradient(colors: [
                        island.typeColor.opacity(0.3),
                        island.typeColor.opacity(0.1)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Progress ring
                Circle()
                    .trim(from: 0, to: island.progress)
                    .stroke(
                        island.typeColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .scaleEffect(1.1)
                    .opacity(0.8)
            )
            .overlay(
                // Border
                RoundedRectangle(cornerRadius: 24)
                    .stroke(island.typeColor, lineWidth: 3)
            )
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
            .frame(width: 200, height: 160)
        }
        .position(island.position)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Bridge View
struct BridgeView: View {
    let from: CGPoint
    let to: CGPoint
    
    var body: some View {
        Path { path in
            // Create a curved bridge
            let midX = (from.x + to.x) / 2
            let midY = (from.y + to.y) / 2 - 30 // Curve upward
            
            path.move(to: from)
            path.addQuadCurve(to: to, control: CGPoint(x: midX, y: midY))
        }
        .stroke(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.indigo.opacity(0.3),
                    Color.indigo.opacity(0.6),
                    Color.indigo.opacity(0.3)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            ),
            style: StrokeStyle(lineWidth: 4, lineCap: .round)
        )
        .zIndex(-1)
    }
}

// MARK: - Extensions
extension ProjectType {
    var color: Color {
        switch self {
        case .work: return Color("ProjectBlue") // Use your new colors
        case .personal: return Color("ProjectPurple") 
        case .health: return Color("ProjectGreen")
        case .learning: return Color("ProjectYellow")
        }
    }
}

extension ProjectIsland {
    var typeColor: Color {
        return type.color
    }
}

#Preview {
    RoadmapView()
}