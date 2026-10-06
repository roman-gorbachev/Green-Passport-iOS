# Сообщество: действия с сообщениями, список чатов, уведомления по категориям

## Контекст

Нужно расширить «Сообщество» на iOS и Android:
- действия с сообщением: ответ, копирование, пересылка, правка и удаление своего;
- форум и группы можно закрепить, убрать в архив и замьютить;
- единый переключатель уведомлений разделить на категории: события, задания, сообщения.

Что есть сейчас (обе платформы одинаково):
- Хаб состоит из двух статичных строк, «Форум» и «Группы».
- У сообщений нет действий. На форуме есть только жалоба на чужой пост.
- Правила Firestore запрещают клиенту `update` и `delete` постов и сообщений.
- **Уведомлений о сообщениях нет вообще.** Все уведомления локальные: награды, напоминания о событиях, купонах и серии. Push не отправляется. На Android FCM подключён, но токен не регистрируется, и `FirebaseMessagingService` нет. На iOS FCM нет, а APNs требует платный Apple Developer Program.

Решения, принятые вами:
1. **Push через FCM.** На Android работает сразу. На iOS готовим данные, настройки и UI, а приём push включим после покупки Apple Developer Program.
2. **Удалённое сообщение** превращается в плашку «Сообщение удалено».
3. **Хаб становится списком чатов:** форум и мои группы. Любой чат можно закрепить, архивировать и замьютить.
4. **Переслать можно в любой мой чат:** форум или группу, где я участник. Пометка «Переслано от <автор>».

Работа затрагивает три репозитория:
- `Green-Passport-iOS`;
- `greenpassport-android`, где лежат приложение, `firestore.rules` и `functions/`;
- `greenpassport-admin` — небольшая правка, чтобы админка понимала удалённые и изменённые посты.

Деплой правил и функций затрагивает общий прод-бэкенд. Делаю его отдельным шагом и только после вашего «да» в чате.

Первым действием этот план сохраняется в `claude/community-messaging-plan.ru.md` обоих приложений.

---

## Этап 0. Спека (обе копии `claude/ux-spec.ru.md`)

UX-изменения сначала идут в спеку. Переписываю 6.14 и 6.19.

**6.14 Сообщество:**
- **Хаб — список чатов.** Сверху закреплённые, ниже остальные по времени последнего сообщения. Строки: «Форум» (плитка `SectionCommunity`) и группы, где я участник (плитка `SectionCalendar`). Строка показывает название и время последнего сообщения, справа значки 📌 (закреплён) и 🔕 (замьючен).
  - Действия над строкой (iOS — свайп и контекстное меню, Android — долгое нажатие): `pin_chat` / `unpin_chat`, `mute_chat` / `unmute_chat`, `archive_chat` / `unarchive_chat`.
  - Архивные чаты прячутся в строку `archived_chats` внизу списка, которая открывает их список с теми же действиями.
  - Строка `community_groups_title` ведёт в каталог всех групп и к созданию группы, как сейчас.
  - Настройки чата личные (видны только мне) и синхронизируются между устройствами.
- **Действия с сообщением** (форум и группа; iOS — контекстное меню по долгому нажатию, Android — меню по долгому нажатию):
  - `reply` — над полем ввода плашка «ответ <имя>: <начало текста>» с крестиком. В отправленном сообщении сверху цитата: имя Forest и одна строка текста. Нажатие на цитату прокручивает к оригиналу, если он загружен.
  - `copy` — текст в буфер обмена, тост или хаптик `copied`.
  - `forward` — шторка «Переслать в…» со списком моих чатов (форум и мои группы, без архивных фильтров). Сообщение уходит копией с пометкой `forwarded_from_format` («Переслано от %1$@»).
  - `edit` (только своё, не удалённое) — поле ввода с текстом и плашкой `editing_message`. После сохранения у сообщения пометка `edited` рядом со временем. Работают фильтр мата и `message_not_sent_msg`.
  - `delete` (только своё) — подтверждение `delete_message_confirm_msg`. Сообщение заменяется плашкой `message_deleted` курсивом серым, без действий кроме ответа. Цитаты на него показывают `message_deleted`.
  - `report` — как раньше, только на чужих постах форума.
