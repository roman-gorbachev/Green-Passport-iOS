# Сообщество: архив, поиск на iOS, клавиатура и меню на Android

## Контекст

Замечания после второй проверки:
1. **Строка «Архив» должна прятаться обратной прокруткой** (обе платформы). Сейчас на iOS она прячется только после прокрутки вниз больше чем на 80 pt, а на Android — только когда поле поиска ушло за верх экрана. На коротком списке спрятать её нельзя вообще.
2. **iOS:** при открытии «Сообщества» слева на секунду мелькает иконка лупы. Это `.searchable` без явного размещения: на iOS 26 в открываемом экране система сначала ставит кнопку поиска в панель, потом переносит поле.
3. **Android, скриншоты форума:**
   - Клавиатура открыта: поле ввода висит на высоту клавиатуры выше неё, шапка уехала за статус-бар. У `MainActivity` не задан `windowSoftInputMode`, поэтому система сдвигает всё окно (`adjustPan`). Вместе с отступом `windowInsetsPadding(ime)` у поля ввода клавиатура учитывается дважды.
   - Новый пост лежит под заголовком «Форум» без размытия. Посты идут новыми сверху. Когда приходит новый пост, `LazyColumn` держит прежний первый пост на месте, и новый оказывается над ним, под шапкой. Шапка (`GlassHeaderScaffold`) размывается только при прокрутке пальцем, поэтому она «не видит» такой сдвиг.
4. **Android:** улучшить вид выпадающих меню. Сейчас это стандартный Material `DropdownMenu`: острые углы, серый тонированный фон, иконки разных цветов.

Первым действием план копируется в `claude/community-polish-plan.ru.md` обоих приложений.

---

## 1. Архив прячется обратной прокруткой

Раскрытие остаётся прежним: потянуть список вниз от верха. Прячется строка при любом движении списка вверх больше чем на 24 pt (`archiveHideDistance`). Это работает и на коротком списке.

**iOS** `CommunityHubScreen.swift`: порог скрытия становится маленьким и отсчитывается от верха, а не от 80 pt:
```swift
private static let archiveRevealDistance: CGFloat = 60
private static let archiveHideDistance: CGFloat = 24

private func updateArchiveVisibility(offset: CGFloat) {
    if offset < -Self.archiveRevealDistance && !isArchiveRevealed {
        isArchiveRevealed = true
    } else if offset > Self.archiveHideDistance && isArchiveRevealed {
        isArchiveRevealed = false
    }
}
```
Список с раскрытой строкой остаётся «в верхней точке» (offset ≈ 0). Поэтому движение вверх на 24 pt прячет строку, а потягивание вниз снова показывает.

**Android** `CommunityHubScreen.kt`, `rememberArchiveRevealConnection`: считаю движение вверх по сумме `consumed + available`. Так жест вверх засчитывается, даже когда список короткий и ничего не прокрутил:
```kotlin
override fun onPostScroll(consumed: Offset, available: Offset, source: NestedScrollSource): Offset {
    val delta = consumed.y + available.y
    if (delta > 0f && available.y > 0f) {
        pushed = 0f
        pulled += available.y
        if (pulled > revealDistance) onReveal()
    } else if (delta < 0f) {
        pulled = 0f
        pushed -= delta
        if (pushed > hideDistance) onHide()
    }
    return Offset.Zero
}
```
`Dimens.ArchiveHideDistance = 24.dp`.

Спека 6.14: «Прокрутка вверх (или жест вверх на коротком списке) снова прячет строку».

## 2. iOS: мелькающая лупа

`CommunityHubScreen.swift`: поле поиска закрепляется под заголовком и видно сразу:
```swift
.searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: Text(.searchGroupsPlaceholder))
```
Это совпадает со спекой («сверху поле поиска») и с Android, где поле стоит первой строкой списка.

## 3. Android: клавиатура и новые посты

**3.1 `app/src/main/AndroidManifest.xml`.** Окно больше не сдвигается целиком, а клавиатура приходит инсетами, которые экраны уже учитывают:
```xml
<activity
    android:name=".MainActivity"
    android:exported="true"
    android:windowSoftInputMode="adjustResize"
    android:theme="@style/Theme.GreenPassport">
```
С edge-to-edge (`enableEdgeToEdge`) `adjustResize` не меняет размер окна, а только передаёт `WindowInsets.ime`.
- Форум и группа уже делают `windowInsetsPadding(WindowInsets.ime.union(WindowInsets.navigationBars))`.
- Анкета и отзывы уже делают `imePadding()`. До этой правки у них, вероятно, тоже был двойной отступ.

