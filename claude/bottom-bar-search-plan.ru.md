# План: нижний бар только на вкладках и нижний поиск (iOS + Android)

После одобрения план сохраняется в обоих репозиториях как `claude/bottom-bar-search-plan.ru.md` — это первое действие, до кода.

## Контекст

Сейчас нижний бар виден на всех экранах:
- **iOS:** у каждой вкладки свой `NavigationStack` внутри `TabView` (`TabStack`), поэтому любой push происходит *внутри* вкладки и таб-бар остаётся.
- **Android:** `GlassBottomBarLayout` обёрнут вокруг всего `NavHost` и просто пропадает в момент перехода (`selected == null`), а сам переход — стандартный fade.

Нужно:
1. Бар есть только на корнях четырёх вкладок (Главная, Магазин, Карта, Избранное). Любой другой экран открывается **поверх** вкладки вместе с её баром: он въезжает и перекрывает бар. Без системного `toolbar(.hidden, for: .tabBar)`.
2. На экранах «Задания», «Эко-советы», «Игры», «Сообщество» внизу, на месте бывшего бара, стоит поле поиска по названию.

Что вы решили:
- iOS: на iOS 26 нативный `.searchable` снизу, на iOS 18 — своя стеклянная капсула.
- Android: push — сдвиг справа поверх вкладки, переключение вкладок мгновенное.
- Поиск работает вместе с фильтрами. «Совет дня» скрыт, пока запрос не пустой. Пустой результат — «Ничего не найдено».

Порядок работы (правило репозиториев): сначала `claude/ux-spec.ru.md` (одинаково в обоих репо), потом iOS, потом Android, в конце — CLAUDE.md обоих репо.

---

## 1. UX-спецификация (оба репо)

**Зачем:** любое изменение UX сначала записывается в спецификацию.
- **§2 «Вкладки»:** панель вкладок есть только на четырёх корневых экранах. Остальные экраны открываются поверх вкладки и перекрывают панель:
  - iOS — push в общем стеке над `TabView`;
  - Android — сдвиг справа; между вкладками переход без анимации.
- **§6.5 / §6.15 / §6.17 / §6.14:** внизу экрана — поле поиска по названию (`search_tasks_placeholder` / `search_ecotips_placeholder` / `search_games_placeholder` / `search_groups_placeholder`).
  - Поиск без учёта регистра.
  - Действует вместе с фильтрами.
  - У советов при непустом запросе скрыт «Совет дня».
  - Пусто — `nothing_found`.
  - В сообществе «Сверху поиск» меняется на «Снизу поиск».

## 2. iOS

### 2.1 Один стек над `TabView`

**Зачем:** перекрыть бар можно, только если push идёт в `NavigationStack`, который *содержит* `TabView`. Вложенные стеки SwiftUI не поддерживает, поэтому стеки вкладок убираем.

Новый тип `presentation/navigation/MainTab.swift`:

```swift
enum MainTab: Hashable, CaseIterable {
    case home
    case shop
    case map
    case favorites

    var title: LocalizedStringResource {
        switch self {
        case .home:
            return .home
        case .shop:
            return .shop
        case .map:
            return .map
        case .favorites:
            return .favorites
        }
    }

    var navigationTitle: LocalizedStringResource? {
        switch self {
        case .home, .map:
            return nil
        case .shop:
            return .shop
        case .favorites:
            return .favoritesScreenTitle
        }
    }

    var systemImage: String {
        switch self {
        case .home:
            return "house"
        case .shop:
            return "bag"
        case .map:
            return "map"
        case .favorites:
            return "heart"
        }
    }
}
```

`TabRouter` переименовывается в `AppRouter`, тип тот же. `TabStack.swift` удаляется. Во всех 7 местах с `@Environment(TabRouter.self)` меняется только имя типа. `MainTabView`:

```swift
struct MainTabView: View {
    let container: AppDIContainer

    @State private var router = AppRouter()
    @State private var selectedTab = MainTab.home

    var body: some View {
        NavigationStack(path: $router.path) {
            TabView(selection: $selectedTab) {
                Tab(String(localized: MainTab.home.title), systemImage: MainTab.home.systemImage, value: MainTab.home) {
                    HomeRoute(container: container)
                }
                Tab(String(localized: MainTab.shop.title), systemImage: MainTab.shop.systemImage, value: MainTab.shop) {
                    ShopRoute(container: container)
                }
                Tab(String(localized: MainTab.map.title), systemImage: MainTab.map.systemImage, value: MainTab.map) {
                    MapRoute(container: container)
                }
                Tab(String(localized: MainTab.favorites.title), systemImage: MainTab.favorites.systemImage, value: MainTab.favorites) {
                    FavoritesRoute(container: container)
                }
            }
            .navigationTitle(selectedTab.navigationTitle.map { return String(localized: $0) } ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(selectedTab.navigationTitle == nil ? .hidden : .visible, for: .navigationBar)
            .navigationDestination(for: AppDestination.self) { destination in
                AppDestinationView(destination: destination, container: container)
            }
        }
        .environment(router)
    }
}
```

**Почему заголовки на уровне `TabView`:** `.navigationTitle` и `.toolbar(.hidden)` из содержимого вкладки не доходят до стека, который лежит снаружи `TabView`. Поэтому `navigationTitle` убирается из `ShopScreen` и `FavoritesScreen`, а `.toolbar(.hidden, for: .navigationBar)` — из `HomeScreen` и `MapScreen`. В превью эти экраны остаются в `NavigationStack`.

`AppDestinationView` не меняется: он уже включает панель через `.toolbar(.visible, for: .navigationBar)` и задаёт inline-заголовок.

**Риск, который проверяем на симуляторе:** под панелью Магазина и Избранного должен работать scroll edge effect (размытие при прокрутке). Если `UITabBarController` не передаёт scroll view навигационной панели, Магазин и Избранное получают собственную шапку в контенте, как у Главной. Если так случится, вернусь к вам до правок.

### 2.2 Общий нижний поиск

Новый файл `presentation/components/View+BottomSearch.swift`. iOS 26-API вызывается только здесь, как требует правило про availability:

```swift
extension View {
    @ViewBuilder
    func bottomSearchable(text: Binding<String>, prompt: LocalizedStringResource) -> some View {
        if #available(iOS 26, *) {
            searchable(text: text, prompt: Text(prompt))
                .toolbar {
                    DefaultToolbarItem(kind: .search, placement: .bottomBar)
                }
        } else {
            safeAreaInset(edge: .bottom, spacing: 0) {
                BottomSearchField(text: text, prompt: prompt)
            }
        }
    }
}
```

Новый файл `presentation/components/BottomSearchField.swift` — запасная капсула для iOS 18:

```swift
struct BottomSearchField: View {
    @Binding var text: String
    let prompt: LocalizedStringResource

    var body: some View {
        HStack(spacing: Spacing.xSmall) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Palette.secondaryText)
            TextField(String(localized: prompt), text: $text)
                .submitLabel(.search)
                .autocorrectionDisabled()
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(Palette.tertiaryText)
                }
                .accessibilityLabel(Text(.clear))
            }
        }
        .padding(.horizontal, Spacing.medium)
        .padding(.vertical, Spacing.small)
        .adaptiveGlassEffect(in: .capsule)
        .padding(.horizontal, Spacing.screenHorizontal)
        .padding(.bottom, Spacing.xSmall)
    }
}
```

Сравнение с запросом выносится в общий файл `presentation/components/String+SearchQuery.swift`:

```swift
extension String {
    func matchesSearchQuery(_ query: String) -> Bool {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return true
        }
        return localizedStandardContains(trimmed)
    }
}
```

Ключ `clear` проверю. Если его нет, добавлю вместе с остальными строками (ru/be/en).

### 2.3 Задания

**Зачем:** поиск работает вместе с фильтрами, и в счётчике кнопки `show_tasks_count` должен учитываться запрос.

```swift
struct TasksListUiState {
    var query = ""

    var isSearching: Bool {
        return !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func tasks(for filters: TaskFilters) -> [EcoTask] {
        let filtered = filters.apply(
            to: tasks,
            completedIds: completedTaskIds,
            pendingIds: pendingTaskIds,
            profileCity: profile?.city
        )
        .filter { return $0.title.matchesSearchQuery(query) }
    }
}
```

- В `TasksListUserAction` добавляется `case queryChanged(String)`. ViewModel записывает его в `uiState.query`.
- `TasksListScreen` строит binding из данных и замыкания, без ViewModel:

```swift
.bottomSearchable(
    text: Binding(get: { return uiState.query }, set: { onAction(.queryChanged($0)) }),
    prompt: .searchTasksPlaceholder
)
.scrollDismissesKeyboard(.interactively)
```