- **Меню чата** (форум — в тулбаре, группа — в существующем `more`): `mute_chat` / `unmute_chat`.
- **Форум по умолчанию замьючен.** Иначе каждый пост слал бы push всем пользователям. Группы по умолчанию не замьючены.

**6.19 Уведомления:**
- В профиле вместо одного переключателя секция `notifications_settings` с тремя переключателями:
  - `notifications_events` — напоминания о событиях;
  - `notifications_tasks` — награды за задания, советы, игры и события, напоминание о серии и о сроке купона;
  - `notifications_messages` — новые сообщения в чатах.
- Разрешение системы запрашивается при первом включении любого из них. Логика отказа та же, что сейчас.
- Сообщения — это push. Не приходят: свои сообщения, сообщения из замьюченных чатов, удаления и правки. В журнал уведомлений push о сообщениях не пишутся. Нажатие на push открывает чат.
- iOS: push о сообщениях пока не приходят (нужен Apple Developer Program). Переключатель и мьют уже сохраняются.

**Раздел 7 «Сознательные различия платформ»:** до появления APNs iOS не получает push о сообщениях.

---

## Этап 1. Данные и бэкенд (`greenpassport-android`: `firestore.rules`, `functions/`)

### 1.1 Новые поля сообщений

Поля одинаковые у постов `posts/{id}` и сообщений `chats/{groupId}/messages/{id}`. Почему денормализуем цитату и пересылку: оригинал может быть вне загруженных 200 сообщений, а в другом чате его вообще не прочитать (чат только для участников).

| Поле | Тип | Когда |
|---|---|---|
| `replyTo` | `{messageId: string, senderName: string\|null, text: string}` (text ≤ 200) | ответ |
| `forwardedFrom` | `{senderName: string\|null}` | пересылка |
| `editedAtEpochMillis` | int | после правки |
| `deleted` | bool | после удаления (`text` = `""`) |

### 1.2 Личные настройки и устройства — новые закрытые коллекции

Почему не подколлекции `users/{uid}/…`: документ `users` и его подколлекции читает любой вошедший пользователь (общий catch-all). Токены FCM и мьюты должны быть видны только владельцу.

- `chatSettings/{uid}_{chatId}` — `{userId, chatId, pinned, archived, muted, updatedAtEpochMillis}`. Для форума `chatId = "forum"`, для группы — id группы.
- `userDevices/{token}` — `{userId, platform: "ANDROID"|"IOS", updatedAtEpochMillis}`.
- `users/{uid}.messageNotificationsEnabled` (bool, нет = true) — нужен функции на сервере. События и задания остаются локальными настройками.
- `groups/{id}.lastMessageAtEpochMillis` пишет только функция, нужен для сортировки хаба. Текст последнего сообщения в документ группы **не** кладу: группы читают все, а чат только участники.

### 1.3 `firestore.rules`

