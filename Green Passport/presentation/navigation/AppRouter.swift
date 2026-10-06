import Observation

@Observable
final class AppRouter {
    var path: [AppDestination] = []

    func push(_ destination: AppDestination) {
        path.append(destination)
    }
}
