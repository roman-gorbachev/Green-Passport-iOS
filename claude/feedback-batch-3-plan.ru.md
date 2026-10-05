# План: правки Макса после субботы + аудит выходных (iOS + Android)

Первым действием после одобрения план копируется в `claude/feedback-batch-3-plan.ru.md` (и в Android-репо `claude/`). UX-изменения сначала вносятся в `claude/ux-spec.ru.md` (обе копии), потом в код.

## Контекст

В субботу реализовали `feedback-batch-2`, потом Макс правил карту, шторку задания, стрик и иконку темы (`7111112`, `0abff68`, `cd84e04`). Остался список от Макса: избранное в шторке задания и совета, удаление из «Избранного», иконка очков, тумблер уведомлений после отказа, отметка «записан» в календаре, высота шторки события, фото у задания. Плюс аудит выходных коммитов на соответствие `CLAUDE.md` и скрытые баги.

Решения, принятые до плана:
- **Иконка очков:** по спеке очки — `bolt.fill`, уровень — `star.fill`. Расходится карточка прогресса (у баланса звезда) — меняем её на молнию, `PointsBadge` не трогаем.
- **Платформы:** iOS и Android в этой сессии.
- **Сердце в шторке задания** — справа от названия, а не второй кнопкой внизу: внизу одна главная кнопка подтверждения, и у выполненного задания её нет вовсе, а сердце нужно всегда.
- **Уведомления после отказа:** iOS не даёт показать системный запрос второй раз (статус `.denied` — окончательный). Делаем как на Android (`ProfileScreen.kt:133`): тап по тумблеру при отказе открывает настройки уведомлений приложения, при возврате в приложение тумблер перечитывает статус.

---

## Часть A. Список Макса

### A1. Сердце избранного в шторке задания

Сейчас добавить в избранное можно только из списка «Все». В шторке, которая открывается с Главной, кнопки нет.

`TaskDetailViewModel` получает `ObserveFavoriteTaskIdsUseCase` + `ToggleTaskFavoriteUseCase` (уже есть, ими пользуется `TasksListViewModel`), `TaskDetailUiState.isFavorite`:

```swift
func toggleFavorite() {
    guard let userId else {
        return
    }
    let isFavorite = !uiState.isFavorite
    uiState.isFavorite = isFavorite
    Task {
        do {
            try await toggleTaskFavorite.execute(userId: userId, taskId: taskId, isFavorite: isFavorite)
        } catch {
            uiState.isFavorite = !isFavorite
        }
    }
}

private func observeFavorite(userId: String) async {
    do {
        for try await favoriteIds in observeFavoriteTaskIds.execute(userId: userId) {
            uiState.isFavorite = favoriteIds.contains(taskId)
        }
    } catch {
        return
    }
}
```

`observeFavorite` добавляется в `withTaskGroup` в `observeData(userId:)`. В шапке `TaskDetailScreen` — новый общий компонент (переиспользуется в A2, A3, A4):

```swift
struct FavoriteButton: View {
    let isFavorite: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isFavorite ? "heart.fill" : "heart")
                .foregroundStyle(isFavorite ? Palette.forest : Palette.secondaryText)
                .contentTransition(.symbolEffect(.replace))
        }
        .buttonStyle(.borderless)
        .accessibilityLabel(Text(.profileFavorites))
        .sensoryFeedback(.impact, trigger: isFavorite)
    }
}
```

```swift
HStack(alignment: .top, spacing: Spacing.medium) {
    MascotImage(size: Self.mascotSize)
    VStack(alignment: .leading, spacing: Spacing.xSmall) { ... }
        .frame(maxWidth: .infinity, alignment: .leading)
    FavoriteButton(isFavorite: uiState.isFavorite, action: onToggleFavorite)
        .font(.title2)
}
```

Строки с сердцем в `TasksListScreen` и `EcoTipsListScreen` переводятся на `FavoriteButton` (сейчас там две копии одного кода).