```
function isCleanOptionalMessageText(text) {
  return text is string && text.size() <= 2000 && !hasBannedWords(text);
}

function isAuthorEdit(authorField) {
  return resource.data[authorField] == request.auth.uid &&
    resource.data.get('deleted', false) == false &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['text', 'editedAtEpochMillis']) &&
    isCleanText(request.resource.data.text, 2000) &&
    request.resource.data.editedAtEpochMillis is int;
}

function isAuthorDelete(authorField) {
  return resource.data[authorField] == request.auth.uid &&
    request.resource.data.diff(resource.data).affectedKeys().hasOnly(['text', 'deleted', 'replyTo', 'forwardedFrom']) &&
    request.resource.data.text == '' &&
    request.resource.data.deleted == true;
}
```
```
match /apps/greenpassport/posts/{postId} {
  allow read: if request.auth != null;
  allow create: if request.auth != null && request.resource.data.authorId == request.auth.uid &&
    isCleanText(request.resource.data.text, 2000) &&
    isCleanOptionalText(request.resource.data, 'authorName', 61) &&
    !request.resource.data.keys().hasAny(['hidden', 'hiddenReason', 'reportCount', 'deleted', 'editedAtEpochMillis']);
  allow update: if request.auth != null && (isAuthorEdit('authorId') || isAuthorDelete('authorId'));
  allow delete: if false;
}

match /apps/greenpassport/chats/{groupId}/messages/{messageId} {
  allow read: if request.auth != null && isGroupMember(database, groupId);
  allow create: if ...как сейчас... &&
    !request.resource.data.keys().hasAny(['deleted', 'editedAtEpochMillis']);
  allow update: if request.auth != null && isGroupMember(database, groupId) &&
    (isAuthorEdit('senderId') || isAuthorDelete('senderId'));
  allow delete: if false;
}

match /apps/greenpassport/chatSettings/{settingsId} {
  allow read, delete: if request.auth != null && resource.data.userId == request.auth.uid;
  allow create, update: if request.auth != null &&
    settingsId == request.auth.uid + '_' + request.resource.data.chatId &&
    request.resource.data.userId == request.auth.uid &&
    request.resource.data.pinned is bool && request.resource.data.archived is bool &&
    request.resource.data.muted is bool;
}

match /apps/greenpassport/userDevices/{token} {
  allow read, delete: if request.auth != null && resource.data.userId == request.auth.uid;
  allow create, update: if request.auth != null && request.resource.data.userId == request.auth.uid &&
    request.resource.data.platform in ['ANDROID', 'IOS'];
}
```
- `isClosedCollection` пополняется `chatSettings` и `userDevices`.
- `groups` update: `lastMessageAtEpochMillis` пишет только Admin SDK, правило не меняется.
- В `posts` create добавлен запрет серверных полей. Это заодно закрывает старую дыру: клиент мог сам выставить `hidden` или `reportCount`.

### 1.4 Функции

`functions/src/community/` (новая папка), экспорт в `index.ts`:

```ts
export const screenForumPostEdit = onDocumentUpdated(
  { region: FIRESTORE_TRIGGER_REGION, document: `${APP_ROOT}/posts/{postId}` },
  async (event) => {
    const before = event.data?.before;
    const after = event.data?.after;
    if (!before || !after || after.get('deleted') === true) return;
    const text = String(after.get('text') ?? '');
    if (text !== before.get('text') && !isTextAllowed(text)) {
      await after.ref.update({ hidden: true, hiddenReason: 'banned_words' });
    }
  },
);
```

`scrubDeletedReplies` — удалённый текст не должен жить в чужих цитатах:
```ts
async function scrubReplies(collection: CollectionReference, messageId: string) {
  const replies = await collection.where('replyTo.messageId', '==', messageId).get();
  const batch = db.batch();
  replies.docs.forEach((reply) => batch.update(reply.ref, { 'replyTo.text': '' }));
  await batch.commit();
}
```
Вызывается из `onDocumentUpdated` на `posts/{id}` и `chats/{groupId}/messages/{id}`, когда `deleted` стал `true`. Пустой `replyTo.text` клиент показывает как `message_deleted`.

`notifyGroupMessage` и `notifyForumPost` (`onDocumentCreated`):
```ts
export const notifyGroupMessage = onDocumentCreated(
  { region: FIRESTORE_TRIGGER_REGION, document: `${APP_ROOT}/chats/{groupId}/messages/{messageId}` },
  async (event) => {
    const message = event.data;
    if (!message) return;
    const groupId = event.params.groupId;
    const group = await db.doc(paths.group(groupId)).get();
    await group.ref.update({ lastMessageAtEpochMillis: message.get('createdAtEpochMillis') });
    const senderId = message.get('senderId') as string;
    const memberIds = (group.get('memberIds') as string[]).filter((id) => id !== senderId);
    const recipients = await filterRecipients(memberIds, groupId, { mutedByDefault: false });
    await sendChatPush(recipients, {
      chatId: groupId,
      title: String(group.get('name') ?? ''),
      body: messagePreview(message),
    });
  },
);
```
- `filterRecipients` отбрасывает тех, у кого `users/{uid}.messageNotificationsEnabled == false` или `chatSettings/{uid}_{chatId}.muted == true`. Для форума (`mutedByDefault: true`) берёт только явно размьюченных: `chatSettings where chatId == 'forum' && muted == false`.
- `sendChatPush` читает `userDevices where userId in [...]` (пачками по 30) и шлёт `messaging.sendEach`:
  - `ANDROID` — data-only с `priority: 'high'` (`type: 'chat'`, `chatId`, `title`, `body`), чтобы приложение само выбирало канал и не показывало push открытого чата;
  - `IOS` — `notification` + `apns`, на будущее.
  - Токены с ошибкой `registration-token-not-registered` удаляются.
