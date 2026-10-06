# Коммит iOS и перенос правок в Android

## Контекст

В iOS-репозитории не закоммичены правки этой сессии: три бага календаря (поиск дня по хешу, нулевой размер бейджа, центровка бейджа), перерисовка дня после записи, легенда календаря, подпись способа подтверждения в шторке задания, отступ сверху у шторок, диалог «Обменять» у кнопки, плашка «Уже изучено», обновлённая спека. Нужно закоммитить их, а затем перенести в Android (`~/Personal/greenpassport-android`) то, что относится к общему UX, и закоммитить там.

### Что переносить в Android, а что нет

| Правка iOS | Android | Решение |
|---|---|---|
| Баги бейджей календаря (`DateComponents`, `UICalendarView`) | `MonthCalendar` на Compose, своих ячеек; бейджи уже есть и центрированы | не переносится, баги чисто iOS |
| **Легенда под календарём** | нет | **переносится** |
| **«Подтверждение фото» не переносится** | `Row` с `PointsChip` + `Text`, текст переносится | **переносится** (`FlowRow`, как в `ProgressHeroCard`) |
| Отступ над шапкой шторки | у `ModalBottomSheet` M3 есть drag handle с отступами ~48 dp до контента | уже выполнено, не трогаю |
| Диалог «Обменять» у кнопки | `AlertDialog` по центру экрана — норма Material | не переносится, платформенное |
| «Уже изучено» перекрывает текст | блок внизу стоит вне прокрутки (`Column` + `weight(1f)`), не перекрывает | уже выполнено |

Отсюда правка формулировок спеки, чтобы они были платформенно-нейтральными (см. шаг 1).

## Шаг 1. Спека (обе копии)

Сейчас в iOS-спеке пиксельные и iOS-специфичные формулировки. Привожу к нейтральным:

- 6.6: «Подпись способа подтверждения не переносится: не помещается рядом с бейджем очков — встаёт строкой ниже. Над шапкой — заметный отступ от края шторки (на Android его даёт drag handle).»
- 6.11: легенда остаётся как есть («Под сеткой в той же карточке легенда: красная точка `not_registered`, зелёная точка `registered`…»).
- 6.15: «Метка «изучено» не перекрывает текст статьи (iOS — на плашке с фоном).»
- Android backlog: две строки, добавленные в этой сессии, после переноса отмечаются `[x]`.

Android-копия спеки содержит строку про точку пользователя на карте (6.12), которой нет в iOS. Этой строки не касаюсь, переношу только свои изменения, а не копирую файл целиком.

## Шаг 2. Коммит iOS

Первым действием: этот план сохраняется в `claude/final-fixes-plan.ru.md` (перезаписывает прежний, он устарел). Затем:

```
Fix calendar badges and polish task, shop and tip screens

- Calendar day badges are found by day and laid out centred, so the red and green counts finally show and stay in place.
- A day's badge is redrawn right after signing up for an event from the calendar.
- The calendar shows a legend for the red and green counts.
- The task sheet keeps the verification label on one line and both detail sheets get more space above the header.
- The exchange confirmation in the shop opens at the coupon's button.
- The "already studied" label on a tip sits on a background and no longer overlaps the article.
```

Без упоминания Claude/AI и без трейлеров (правило CLAUDE.md обоих репозиториев).

## Шаг 3. Android: легенда календаря

**Почему:** спека 6.11 теперь требует легенду, на Android её нет.

