# Сообщество: правки после первой проверки (iOS и Android)

## Контекст

Замечания пользователя после первой версии списка чатов:

| # | Что | iOS | Android |
|---|---|---|---|
| 1 | Форум отдельно от списка чатов | ✓ | ✓ |
| 2 | Убрать строку «Группы»: под форумом сразу мои группы | ✓ | ✓ |
| 3 | Поиск по названию группы и по именам участников | ✓ | ✓ |
| 4 | Архив открывается потягиванием списка вниз, как в Telegram | ✓ | ✓ |
| 5 | После отправки сообщения клавиатура скрывается | ✓ | ✓ |
| 6 | Звук чата не переключается | ✓ | — |
| 7 | На Главной «Сообщество» переносится одной буквой | — | ✓ |
| 8 | Сообщения в чате группы прижаты к верху, а должны к низу | — | ✓ |
| 9 | Освежить вид «Сообщества» по образцу iOS | — | ✓ |

Решения пользователя: под форумом — **мои группы**, чужие группы находятся **поиском** (как в Telegram). Звук проверяли **до деплоя** правил.

Первым действием план копируется в `claude/community-hub-v2-plan.ru.md` обоих приложений.

---

## 0. Спека (обе копии `claude/ux-spec.ru.md`, раздел 6.14)

Хаб переписывается так:
- Сверху поле поиска `search_groups_placeholder` («Поиск групп и участников»).
- Секция «Форум»: одна строка `community_forum_title` с временем последнего поста и значком «без звука». Форум не закрепляется и не архивируется. Долгое нажатие или контекстное меню предлагает только `mute_chat` / `unmute_chat`.
- Секция `my_groups`: группы, где я участник. Сначала закреплённые, потом по последнему сообщению. Действия: закрепить, звук, архив. Пусто — `my_groups_empty_msg` («Найдите группу через поиск или создайте свою»).
- Архив: если в нём есть группы, то потягивание списка вниз от самого верха (дальше порога) показывает над форумом строку `archived_chats` с числом групп. Прокрутка вниз снова её прячет. Строка открывает экран архива.
- Поиск (непустой запрос) заменяет секции результатами: `my_groups`, затем `other_groups`. Группа подходит, если запрос (без учёта регистра) входит в её название или в имя любого участника. Если совпало имя участника, в подзаголовке `member_match_format` («Участник: %1$s»). Ничего не найдено — `groups_not_found`. Нажатие на чужую группу открывает её экран с кнопкой `groups_join_button`.
- В тулбаре кнопка «+» с меню: `create_group` (диалог с полем `groups_draft_label`, фильтр мата) и `join_by_code` (как раньше). Отдельного экрана «Группы» больше нет.
- Общее для форума и чата: после отправки клавиатура скрывается.

Из спеки удаляется описание экрана «Группы» (каталог и создание переехали в хаб).

---

## 1. Данные (обе платформы)

**Хаб получает все группы, а не только мои.** Для поиска нужны и чужие группы. Достаточно уже существующего `observeGroups()`: «мои» отбираются по `memberIds.contains(userId)` на клиенте, и отдельная подписка `observeMyGroups` хабу больше не нужна. Пересылка продолжает использовать `observeMyGroups`.

**Имена участников для поиска.** У группы есть только `memberIds`. Имена подгружаются лениво при первом непустом запросе: собирается объединение `memberIds` всех групп и загружается существующим `FetchGroupMembersUseCase` (пачками по 30, уже реализовано в обоих репозиториях). Результат кешируется во ViewModel и дозагружается только для новых id.

Почему не на сервере: для нынешнего размера сообщества это несколько запросов, без деплоя и без устаревания имён в денормализованном поле. Если групп станет сотни, перенесём `memberNames` в документ группы триггером.

**Форум уходит из `ChatSummary.list`.** Список строится только из групп. Форум отдаётся отдельно: время последнего поста и `ChatSettings` с `chatId = forum`.

iOS `domain/models/ChatSummary+List.swift`:
```swift
extension ChatSummary {
    static func groups(_ groups: [CommunityGroup], settings: [ChatId: ChatSettings]) -> [ChatSummary] {
        return groups.map { group in
            let chatId = ChatId.group(id: group.id)
            return ChatSummary(
                chatId: chatId,
                groupName: group.name,
                lastMessageAt: group.lastMessageAt,
                settings: settings[chatId] ?? .defaults(for: chatId)
            )
        }
        .sorted { lhs, rhs in
            if lhs.settings.isPinned != rhs.settings.isPinned {
                return lhs.settings.isPinned
            }
            return (lhs.lastMessageAt ?? .distantPast) > (rhs.lastMessageAt ?? .distantPast)
        }
    }
}
```