- Пустое состояние: `StateView(kind: .empty(message: uiState.isSearching ? .nothingFound : .tasksEmpty))`.

### 2.4 Эко-советы

```swift
struct EcoTipsListUiState {
    var query = ""

    var isSearching: Bool {
        return !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var dailyTip: EcoTip? {
        guard !isSearching else {
            return nil
        }
        return tips.first { return $0.isDailyTip }
    }

    var visibleTips: [EcoTip] {
        let byCategory: [EcoTip]
        switch filter {
        case .all:
            byCategory = tips
        case .category(let category):
            byCategory = tips.filter { return $0.category == category }
        }
        return byCategory.filter { return $0.title.matchesSearchQuery(query) }
    }
}
```

- `EcoTipsListViewModel.updateQuery(_:)`.
- Экран получает `@Binding var query`, как `CommunityHubScreen`; route передаёт `Binding(get:set:)` во ViewModel.
- К экрану добавляются `.bottomSearchable(text: $query, prompt: .searchEcotipsPlaceholder)` и `.scrollDismissesKeyboard(.interactively)`.
- Пустой результат при поиске — `.nothingFound`.

### 2.5 Игры

**Зачем:** `uiState` здесь — общий `ListUiState<Game>`. Чтобы не менять его тип, ViewModel отдаёт отфильтрованную копию.

```swift
private(set) var query = ""

var visibleState: ListUiState<Game> {
    guard case .success(let games) = uiState else {
        return uiState
    }
    return .success(data: games.filter { return $0.title.matchesSearchQuery(query) })
}

func updateQuery(_ query: String) {
    self.query = query
}
```

- `GamesHubScreen` получает `visibleState` и `@Binding var query`.
- Если в `.success` после поиска пусто — `StateView(kind: .empty(message: .nothingFound))`.
- Модификаторы `ScrollView`: `.bottomSearchable`, `.scrollDismissesKeyboard(.interactively)`, `.dismissesKeyboardOnBackgroundTap()`.

### 2.6 Сообщество

Одна замена в `CommunityHubScreen`. Логика `GroupSearch` (название и участники) остаётся прежней.

```swift
.bottomSearchable(text: $query, prompt: .searchGroupsPlaceholder)
```

вместо `.searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), ...)`.

### 2.7 Строки (`Localizable.xcstrings`, ru / be / en)

| Ключ | ru | be | en |
|---|---|---|---|
| `search_tasks_placeholder` | Поиск заданий | Пошук заданняў | Search tasks |
| `search_ecotips_placeholder` | Поиск советов | Пошук парад | Search tips |
| `search_games_placeholder` | Поиск игр | Пошук гульняў | Search games |
| `nothing_found` | Ничего не найдено | Нічога не знойдзена | Nothing found |

## 3. Android

### 3.1 Бар — часть экрана вкладки

**Зачем:** чтобы следующий экран мог перекрыть бар, бар должен рисоваться внутри экрана вкладки, а не над всем `NavHost`.

- `GreenPassportAppShell` больше не оборачивает `AppNavHost` в `GlassBottomBarLayout`. `previousTabUnderDialog` удаляется: шторка лежит над экраном вкладки, и бар этого экрана остаётся под ней сам.
- В `AppNavHost` четыре корневых экрана оборачиваются так:

```kotlin
@Composable
private fun TopLevelScreen(
    tab: TopLevelDestination,
    navController: NavHostController,
    content: @Composable () -> Unit,
) {
    GlassBottomBarLayout(
        selected = tab,
        onSelect = navController::navigateToTopLevel,
        isOpaque = tab == TopLevelDestination.MAP,
        content = content,
    )
}

composable<Destination.Shop> {
    TopLevelScreen(tab = TopLevelDestination.SHOP, navController = navController) {
        FeatureScaffold(...) { ... }
    }
}
```

- `GlassBottomBarLayout.selected` становится не-null.
- `navigateToTopLevel` переезжает в `navigation/NavControllerTopLevel.kt`.

### 3.2 Переходы

**Зачем:** push должен въезжать справа поверх вкладки, а переключение вкладок — без анимации, чтобы бар не дёргался.

