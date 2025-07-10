// Define a Task
class Task {
    let execute: () -> Void
    let name: String

    init(name: String, execute: @escaping () -> Void) {
        self.name = name
        self.execute = execute
    }
}

// Define a Scheduler
class Scheduler {
    private var taskQueue: [Task] = []

    // Add a task to the queue
    func addTask(_ task: Task) {
        taskQueue.append(task)
    }

    // Run the scheduled tasks
    func run() {
        while !taskQueue.isEmpty {
            let task = taskQueue.removeFirst()
            // In a bare-metal environment, consider using hardware-specific code to switch tasks
            print("Running \(task.name)")
            task.execute()
        }
    }
}