Поиск — чистая функция в домене, `domain/models/GroupSearch.swift` (Android: `core/model/community/GroupSearch.kt`):
```swift
nonisolated enum GroupSearch {
    static func matches(
        _ groups: [CommunityGroup],
        query: String,
        memberNames: [String: String]
    ) -> [GroupSearchResult] {
        let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !needle.isEmpty else {
            return []
        }
        return groups.compactMap { group in
            if group.name.lowercased().contains(needle) {
                return GroupSearchResult(group: group, matchedMemberName: nil)
            }
            let member = group.memberIds.compactMap { memberNames[$0] }.first { $0.lowercased().contains(needle) }
            return member.map { GroupSearchResult(group: group, matchedMemberName: $0) }
        }
    }
}
```
`GroupSearchResult` — отдельный файл: `group` и `matchedMemberName: String?`.

**Создание группы из хаба.** Используются существующие `CreateGroupUseCase`, `JoinGroupByCodeUseCase` и `GroupNotFoundError` / `GroupNotFoundException`. Логика переезжает из `GroupsViewModel` в ViewModel хаба. `GroupsRoute`/`GroupsScreen`/`GroupsViewModel`/`GroupsUiState` (iOS) и `GroupsScreen`/`GroupsViewModel`/`GroupsUiState`/`JoinByCodeButton` (Android) удаляются вместе с `AppDestination.groups` / `Destination.CommunityGroups`.

---

## 2. iOS

### 2.1 Хаб — `CommunityHubScreen` / `ChatListViewModel`
`ChatListUiState`:
```swift
struct ChatListUiState {
    var forum: ChatSummary?
    var groups: [ChatSummary] = []
    var archivedCount = 0
    var searchResults: [GroupSearchResult] = []
    var currentUserId: String?
    var isLoading = true
    var hasError = false
    var isCreatingGroup = false
    var isGroupNameRejected = false
    var isInviteCodeNotFound = false
}
```
ViewModel подписывается на `observeGroups`, последний пост форума и `chatSettings`. Добавляются методы `search(_:)` (ленивая загрузка имён), `createGroup(name:)` и `joinByCode(_:) async -> String?`.

Экран:
```swift
List {
    if isArchiveRevealed && uiState.archivedCount > 0 {
        archiveRow
    }
    if query.isEmpty {
        Section { forumRow }
        Section {
            ForEach(uiState.groups) { chat in
                ChatListRow(chat: chat, onOpen: { onOpenChat(chat.chatId) }, onAction: { onChatAction($0, chat) })
            }
        } header: {
            Text(.myGroups)
        }
    } else {
        searchSections
    }
}
.searchable(text: $query, prompt: Text(.searchGroupsPlaceholder))
.onScrollGeometryChange(for: CGFloat.self) { geometry in
    return geometry.contentOffset.y + geometry.contentInsets.top
} action: { _, offset in
    if offset < -Self.archiveRevealDistance {
        withAnimation(.snappy) { isArchiveRevealed = true }
    } else if offset > Self.archiveHideDistance {
        withAnimation(.snappy) { isArchiveRevealed = false }
    }
}
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        Menu { createGroupButton; joinByCodeButton } label: { Label(String(localized: .createGroup), systemImage: "plus") }
    }
}
```
`archiveRevealDistance = 60` и `archiveHideDistance = 80` — `private static let`. `onScrollGeometryChange` есть с iOS 18, это наш минимум. У строки форума контекстное меню только со звуком. `ChatListRow` остаётся для групп.

Создание группы — `.alert` с `TextField` (как «Вступить по коду»). Вступление по коду — тот же алерт, что был в `GroupsScreen`, после успеха `router.push(.group(id:))`.

### 2.2 Звук чата
С деплоем правил запись разрешена, поэтому, скорее всего, звук уже работает. Добавляю откат при ошибке записи, чтобы переключатель не «залипал» в неверном состоянии:
```swift
private func save(_ updated: ChatSettings) {
    guard let userId else {
        return
    }
    let previous = settings
    settings = updated
    Task {
        do {
            try await updateChatSettings.execute(updated, userId: userId)
        } catch {
            settings = previous
        }
    }
}
```
То же в `ChatListViewModel.handle`: при ошибке настройка чата возвращается к прежней.

### 2.3 Клавиатура после отправки
`MessageComposer`: кнопка отправки сначала прячет клавиатуру:
```swift
Button {
    Keyboard.dismiss()
    onSend()
} label: { … }
```

---

## 3. Android

### 3.1 Хаб — `CommunityHubScreen` / `ChatListViewModel`
Та же структура, что на iOS: `ChatListUiState` с `forum`, `groups`, `archivedCount`, `searchResults` и флагами создания и вступления. `LazyColumn`:
- поле поиска сверху (`OutlinedTextField` в стиле `MessageComposer`: скруглённый `surface`, иконка `Search`);
- строка архива (если раскрыта);
- `ListSection` «Форум»;
- `ListSection(header = my_groups)`;
- в режиме поиска — секции результатов.

