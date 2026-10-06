# Клавиатура без кнопок: закрытие свайпом или тапом (iOS)

## Контекст

На экранах со списком (`List` / `Form`) над клавиатурой стоит кнопка «спрятать клавиатуру» (`keyboard.chevron.compact.down`), а у поля создания группы клавиша ввода подписана «Done». Пользователь хочет убрать такие кнопки: клавиатура закрывается только жестом. Если экран прокручивается — свайпом вниз, если это обычный стек — тапом по пустому месту. Касается только iOS: на Android клавиатура закрывается системной кнопкой «назад».

### Что сейчас на экранах с вводом

| Экран | Контейнер | Сейчас | Станет |
|---|---|---|---|
| `AuthScreen` | `ScrollView` | свайп + тап по фону | без изменений |
| `ProfileSetupScreen` | `ScrollView` | свайп + тап по фону | без изменений |
| `GroupDetailScreen` (чат) | `ScrollView` | свайп + тап по фону | без изменений |
| `ForumScreen` | `List` | свайп + **кнопка над клавиатурой** | только свайп |
| `GroupsScreen` | `List` | свайп + **кнопка** + клавиша «Done» | только свайп, обычная клавиша ввода |
| `FeedbackScreen` | `Form` | свайп + **кнопка** | только свайп |
| `MapScreen` (поиск) | карта | тап по карте | без изменений |

`List` и `Form` всегда пружинят по вертикали (даже когда строк мало), поэтому свайп вниз закрывает клавиатуру и на коротком списке. Тап по фону на списках не добавляю: жест на весь `List` срабатывает и при тапе по соседнему полю или строке. Клавиатура тогда моргает, а действие строки конфликтует с жестом.

Первым действием план сохраняется в `claude/keyboard-dismissal-plan.ru.md`.

## Шаг 1. Убрать кнопку над клавиатурой

`dismissesKeyboardOnScroll()` в `presentation/components/View+KeyboardDismissal.swift` нужен только ради этой кнопки. Без неё он превращается в обёртку над одной строкой, поэтому удаляю его. На трёх экранах вызываю системный модификатор напрямую, как это уже сделано на `ScrollView`-экранах.

`View+KeyboardDismissal.swift` после правки:
```swift
import SwiftUI

extension View {
    func dismissesKeyboardOnBackgroundTap() -> some View {
        return background {
            Color.clear
                .contentShape(.rect)
                .onTapGesture {
                    Keyboard.dismiss()
                }
        }
    }
}
```

`ForumScreen`, `GroupsScreen`, `FeedbackScreen`:
```swift
.scrollDismissesKeyboard(.interactively)
```
вместо `.dismissesKeyboardOnScroll()`.

Строка `hide_keyboard` в `Localizable.xcstrings` больше нигде не используется (в Android её нет), поэтому удаляю её. Удаляю точечно, как добавлял строки легенды, без переформатирования файла.

## Шаг 2. Клавиша «Done» у поля группы

`GroupsScreen`: убираю `.submitLabel(.done)`. `.onSubmit(onCreate)` оставляю: клавиша ввода по-прежнему создаёт группу, но подписана обычным «ввод», а не «Done». Совсем убрать клавишу ввода с системной клавиатуры нельзя.

```swift
TextField(String(localized: .groupsDraftLabel), text: $draftName)
    .onSubmit(onCreate)
```

## Шаг 3. Документация

`CLAUDE.md`, раздел Conventions, строка про клавиатуру:
```
- Keyboard: every screen with text input must let the user hide the keyboard with a gesture only — no hide-keyboard or "Done" buttons above or on the keyboard. Scrollable screens close it by dragging down: `ScrollView` screens use `.scrollDismissesKeyboard(.interactively)` plus `.dismissesKeyboardOnBackgroundTap()`, `List`/`Form` screens use `.scrollDismissesKeyboard(.interactively)` (they always bounce, so a short list works too). Non-scrolling screens close it on a tap outside the field (`.dismissesKeyboardOnBackgroundTap()`; the map dismisses it on a map tap).
```
Спеку не трогаю: на Android клавиатура закрывается системной кнопкой «назад», UX-поток не меняется. Это нативное поведение платформы.

## Проверка

```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
grep -rn "dismissesKeyboardOnScroll\|placement: .keyboard\|hideKeyboard" "Green Passport"
```
Последний `grep` должен ничего не найти.

Ручные сценарии (на симуляторе включить программную клавиатуру: I/O → Keyboard → Toggle Software Keyboard):
1. Форум и отзывы: фокус в поле — над клавиатурой нет кнопки; свайп списка вниз закрывает клавиатуру.
2. Группы (пустой список и со списком): нет кнопки над клавиатурой, клавиша ввода подписана «ввод» и создаёт группу; свайп вниз закрывает клавиатуру.
3. Вход и анкета: свайп вниз и тап по пустому месту закрывают клавиатуру.
4. Чат группы: свайп вниз по сообщениям и тап по пустому месту закрывают клавиатуру.
5. Карта: тап по карте закрывает клавиатуру поиска.