- `messagePreview` — `«Имя: текст»` до 100 символов; для пересланного — «Имя: ↪ текст».
- `paths` в `db.ts` дополняется: `group(id)`, `chatSettings(uid, chatId)`, `userDevices`.

### 1.5 Деплой (после вашего подтверждения)

```bash
cd ~/Personal/greenpassport-android
npm --prefix functions run build
firebase deploy --only firestore:rules,functions:screenForumPostEdit,functions:scrubDeletedPostReplies,functions:scrubDeletedMessageReplies,functions:notifyGroupMessage,functions:notifyForumPost
```
Индексы: `chatSettings (chatId, muted)` и `userDevices (userId)` — в `firestore.indexes.json` и `firebase deploy --only firestore:indexes`.

---

## Этап 2. Действия с сообщением (iOS и Android)

### 2.1 Модели

iOS `domain/models/ForumPost.swift`, `GroupMessage.swift` получают:
```swift
let replyTo: MessageQuote?
let forwardedFrom: String?
let isEdited: Bool
let isDeleted: Bool
```
Новый тип `domain/models/MessageQuote.swift`:
```swift
nonisolated struct MessageQuote: Hashable, Sendable {
    let messageId: String
    let senderName: String?
    let text: String
}
```
Новый тип `domain/models/ChatId.swift`, общий идентификатор для пересылки, настроек и хаба:
```swift
nonisolated enum ChatId: Hashable, Sendable {
    case forum
    case group(id: String)

    var rawValue: String {
        switch self {
        case .forum:
            return "forum"
        case .group(let id):
            return id
        }
    }
}
```
Android — те же поля в `core/model/Community.kt` / `GroupMessage.kt`, `MessageQuote` и `ChatId` отдельными файлами в `core/model/community/`.

### 2.2 Репозиторий и use cases

`CommunityRepository` (обе платформы):
```swift
func postToForum(authorId: String, authorName: String?, authorAvatar: AvatarStyle?, text: String, replyTo: MessageQuote?, forwardedFrom: String?) async throws
func sendMessage(groupId: String, senderId: String, senderName: String?, senderAvatar: AvatarStyle?, text: String, replyTo: MessageQuote?, forwardedFrom: String?) async throws
func editMessage(in chat: ChatId, messageId: String, text: String) async throws
func deleteMessage(in chat: ChatId, messageId: String) async throws
```
Firestore-реализация правки и удаления:
```swift
func editMessage(in chat: ChatId, messageId: String, text: String) async throws {
    try await messageReference(in: chat, messageId: messageId).updateData([
        Self.fieldText: text,
        Self.fieldEditedAt: EpochMillis.now,
    ])
}

func deleteMessage(in chat: ChatId, messageId: String) async throws {
    try await messageReference(in: chat, messageId: messageId).updateData([
        Self.fieldText: "",
        Self.fieldDeleted: true,
        Self.fieldReplyTo: FieldValue.delete(),
        Self.fieldForwardedFrom: FieldValue.delete(),
    ])
}
```
Новые use cases в `domain/usecases/community/` (Android — `feature/community/domain/`), по одному на файл:
- `EditMessageUseCase` — `TextModerator` → `ContentRejectedError`, затем `editMessage`.
- `DeleteMessageUseCase`.
- `ForwardMessageUseCase` — по `ChatId` вызывает `PostToForumUseCase` или `SendGroupMessageUseCase` с `forwardedFrom`.
- `PostToForumUseCase` и `SendGroupMessageUseCase` получают параметр `replyTo: MessageQuote?`.

Цитата обрезается до 200 символов в одном месте — `MessageQuote.make(messageId:senderName:text:)`, `private static let maximumTextLength = 200`.

### 2.3 Состояние экрана