Раскрытие архива потягиванием — через `nestedScroll`. Поднятый наверх остаток жеста вниз означает, что список уже упёрся в верх:
```kotlin
val archiveConnection = remember {
    object : NestedScrollConnection {
        private var pulled = 0f

        override fun onPostScroll(consumed: Offset, available: Offset, source: NestedScrollSource): Offset {
            if (available.y > 0f) {
                pulled += available.y
                if (pulled > revealDistancePx) isArchiveRevealed = true
            } else if (consumed.y < 0f) {
                pulled = 0f
                if (listState.firstVisibleItemIndex > 0) isArchiveRevealed = false
            }
            return Offset.Zero
        }
    }
}
```
`revealDistancePx` — из `Dimens.ArchiveRevealDistance = 60.dp`.

Действия «+» — в `FeatureScaffold(actions = …)` в `AppNavHost`: `IconButton(Add)` + `DropdownMenu` (создать группу, вступить по коду), диалоги `AlertDialog` с полем.

### 3.2 Вид «Сообщества» по образцу iOS
- Строка группы: плитка `SymbolTile`, название, время последнего сообщения, значки закрепления и звука справа — уже в `ChatRow`. Ей добавляются подзаголовок с числом участников для чужих групп в поиске и `member_match_format`.
- Секции с заголовками, как в iOS `insetGrouped` (`ListSection(header = …)`), отступы `Dimens.ScreenHorizontalPadding` / `SpacingMedium`.
- Форум — отдельная секция с одной строкой.
- Пустое состояние «Моих групп» — текст `my_groups_empty_msg` внутри секции.

Визуальную проверку делаете вы. Если «освежить» значит что-то большее, чем привести к виду iOS, пришлите, что именно смущает: скриншот с пометками.

### 3.3 Сообщения прижаты к низу
`GroupDetailScreen.GroupChat`, `LazyColumn`:
```kotlin
verticalArrangement = Arrangement.spacedBy(Dimens.SpacingSmall, Alignment.Bottom),
```
Короткая переписка встаёт к полю ввода. Прокрутка к последнему сообщению остаётся.

### 3.4 Клавиатура после отправки
`core/designsystem/component/MessageComposer.kt`:
```kotlin
val keyboardController = LocalSoftwareKeyboardController.current
val focusManager = LocalFocusManager.current
FilledIconButton(
    onClick = {
        if (!isSending) {
            keyboardController?.hide()
            focusManager.clearFocus()
            onSend()
        }
    },
    …
)
```

### 3.5 «Сообщество» на Главной
Подпись `QuickActionButton` получает перенос по слогам, как на iOS («Сообще-ство»), вместо одинокой буквы:
```kotlin
style = MaterialTheme.typography.labelSmall.copy(
    hyphens = Hyphens.Auto,
    lineBreak = LineBreak.Paragraph,
),
```

---

## 4. Строки (ru / be / en, обе платформы)

`search_groups_placeholder` — «Поиск групп и участников» / «Пошук груп і ўдзельнікаў» / «Search groups and members»
`my_groups` — «Мои группы» / «Мае групы» / «My groups»
`other_groups` — «Другие группы» / «Іншыя групы» / «Other groups»
`my_groups_empty_msg` — «Найдите группу через поиск или создайте свою» / «Знайдзіце групу праз пошук або стварыце сваю» / «Find a group with search or create your own»
`groups_not_found` — «Ничего не найдено» / «Нічога не знойдзена» / «Nothing found»
`member_match_format` — «Участник: %1$@» (Android `%1$s`) / «Удзельнік: …» / «Member: …»
`create_group` — «Создать группу» / «Стварыць групу» / «Create group»

`chats` больше не нужна. Строки удалённого экрана групп, которые используются в диалогах хаба, остаются.

---

## 5. Коммиты

1. iOS: спека, план, хаб, поиск, архив потягиванием, клавиатура, откат звука, удаление экрана групп.
2. Android: спека, план, то же плюс прижатый к низу чат, перенос на Главной и вид хаба.

Деплой не нужен: правила и функции не меняются.

## Проверка

```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
cd ~/Personal/greenpassport-android && ./gradlew assembleDebug detektAll :feature:community:lintDebug :core:lintDebug
```
Ручные сценарии (обе платформы):
1. Хаб: сверху поиск, ниже «Форум» одной строкой, ниже «Мои группы». Строки «Группы» нет.
2. Форум: долгое нажатие даёт только звук. Закрепить или архивировать его нельзя.
3. Поиск по части названия чужой группы находит её в «Других группах», нажатие открывает экран с «Вступить». Поиск по имени участника находит его группы с подписью «Участник: …».
4. Архив: группа убрана в архив, потягивание списка вниз от верха показывает «Архив чатов», прокрутка вниз прячет строку. Без архивных групп ничего не появляется.
5. «+» → «Создать группу»: группа появляется в «Моих группах», мат отклоняется. «Вступить по коду» открывает группу.
6. Отправка в форуме и группе прячет клавиатуру.
7. iOS: звук форума и группы переключается и сохраняется после перезапуска.
8. Android: короткая переписка в группе прижата к полю ввода. На Главной «Сообще-ство» с переносом.
