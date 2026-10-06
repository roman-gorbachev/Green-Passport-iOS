import Foundation

final class ObserveLatestForumPostDateUseCase {
    private let communityRepository: CommunityRepository

    init(communityRepository: CommunityRepository) {
        self.communityRepository = communityRepository
    }

    func execute() -> AsyncThrowingStream<Date?, Error> {
        return communityRepository.observeLatestForumPostDate()
    }
}