В `ForumUiState` и `GroupDetailUiState` добавляется общий режим поля ввода:
```swift
nonisolated enum ComposerMode: Hashable {
    case new
    case reply(MessageQuote)
    case edit(messageId: String)
}
```
Во ViewModel:
- `startReply(_:)`, `startEdit(_:)` (подставляет текст в `draft`), `cancelComposerMode()`;
- `send()` смотрит на `composerMode`;
- `delete(_:)`, `forward(_:to:)`;
- `copy(_:)` — `UIPasteboard.general.string` (Android — `ClipboardManager`) и `copiedCount` для хаптика.

### 2.4 UI

**iOS:**
- `MessageComposer` получает необязательную плашку над полем: `composerBanner: ComposerBanner?` (иконка, заголовок, текст, крестик).
- Пузырь группы и строка форума получают `.contextMenu`:
```swift
.contextMenu {
    if !message.isDeleted {
        Button { onAction(.reply(message)) } label: { Label(String(localized: .reply), systemImage: "arrowshape.turn.up.left") }
        Button { onAction(.copy(message)) } label: { Label(String(localized: .copy), systemImage: "doc.on.doc") }
        Button { onAction(.forward(message)) } label: { Label(String(localized: .forward), systemImage: "arrowshape.turn.up.right") }
        if message.senderId == currentUserId {
            Button { onAction(.edit(message)) } label: { Label(String(localized: .edit), systemImage: "pencil") }
            Button(role: .destructive) { onAction(.delete(message)) } label: { Label(String(localized: .delete), systemImage: "trash") }
        }
    }
}
```
- Новые компоненты в `presentation/components/` — `MessageQuoteView` (цитата и «Переслано от»), `DeletedMessageText`.
- Экраны принимают `GroupMessageAction` / `ForumPostAction` (enum `userAction`, как требует CLAUDE.md).
- Пересылка — шторка `ForwardTargetSheet` (новый route и screen в `presentation/community/ui/`) со списком из `ObserveMyChatsUseCase` (этап 3). Выбор чата отправляет сообщение и закрывает шторку, хаптик `.success`.
- Удаление — `confirmationDialog` на пузыре (как «Обменять» в магазине).
- Нажатие на цитату — `ScrollViewReader.scrollTo(messageId)`.

**Android:** `combinedClickable(onLongClick = …)` на `MessageRow` и `ForumPostRow` открывает `DropdownMenu` с теми же пунктами. `MessageComposer` (core) получает `banner`. Пересылка — `ModalBottomSheet` (`GpSheetScaffold`). Удаление — `AlertDialog`.

---

## Этап 3. Хаб как список чатов (iOS и Android)

### 3.1 Данные

- `ChatSettings` (`chatId`, `isPinned`, `isArchived`, `isMuted`).
- Репозиторий `ChatSettingsRepository` (`FirestoreChatSettingsRepository`):
```swift
protocol ChatSettingsRepository {
    func observeSettings(userId: String) -> AsyncThrowingStream<[ChatId: ChatSettings], Error>
    func save(_ settings: ChatSettings, userId: String) async throws
}
```
- Нет документа — значит дефолт: форум `muted = true`, группа `muted = false`, не закреплён и не в архиве. Дефолт в одном месте, `ChatSettings.defaults(for:)`.
- `CommunityRepository.observeMyGroups(userId:)` — `whereField("memberIds", arrayContains: userId)`. `CommunityGroup` получает `lastMessageAt: Date?`.
- Последний пост форума — `posts` order desc limit 1.

### 3.2 Use cases

- `ObserveMyChatsUseCase` склеивает форум, мои группы и настройки в `[ChatSummary]`:
```swift
nonisolated struct ChatSummary: Identifiable, Hashable {
    let chatId: ChatId
    let title: String
    let lastMessageAt: Date?
    let settings: ChatSettings

    var id: String {
        return chatId.rawValue
    }
}
```
  Сортировка: закреплённые, потом по `lastMessageAt` убыванию.
- `UpdateChatSettingsUseCase` (pin, archive, mute).

### 3.3 UI

