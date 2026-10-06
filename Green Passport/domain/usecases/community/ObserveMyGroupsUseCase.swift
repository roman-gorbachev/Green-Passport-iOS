final class ObserveMyGroupsUseCase {
    private let communityRepository: CommunityRepository

    init(communityRepository: CommunityRepository) {
        self.communityRepository = communityRepository
    }

    func execute(userId: String) -> AsyncThrowingStream<[CommunityGroup], Error> {
        return communityRepository.observeMyGroups(userId: userId)
    }
}