```kotlin
NavHost(
    navController = navController,
    startDestination = Destination.Home,
    enterTransition = { if (isTabSwitch()) EnterTransition.None else slideIntoContainer(SlideDirection.Start) },
    exitTransition = { if (isTabSwitch()) ExitTransition.None else ExitTransition.KeepUntilTransitionsFinished },
    popEnterTransition = { EnterTransition.None },
    popExitTransition = { if (isTabSwitch()) ExitTransition.None else slideOutOfContainer(SlideDirection.End) },
    modifier = modifier,
)

private fun AnimatedContentTransitionScope<NavBackStackEntry>.isTabSwitch(): Boolean {
    return initialState.destination.isTopLevel() && targetState.destination.isTopLevel()
}

private fun NavDestination.isTopLevel(): Boolean {
    return TopLevelDestination.entries.any { tab -> hasRoute(tab.destination::class) }
}
```

На устройстве проверяю порядок слоёв при «назад»: уходящий экран должен быть сверху.

### 3.3 Нижний поиск

- **`core/designsystem/component/GlassSearchBar.kt`** — капсула той же высоты и с теми же отступами, что `GpBottomBar`: `BottomBarHeight`, `BottomBarOuterPadding`, стекло Haze, обводка, лупа, поле и крестик очистки. Строится на основе существующего `GpSearchField`.
- **`GlassHeaderScaffold` / `FeatureScaffold`** получают необязательный параметр `search: SearchBarContent?` (`query`, `onQueryChange`, `placeholder`). Если он передан:
  - капсула рисуется снизу с `navigationBarsPadding().imePadding()` и размывает тот же `hazeState`;
  - к `bottomPadding` контента прибавляется `BottomBarReservedHeight`.

```kotlin
data class SearchBarContent(
    val query: String,
    val onQueryChange: (String) -> Unit,
    val placeholder: String,
)
```

- **Задания, советы, игры:** в `UiState` добавляется `query`, во ViewModel — `onQueryChanged`. Фильтрация по `title.contains(query.trim(), ignoreCase = true)`, вместе с фильтрами, как на iOS. У советов при `isSearching` скрыт «Совет дня». Пусто — `nothing_found`.
- **Игры и советы:** ViewModel поднимается в `AppNavHost` через `hiltViewModel()`, как уже сделано для заданий и сообщества, чтобы передать `search` в `FeatureScaffold`.
- **Сообщество:** из `LazyColumn` удаляются `SearchField` и `SEARCH_KEY`. Запрос передаётся в `FeatureScaffold(search = ...)`.
- **Строки:** те же 4 ключа в `strings.xml`: задания, советы и игры — в своих модулях, `nothing_found` — в `core`; ru / be / en.

## 4. CLAUDE.md

- **iOS, раздел Navigation:**
  - один `NavigationStack` над `TabView`, `AppRouter`, `MainTab`;
  - заголовки корней вкладок задаются на уровне `TabView`;
  - нижний поиск только через `bottomSearchable`;
  - в разделе Availability добавляется строка про `DefaultToolbarItem(kind: .search)` → `BottomSearchField`.
- **Android:** бар — часть экранов вкладок, правила переходов, `FeatureScaffold(search =)`.

## 5. Проверка

**Сборка iOS:**
```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
```

**Сборка Android:**
```bash
cd ~/Personal/greenpassport-android && ./gradlew :app:assembleDebug
```

**Ручные сценарии (на обеих платформах; на iOS — iOS 26 и, если есть, iOS 18):**
1. С Главной открыть «Задания»: экран въезжает и перекрывает бар, бара на экране нет. «Назад» / свайп — экран уезжает, бар Главной на месте.
2. Профиль, Календарь, Отзывы, Уведомления, Мои купоны (из Магазина), статья из Избранного: бара нет нигде.
3. Переключение вкладок: бар не мигает. Заголовки Магазина и Избранного inline. У Главной и Карты нет навигационной панели. В Магазине и Избранном при прокрутке под заголовком появляется стекло.
4. Задания: поиск снизу. Ввод «пласт» оставляет только подходящие названия, фильтры работают вместе с поиском, в шторке фильтров счётчик учитывает запрос. Без совпадений — «Ничего не найдено».
5. Эко-советы: при вводе «Совет дня» скрывается, категория и поиск работают вместе.
6. Игры: поиск по названию на языке приложения. Клавиатура закрывается тапом по фону и прокруткой.
7. Сообщество: поиск снизу, результаты «Мои группы / Другие группы». Свайп вниз к архиву работает как раньше.
8. Шторка задания поверх вкладки: на Android бар вкладки виден под затемнением, как сейчас.
9. Светлая и тёмная темы. Поле поиска поднимается над клавиатурой и не перекрывает последнюю строку списка.