**Android:** то же в `TaskDetailViewModel.kt` / `TaskDetailSheet.kt` (`IconButton` с `Favorite`/`FavoriteBorder` справа от названия).

### A2. Удаление из «Избранного» — сердце и свайп

Сейчас в «Избранном» строки только открывают элемент; убрать можно лишь из исходного экрана. Делаем как в списке «Все»: сердце в строке + свайп (свайп — только iOS, на Android сердце, как в `TasksListScreen.kt`).

`FavoritesViewModel` получает `ToggleTaskFavoriteUseCase` и `ToggleTipBookmarkUseCase`, `FavoritesScreen` — один `onAction: (FavoritesUserAction) -> Void` вместо четырёх замыканий:

```swift
enum FavoritesUserAction {
    case taskSelected(EcoTask)
    case tipSelected(EcoTip)
    case placeSelected(MapPoint)
    case taskRemoved(EcoTask)
    case tipRemoved(EcoTip)
    case placeRemoved(MapPoint)
    case retry
}
```

```swift
ListRow(title: task.title, subtitle: String(localized: task.category.title)) {
    MascotImage(size: Self.mascotSize)
} trailing: {
    PointsBadge(points: task.rewardPoints)
    FavoriteButton(isFavorite: true) { onAction(.taskRemoved(task)) }
}
...
.swipeActions(edge: .trailing) {
    Button {
        onAction(.taskRemoved(task))
    } label: {
        Image(systemName: "heart.slash.fill")
    }
    .tint(Palette.forest)
}
```

Шеврон в строках советов и мест заменяется сердцем (строка и так открывается тапом).

**Скрытый баг рядом:** `FavoritesRoute.selectedPlace` ищет точку в `savedPlaces`, поэтому «Сохранено → Сохранить» в шторке места мгновенно закрывает шторку. Искать в `uiState.mapPoints` — шторка остаётся, кнопка переключается.

**Android:** `FavoritesScreen.kt` и `BookmarksScreen.kt` — `IconButton` с `Favorite` в `trailing`, во VM `onToggleFavorite` / `onToggleBookmark` через существующие `ToggleTaskFavoriteUseCase` / `ToggleTipBookmarkUseCase`. `SavedPlacesScreen.kt` уже так делает.

### A3. Сердце на экране совета/статьи

В списке советов сердце уже есть (`EcoTipsListScreen`), а на самом экране статьи — нет. `EcoTipDetailViewModel` получает `ObserveBookmarkedTipIdsUseCase` + `ToggleTipBookmarkUseCase`, `EcoTipDetailUiState.isBookmarked`; кнопка — `FavoriteButton` в тулбаре:

```swift
.toolbar {
    ToolbarItem(placement: .topBarTrailing) {
        FavoriteButton(isFavorite: uiState.isBookmarked, action: onToggleBookmark)
    }
}
```

**Android:** `EcoTipDetailScreen.kt` — `IconButton` в `actions` верхней панели.

### A4. Иконка очков на карточке прогресса

`ProgressHeroCard.swift:46` и Android `ProgressHeroCard.kt:132`: `star.fill` / `Icons.Filled.Star` → `bolt.fill` / `Icons.Filled.Bolt`. Спека уже так и говорит (таблица иконок, «Очки — `bolt.fill`»).

### A5. Тумблер уведомлений после отказа

`requestIfNeeded()` при `.denied` возвращает `false` без всякой реакции, а статус читается только один раз в `observe()`, так что после возврата из Настроек тумблер не обновляется.

```swift
enum NotificationAuthorization {
    case authorized
    case denied
}
```

```swift
protocol NotificationPermission {
    func requestIfNeeded() async -> NotificationAuthorization
    func isAuthorized() async -> Bool
}
```

`SetNotificationsEnabledUseCase.execute` возвращает `NotificationAuthorization`; `ProfileViewModel`:

```swift
private(set) var opensNotificationSettings = 0

func toggleNotifications(_ isEnabled: Bool) {
    Task {
        let authorization = await setNotificationsEnabled.execute(isEnabled: isEnabled)
        uiState.notificationsEnabled = isEnabled && authorization == .authorized
        if isEnabled && authorization == .denied {
            opensNotificationSettings += 1
        }
    }
}

func refreshNotifications() async {
    uiState.notificationsEnabled = await notificationPermission.isAuthorized() && isNotificationsEnabled.execute()
}
```

`ProfileRoute`: `.onChange(of: viewModel.opensNotificationSettings) { openURL(URL(string: UIApplication.openNotificationSettingsURLString)) }` и `.onChange(of: scenePhase) { if $1 == .active { Task { await viewModel.refreshNotifications() } } }`. Если пользователь включил уведомления в Настройках, но `notifications_enabled` выключен, тумблер покажет «выкл» — он включит его, и запрос пройдёт (статус уже `.authorized`).

**Android:** уже сделано (`ProfileScreen.kt:87–133`), правок нет.

### A6. Календарь: отдельный счётчик «я записан»

Сейчас красная капсула = все события дня. Нужно: красная — события, на которые я **не** записан, зелёная (Forest) — на которые записан; если в дне есть оба вида, видны две капсулы.

`CalendarViewModel` получает `ObserveSessionUseCase` + `ObserveRegisteredEventIdsUseCase` (уже есть, им пользуется `EventDetailViewModel`), хранит `registeredEventIds: Set<String>`. Новая модель дня:

```swift
struct DayEventCounts: Hashable {
    let open: Int
    let registered: Int
}
```

```swift
private static func dayCounts(events: [EcoEvent], registeredIds: Set<String>) -> [DateComponents: DayEventCounts] {
    return Dictionary(grouping: events, by: \.day).mapValues { dayEvents in
        let registered = dayEvents.filter { return registeredIds.contains($0.id) }.count
        return DayEventCounts(open: dayEvents.count - registered, registered: registered)
    }
}
```

`EventCountBadge.make(counts:)` возвращает `UIStackView` из 0–2 капсул (`Palette.error` и `Palette.forest`, общий метод создания капсулы). `EventCalendarView` принимает `[DateComponents: DayEventCounts]`, логика `changedDays` сравнивает уже их — перерисовываются и дни, где поменялась только запись.

**Android:** `CalendarViewModel.kt` — `combine` с `ObserveRegisteredEventIdsUseCase`; `MonthCalendar.kt` `EventCountBadge(count)` → `EventCountBadges(open, registered)` в `Row`, вторая капсула `colorScheme.primary`.

Спека 6.11: «капсула красная — события, на которые ты не записан; зелёная (Forest) — на которые записан; в дне могут быть обе».

### A7. Шторка события — по высоте контента

`EventDetailSheet` жёстко ставит `.large`, а у короткого события под кнопкой пустая половина экрана. Высоту контента сейчас считают три места тремя способами (задание — `ContentHeightPreferenceKey`, точка карты и стрик — `onGeometryChange` с добавкой). Сводим в один компонент:

```swift
struct FittedSheetDetent: ViewModifier {
    private static let minimumHeight: CGFloat = 200

    let chromeHeight: CGFloat
    @State private var contentHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
                contentHeight = height
            }
            .presentationDetents([.height(max(contentHeight + chromeHeight, Self.minimumHeight))])
            .presentationDragIndicator(.visible)
    }
}
```

```swift
extension View {
    func fittedSheetDetent(chromeHeight: CGFloat) -> some View {
        return modifier(FittedSheetDetent(chromeHeight: chromeHeight))
    }

    func reportsSheetContentHeight() -> some View {
        return background {
            GeometryReader { proxy in
                Color.clear.preference(key: ContentHeightPreferenceKey.self, value: proxy.size.height)
            }
        }
    }
}
```

`TaskDetailRoute` и `EventDetailRoute` используют `.fittedSheetDetent(...)`, экраны помечают прокручиваемый контент и нижний блок кнопок `.reportsSheetContentHeight()` (вместо двух копий `GeometryReader` в `TaskDetailScreen`). Система сама ограничивает `.height` большим детентом, поэтому длинное описание просто прокручивается.