Новый файл `feature/calendar/.../presentation/ui/CalendarLegend.kt`:
```kotlin
package com.smartcity.greenpassport.feature.calendar.presentation.ui

@Composable
fun CalendarLegend(modifier: Modifier = Modifier) {
    Row(
        horizontalArrangement = Arrangement.spacedBy(Dimens.SpacingMedium, Alignment.CenterHorizontally),
        modifier = modifier.fillMaxWidth(),
    ) {
        CalendarLegendItem(
            title = stringResource(R.string.not_registered),
            color = MaterialTheme.colorScheme.error,
        )
        CalendarLegendItem(
            title = stringResource(R.string.registered),
            color = MaterialTheme.colorScheme.primary,
        )
    }
}

@Composable
private fun CalendarLegendItem(title: String, color: Color) {
    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(Dimens.SpacingExtraSmall),
    ) {
        Box(
            modifier = Modifier
                .size(Dimens.CalendarLegendDotSize)
                .background(color, CircleShape),
        )
        Text(
            text = title,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
    }
}
```
`Dimens.kt` (core): `val CalendarLegendDotSize = 8.dp` рядом с `CalendarBadgeMinSize`.

`CalendarScreen.kt`, карточка месяца:
```kotlin
GpSurfaceCard(modifier = Modifier.fillMaxWidth()) {
    Column(
        verticalArrangement = Arrangement.spacedBy(Dimens.SpacingSmall),
        modifier = Modifier.padding(Dimens.CardPadding),
    ) {
        MonthCalendar(
            month = uiState.visibleMonth,
            selectedDay = uiState.selectedDay,
            dayCounts = uiState.dayCounts,
            onMonthChange = viewModel::onMonthChange,
            onDaySelected = { day ->
                viewModel.onDaySelected(day)
                coroutineScope.launch { listState.animateScrollToItem(DAY_TITLE_ITEM_INDEX) }
            },
        )
        CalendarLegend()
    }
}
```
Строки в `feature/calendar/src/main/res/values{,-be,-en}/strings.xml` (ключи те же, что в iOS):
```xml
<string name="not_registered">Не записаны</string>
<string name="registered">Записаны</string>
```
be: `Не запісаныя` / `Запісаныя`; en: `Not registered` / `Registered`.

## Шаг 4. Android: подпись способа подтверждения

**Почему:** в `TaskDetailSheet.kt` `PointsChip` и подпись стоят в `Row`, длинная «Подтверждение фото» переносится. Делаю как у капсулы серии в `ProgressHeroCard`: `FlowRow`, подпись в одну строку и при нехватке места уходит на следующую строку.

```kotlin
FlowRow(
    horizontalArrangement = Arrangement.spacedBy(Dimens.SpacingSmall),
    verticalArrangement = Arrangement.spacedBy(Dimens.SpacingExtraSmall),
    itemVerticalAlignment = Alignment.CenterVertically,
    modifier = Modifier.padding(top = Dimens.SpacingExtraSmall),
) {
    PointsChip(points = task.rewardPoints)
    Text(
        text = stringResource(verificationLabelRes(task.verification)),
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.outline,
        maxLines = 1,
        softWrap = false,
    )
}
```
Если `ProgressHeroCard` использует `@OptIn(ExperimentalLayoutApi::class)`, ставлю такой же.

## Шаг 5. Спека → `[x]` и коммиты

- В обеих копиях спеки два пункта Android backlog этой сессии отмечаются `[x]`.
- План для Android сохраняется в `~/Personal/greenpassport-android/claude/final-fixes-plan.ru.md`.
- Коммит Android:
  ```
  Add the calendar legend and keep the task verification label on one line

  - The calendar card shows a legend for the red and green event counts.
  - The task sheet keeps the verification label on one line and moves it below the points when it does not fit.
  ```
- Коммит iOS (только спека): `Mark the calendar legend and verification label as done on Android`.

## Проверка

iOS:
```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
```
Android (до коммита):
```bash
./gradlew assembleDebug
./gradlew detektAll
./gradlew :feature:calendar:lintDebug :feature:tasks:lintDebug
```
Ручные сценарии на Android (проверяете вы на устройстве или эмуляторе):
1. Календарь: под сеткой легенда «● Не записаны ● Записаны», точки красная и зелёная, совпадают с цветами бейджей; светлая и тёмная тема.
2. Шторка задания с фото: «Подтверждение фото» одной строкой рядом с очками или строкой ниже, без переноса по словам.