**iOS:**
- `CommunityHubScreen` получает Route и ViewModel (`CommunityHubRoute`, `CommunityHubViewModel`, `buildCommunityHubViewModel()`), потому что хаб становится живым.
- `List`:
  - секция «Чаты» — `ChatRow` (плитка, название, время, значки);
  - строка `archived_chats` (если есть архивные) → `AppDestination.archivedChats`;
  - строка `community_groups_title` → каталог групп, как сейчас.
- `.swipeActions(edge: .leading)` — закрепить. `.swipeActions(edge: .trailing)` — архив и мьют. `.contextMenu` — те же три.
- `ArchivedChatsRoute` и `ArchivedChatsScreen` — тот же список только архивных.
- В меню группы (`more`) и в тулбаре форума — `mute_chat` / `unmute_chat`.

**Android:** то же на `LazyColumn`. Долгое нажатие открывает `DropdownMenu` с pin, archive и mute. Добавляется `Destination.ArchivedChats`.

---

## Этап 4. Категории уведомлений и push

### 4.1 Настройки (обе платформы)

Локальные ключи (имена общие для UserDefaults и DataStore):
- `notifications_events_enabled` (по умолчанию true);
- `notifications_tasks_enabled` (по умолчанию true).

Сообщения хранятся в `users/{uid}.messageNotificationsEnabled`.

Миграция: если старый `notifications_enabled == false`, оба новых ключа ставятся в false. Старый ключ после переноса удаляется. Код миграции — `MigrateNotificationSettingsUseCase`, вызывается один раз на старте (iOS — в `RootViewModel`, Android — в `MainViewModel`).

Кто какую категорию смотрит:

| Уведомление | Категория |
|---|---|
| `event_reminder_*` | события |
| награды (`RewardNotifier`), `streak_reminder`, `coupon_expiring_*` | задания |
| push о сообщениях | сообщения (сервер) |

iOS: `SettingsRepository` получает `isNotificationCategoryEnabled(_ category: NotificationCategory)` и `setNotificationCategory(_:enabled:)`.
```swift
nonisolated enum NotificationCategory: String, CaseIterable, Sendable {
    case events
    case tasks
    case messages
}
```
- `LocalRewardNotifier` и `LocalNotificationReminderScheduler.deliver` проверяют свою категорию вместо `notifications_enabled`.
- Выключение «событий» снимает все `event_reminder_*`. Выключение «заданий» снимает `streak_reminder` и `coupon_expiring_*`.
- Android — то же в `LocalAppSettingsRepository` и воркерах (`EventReminderWorker`, `CouponReminderWorker`, `StreakReminderWorker`, `AndroidRewardNotifier`).

UI профиля (обе платформы): секция `notifications_settings` с тремя переключателями вместо одного. Текущая логика разрешений (`ProfileViewModel.toggleNotifications`) обобщается на категорию.

### 4.2 Android push

- `NotificationsRepository.registerToken(userId)` пишет `userDevices/{token}` `{userId, platform: "ANDROID", updatedAtEpochMillis}`. Вызывается при каждом входе (из `MainViewModel` по сессии) и в `onNewToken`. При выходе документ токена удаляется.
- Новый `core/messaging/service/ChatMessagingService.kt`:
```kotlin
class ChatMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) { ... registerToken ... }

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        if (data[KEY_TYPE] != TYPE_CHAT) return
        val chatId = data[KEY_CHAT_ID] ?: return
        if (OpenChatTracker.openChatId == chatId) return
        chatNotifier.show(chatId = chatId, title = data[KEY_TITLE].orEmpty(), body = data[KEY_BODY].orEmpty())
    }
}
```
- Регистрируется в манифесте `core` с `com.google.firebase.MESSAGING_EVENT`.
- `OpenChatTracker` — синглтон, который форум и группа выставляют в `DisposableEffect`.
- Канал `greenpassport_messages` (`NotificationChannels.MESSAGES_CHANNEL_ID`, строка `notification_channel_messages`). Уведомление группируется по `chatId`, нажатие — `PendingIntent` в `MainActivity` с extra `chatId` → навигация в `Destination.Forum` или `Destination.CommunityGroup(id)` (переиспользую `NotificationDeepLink`).
- Разрешение `POST_NOTIFICATIONS` запрашивается по текущей логике профиля.