**3.2 Экран входа** (`AuthScreen.kt`) — единственный экран с полями ввода без `imePadding`. Раньше его выручал сдвиг окна, теперь поля закрыла бы клавиатура. Его прокручиваемой колонке добавляется отступ:
```kotlin
Column(
    modifier = Modifier
        .fillMaxSize()
        .verticalScroll(rememberScrollState())
        .imePadding()
        …
```
Поиск в «Сообществе» стоит вверху, его клавиатура не закрывает. Диалоги `AlertDialog` обрабатывают клавиатуру сами.

**3.3 Новый пост на форуме виден сразу.** `ForumScreen.kt`: если список и так стоит вверху (первый или второй видимый элемент), он прокручивается к новому первому посту:
```kotlin
val newestPostId = uiState.posts.firstOrNull()?.id
LaunchedEffect(newestPostId) {
    if (newestPostId != null && listState.firstVisibleItemIndex <= NEWEST_POST_FOLLOW_INDEX) {
        listState.animateScrollToItem(0)
    }
}
```
`NEWEST_POST_FOLLOW_INDEX = 1`. Если человек читает старые посты ниже, его позиция не сбивается. В верхней точке шапка правильно остаётся без размытия: под ней ничего нет.

## 4. Android: стиль выпадающих меню

Новый общий компонент `core/designsystem/component/GpDropdownMenu.kt` (и `GpDropdownMenuItem.kt`). Меню похожи на iOS: скруглённая карточка `surface` с мягкой тенью, иконки цветом `primary`, у опасного пункта и текст, и иконка цвета `error`.
```kotlin
@Composable
fun GpDropdownMenu(
    expanded: Boolean,
    onDismissRequest: () -> Unit,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.() -> Unit,
) {
    DropdownMenu(
        expanded = expanded,
        onDismissRequest = onDismissRequest,
        shape = RoundedCornerShape(Dimens.CornerRadiusLarge),
        containerColor = MaterialTheme.colorScheme.surface,
        tonalElevation = Dimens.SpacingNone,
        shadowElevation = Dimens.MenuShadowElevation,
        modifier = modifier.widthIn(min = Dimens.MenuMinWidth),
        content = content,
    )
}
```
```kotlin
@Composable
fun GpDropdownMenuItem(
    text: String,
    icon: ImageVector?,
    onClick: () -> Unit,
    isDestructive: Boolean = false,
) {
    val color = if (isDestructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
    val iconColor = if (isDestructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
    DropdownMenuItem(
        text = { Text(text = text, style = MaterialTheme.typography.bodyLarge, color = color) },
        leadingIcon = icon?.let { { Icon(imageVector = it, contentDescription = null, tint = iconColor) } },
        onClick = onClick,
        contentPadding = PaddingValues(horizontal = Dimens.CardPadding),
    )
}
```
`Dimens.MenuShadowElevation = 8.dp`, `Dimens.MenuMinWidth = 200.dp`.

Перевожу на них все выпадающие меню проекта (`grep -rn "DropdownMenu("`). В сообществе это `MessageActionsBox`, `ChatListRow`, `GroupMenuButton`, `CommunityAddButton` и меню жалобы в `ForumScreen`. Остальные модули — по результату grep, чтобы стиль был одинаковым везде. Разделитель перед причинами жалобы остаётся `HorizontalDivider` цвета `outlineVariant`.

---

## Коммиты
1. iOS: архив, поиск, спека, план.
2. Android: архив, клавиатура и инсеты, новые посты, меню, спека, план.

## Проверка
```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
cd ~/Personal/greenpassport-android && ./gradlew assembleDebug detektAll :feature:community:lintDebug :core:lintDebug :feature:auth:lintDebug
```
Ручные сценарии:
1. Обе платформы: группа в архиве → потянуть список вниз → «Архив чатов» появился → движение вверх → строка спряталась. То же на коротком списке.
2. iOS: открыть «Сообщество» — поле поиска сразу под заголовком, лупа нигде не мелькает.
3. Android, форум: тап в поле — поле сразу над клавиатурой, шапка «Форум» на месте. Отправить пост — он виден сверху целиком, не под шапкой. То же в чате группы.
4. Android: вход по почте — поля не закрыты клавиатурой, их можно прокрутить. Анкета и отзывы — без лишней пустоты над клавиатурой.
5. Android: долгое нажатие на сообщение, на группу, меню «+» и меню группы — скруглённые меню с тенью, «Удалить» красным.