`EventDetailRoute` убирает навбар с кнопкой «Закрыть» — так же, как Макс сделал в шторке задания (закрывается свайпом, есть маркер). `MapPointSheetPresentation` и шторка стрика остаются на `onGeometryChange` (у них нет `ScrollView`), но получают защиту от нуля — см. B3.

**Android:** `GpSheetScaffold` — `ModalBottomSheet`, он уже по высоте контента; проверить на эмуляторе, правок не ожидается.

`CLAUDE.md` (Navigation) и спека (п. «Детали задания и события», 6.7): обе шторки — по высоте контента.

### A8. Фото у задания

Админка уже позволяет загрузить фото задания (`TaskEditorPage.tsx`, поле `imageUrl`), `EcoTask.imageUrl` уже маппится, но шторка его не показывает. Если фото есть — сверху шторки, как у события (3:2):

```swift
if let imageUrl = task.imageUrl.flatMap(URL.init(string:)) {
    Color.clear
        .aspectRatio(Self.imageAspectRatio, contentMode: .fit)
        .overlay {
            RemoteImage(url: imageUrl)
        }
        .clipShape(.rect(cornerRadius: CornerRadius.large, style: .continuous))
}
```

Без фото шторка выглядит как сейчас. В сид-контенте у заданий фото нет — проверять на задании, которому фото добавлено в админке.

**Android:** `TaskDetailSheet.kt` — `NetworkImage` с тем же соотношением сверху.

Спека 6.6: «Сверху фото задания (3:2), если загружено в админке».

### A9. Напоминания о событиях («надеюсь, напоминают»)

Работают, но с тремя багами:
1. **Выключение тумблера не снимает уже поставленные напоминания** о событиях и купонах — снимается только стрик (`SetNotificationsEnabledUseCase`). На Android воркер проверяет флаг в момент срабатывания, на iOS — только при постановке. Добавить `ReminderScheduler.cancelAllReminders()` (`removeAllPendingNotificationRequests()`) и вызывать при выключении.
2. **Запись меньше чем за час до начала — напоминание не приходит.** `max(date, Date())` даёт `UNCalendarNotificationTrigger` на уже прошедшую секунду. Android в этом случае шлёт сразу (`coerceAtLeast(0)`). Перейти на интервальный триггер:
   ```swift
   private static let minimumTriggerDelay: TimeInterval = 1

   let delay = max(fireDate.timeIntervalSinceNow, Self.minimumTriggerDelay)
   let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
   ```
3. **Запись в журнал идёт до проверки разрешения**: при выключенных уведомлениях в журнале появляется напоминание, которое не придёт. `deliver` возвращает `Bool`, `schedule` пишет в журнал только при `true`.

Ограничение остаётся: напоминание ставится только на устройстве, где была запись, и не переносится, если админ сдвинул время. Записываю в «Known limitations» `CLAUDE.md`.

---

## Часть B. Аудит выходных коммитов

### B1. Нарушения правил `CLAUDE.md`

| Где | Правило | Исправление |
|---|---|---|
| `app/ThemedRoot.swift` | `print("Не удалось…")` — захардкоженная строка, отладочный вывод | убрать `do/catch`, `try? await` |
| `app/ThemedRoot.swift` | `.milliseconds(900)` инлайн | `private static let iconSwitchDelay: Duration = .milliseconds(900)` |
| `app/ThemedRoot.swift` | `theme`, `wantsDarkIcon` без `return`; лишний `private enum AppIconName` вместо `private static let`; лишний `@MainActor` (изоляция по умолчанию) | вернуть `private static let darkIconName`, дописать `return` |
| `home/ui/HomeRoute.swift`, `map/ui/MapPointSheet.swift` | `{ $0.size.height }` без `return` | `{ proxy in return proxy.size.height }` |
| `auth/ui/AuthScreen.swift` | комментарий `// включить, когда…` | удалить (причина уже в `CLAUDE.md` → Known limitations) |
| `home/ui/HomeScreen.swift:88` | `.lineLimit(2)` инлайн | `private static let quickActionLineLimit = 2` |
| `tasks/ui/TaskDetailRoute.swift` | `NavigationStack` со скрытым навбаром ничего не делает | убрать при переходе на `fittedSheetDetent` (A7) |
| `CLAUDE.md` | говорит «event sheet full-height» и «clamped… 90%», а это уже не так | переписать абзац Navigation под A7 |