### 4.3 iOS

- Мьют, категории и `messageNotificationsEnabled` работают и сохраняются.
- Регистрация токена и приём push пока не делаются: нет FirebaseMessaging и APNs. В `CLAUDE.md` → Known limitations: «Push о сообщениях не приходят на iOS до подключения APNs (нужен Apple Developer Program). Сервер уже шлёт iOS-payload на токены с `platform: IOS`, подключить надо FirebaseMessaging, `aps-environment`, `registerForRemoteNotifications` и запись `userDevices`».

---

## Этап 5. Админка (`greenpassport-admin`)

`src/domain/moderation.ts`: `Post` получает `deleted: boolean` и `editedAtEpochMillis: number | null`. `ReportsPage` показывает «удалено автором» вместо пустого текста и «изменено» у правленых постов. Иначе жалоба на пост, удалённый автором, выглядела бы как пустая карточка. `npm test` и `npm run build` админки.

---

## Строки (iOS `Localizable.xcstrings` и Android `strings.xml`, ru / be / en)

`reply`, `copy`, `copied`, `forward`, `edit`, `delete`, `edited`, `message_deleted`, `delete_message_confirm_msg`, `editing_message`, `replying_to_format`, `forwarded_from_format`, `forward_to`, `pin_chat`, `unpin_chat`, `mute_chat`, `unmute_chat`, `archive_chat`, `unarchive_chat`, `archived_chats`, `chats`, `notifications_settings`, `notifications_events`, `notifications_tasks`, `notifications_messages`, `notification_channel_messages`.

Перед добавлением проверяю, нет ли уже такого ключа (`copy`, `delete`, `edit` могут быть).

## Документация

- `CLAUDE.md` обоих приложений: поля сообщений, `chatSettings`, `userDevices`, push (Android), Known limitations (iOS).
- Android `CLAUDE.md`: новые функции.

## Порядок работы и коммиты

1. Спека (обе копии) и планы в `claude/`.
2. Бэкенд: правила, функции, индексы. Сборка функций, **деплой после вашего подтверждения**. Коммит в Android.
3. Действия с сообщением: iOS → коммит, Android → коммит.
4. Хаб чатов, архив и мьют: iOS → коммит, Android → коммит.
5. Категории уведомлений и Android push: iOS → коммит, Android → коммит.
6. Админка → коммит.

## Проверка

Сборки:
```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
cd ~/Personal/greenpassport-android && ./gradlew assembleDebug detektAll && ./gradlew test
npm --prefix functions run build && npm --prefix functions run lint
cd ~/Personal/greenpassport-admin && npm test && npm run build
```
Правила — эмулятор Firestore (`firebase emulators:exec --only firestore`), если в репо есть тесты правил. Если нет, ручная проверка:
- чужое сообщение нельзя изменить или удалить;
- в своём нельзя поменять `senderId` или `hidden`;
- правка с матом отклоняется;
- `chatSettings` и `userDevices` чужого пользователя не читаются.

Ручные сценарии (два аккаунта, Android-устройство с push):
1. Ответ: цитата видна у обоих, нажатие прокручивает к оригиналу.
2. Копирование: текст в буфере.
3. Пересылка из группы на форум и в другую группу: «Переслано от …».
4. Правка: «изменено» у обоих. Мат при правке → `text_contains_banned_words`. На форуме пост с матом после правки скрывается сервером.
5. Удаление: плашка «Сообщение удалено» у обоих, цитаты на него показывают «Сообщение удалено».
6. Хаб: форум и мои группы. Закрепление поднимает чат наверх, архив прячет в «Архив», возврат из архива работает. Настройки видны на втором устройстве того же аккаунта.
7. Push (Android): сообщение в группе приходит второму участнику. В замьюченной группе — нет. Форум без размьюта — нет, после размьюта — да. При выключенной категории «Сообщения» — нет. В открытом чате — нет. Нажатие открывает чат.
8. Категории: при выключенных «Заданиях» нет уведомления о награде и напоминания серии. При выключенных «Событиях» не приходит напоминание о событии. Старый выключенный переключатель после обновления даёт обе категории выключенными.