### B2. `calendar/ui/EventDetailScreen.swift` — двойная вибрация

`.sensoryFeedback(.success, trigger: uiState.isCheckedIn)` стоит два раза подряд (с `298faf2`) → при отметке на месте двойной отклик. Удалить дубль.

### B3. `map/ui/MapRoute.swift` + `MapPointSheet` — схлопывание шторки при закрытии

После `cd84e04` содержимое шторки — `Group { if let point … }`. Когда `selectedPointId` сбрасывается, `Group` пустеет на время анимации закрытия, `onGeometryChange` отдаёт 0, и детент прыгает до 16 pt. Игнорировать нулевую высоту:

```swift
.onGeometryChange(for: CGFloat.self) { proxy in
    return proxy.size.height
} action: { measured in
    guard measured > 0 else {
        return
    }
    height = measured + MapPointSheet.bottomAllowance
}
```

Сам подход Макса (одна шторка, содержимое меняется при тапе по другой метке без закрытия и открытия) хороший — оставляю.

### B4. `FavoritesRoute` — шторка места закрывается при «Сохранено» → см. A2.

### B5. Проверено, багов нет
- `ContentHeightPreferenceKey.reduce` с `+=` (а не `max`, как было в плане) — правильно: суммирует контент и блок кнопки.
- `ThemedRoot.task(id: wantsDarkIcon)` — задержка нужна, чтобы системный алерт смены иконки не появлялся во время анимации смены темы; повторный тап отменяет предыдущую задачу. Оставляю, только привожу к правилам (B1).
- Ключи `Localizable.xcstrings` из `0e4900a` — у всех есть `ru`/`be`/`en`.

---

## Документы
- `claude/ux-spec.ru.md` (обе копии): п. «Детали задания и события» → «по высоте контента»; 6.6 — фото и сердце; 6.7 — без кнопки «Закрыть»; 6.11 — две капсулы; 6.13 — сердце в строке, на iOS ещё свайп; совет — сердце на экране статьи. В «Android backlog» новых пунктов нет — Android делается в этой же сессии.
- `CLAUDE.md`: абзац Navigation (A7), «Known limitations» (A9).

## Верификация

**iOS:**
```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
```
Вручную на симуляторе (светлая и тёмная тема):
1. Главная → задание → сердце справа от названия; после тапа задание есть во «Избранном» и сердце залито в списке «Все».
2. «Избранное» → задания / советы / места: тап по сердцу и свайп убирают строку; в шторке места «Сохранено → Сохранить» не закрывает шторку.
3. Совет → сердце в тулбаре, совет появился во вкладке «Советы» «Избранного».
4. Карточка прогресса на Главной — молния, как на бейджах заданий.
5. Профиль → запретить уведомления в системном запросе → тап по тумблеру открывает Настройки → включить → вернуться: тумблер включается тапом.
6. Календарь: записаться на событие → в этот день зелёная капсула «1»; день с 2 свободными и 1 записанным — красная «2» и зелёная «1».
7. Главная → ближайшее событие: шторка по высоте контента, кнопка записи сразу под описанием.
8. Задание с фото из админки — фото сверху шторки; без фото — как раньше.
9. Записаться на событие, которое начнётся меньше чем через час → уведомление приходит сразу; выключить тумблер → `UNUserNotificationCenter` не содержит ожидающих запросов (проверка: напоминание не приходит).
10. Карта: открыть точку, закрыть свайпом — шторка не схлопывается в полоску перед закрытием; тап по другой метке меняет содержимое без закрытия.

**Android:** `./gradlew :app:assembleDebug`, пункты 1–4, 6–8 на эмуляторе.
