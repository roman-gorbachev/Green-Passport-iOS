# План: минимальная версия iOS 18 + предупреждение в MapPointSheet

Первым действием после одобрения план копируется в `claude/ios18-deployment-plan.ru.md`.

## Контекст

Сейчас `IPHONEOS_DEPLOYMENT_TARGET = 26.5`, нужно опустить до 18.0. Код уже использует Liquid Glass и другие API, которых нет в iOS 18, — с новой минимальной версией они не скомпилируются. Отдельно: Xcode показывает фиолетовое предупреждение «Performing I/O on the main thread can cause slow launches» на `MapPointSheet.swift:69`.

Поиск по коду нашёл API только из iOS 26 (все остальные — `Tab`, `CLServiceSession`, `onGeometryChange`, MapKit для SwiftUI, SwiftData, `@Previewable`, `.sensoryFeedback`, `.symbolEffect` — есть в iOS 17/18):

| API | Где |
|---|---|
| `.buttonStyle(.glassProminent)` | `components/AppButton`, `components/MessageComposer`, `map/ui/MapPointSheet`, `moderation/ui/ModerationScreen` |
| `.buttonStyle(.glass)` | `map/ui/MapPointSheet`, `profilesetup/ui/ProfileSetupScreen`, `ecotips/ui/EcoTipDetailScreen`, `moderation/ui/ModerationScreen` (×3), `tasks/ui/QrScannerScreen` |
| `.glassEffect(in:)` | `map/ui/MapScreen` (×2), `components/MessageComposer`, `tasks/ui/QrScannerScreen`, `games/ui/GameWebScreen` |
| `Button(role: .close)` | `tasks/ui/QrScannerScreen`, `tasks/ui/TaskFiltersSheet`, `shop/ui/CouponDetailRoute`, `community/ui/GroupMembersSheet`, `games/ui/GameWebScreen` |
| `MKMapItem(location:address:)` | `map/ui/MapRoute`, `favorites/ui/FavoritesRoute` (одинаковый `openDirections`) |

Окончательный список даёт только компилятор, поэтому после правок будет **одна** сборка с новой минимальной версией (не запуск на симуляторе), чтобы поймать то, что поиск мог пропустить.

---

## 1. Минимальная версия

`Green Passport.xcodeproj/project.pbxproj`: `IPHONEOS_DEPLOYMENT_TARGET = 26.5` → `18.0` в обеих конфигурациях проекта (Debug и Release, строки 206 и 266). У таргета своего значения нет — он наследует от проекта. SwiftPM-зависимости (Firebase, GoogleSignIn) поддерживают iOS 15+, их не трогаем.

## 2. Адаптивные обёртки вместо прямых вызовов iOS 26

Везде одинаково: на iOS 26 — как сейчас (Liquid Glass), на iOS 18 — ближайший системный аналог. Проверки `#available` собраны в одном месте, а не в 15 экранах.

`presentation/components/View+AdaptiveGlass.swift`:

```swift
import SwiftUI

extension View {
    @ViewBuilder
    func adaptiveGlassEffect<S: Shape>(in shape: S) -> some View {
        if #available(iOS 26, *) {
            glassEffect(in: shape)
        } else {
            background(.regularMaterial, in: shape)
        }
    }

    @ViewBuilder
    func adaptiveGlassButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glass)
        } else {
            buttonStyle(.bordered)
        }
    }

    @ViewBuilder
    func adaptiveProminentGlassButtonStyle() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glassProminent)
        } else {
            buttonStyle(.borderedProminent)
        }
    }
}
```

Замена механическая: `.buttonStyle(.glass)` → `.adaptiveGlassButtonStyle()`, `.buttonStyle(.glassProminent)` → `.adaptiveProminentGlassButtonStyle()`, `.glassEffect(in: X)` → `.adaptiveGlassEffect(in: X)`.

`presentation/components/CloseButton.swift` — системная кнопка закрытия на iOS 26, крестик с тем же смыслом на iOS 18 (ключ `close` уже есть в каталоге):

```swift
import SwiftUI

struct CloseButton: View {
    let action: () -> Void

    var body: some View {
        if #available(iOS 26, *) {
            Button(role: .close, action: action)
        } else {
            Button(action: action) {
                Image(systemName: "xmark")
            }
            .accessibilityLabel(Text(.close))
        }
    }
}
```

`Button(role: .close) { dismiss() }` → `CloseButton { dismiss() }`, `Button(role: .close, action: onClose)` → `CloseButton(action: onClose)`. В `QrScannerScreen` стиль `.glass` у этой кнопки → `.adaptiveGlassButtonStyle()`.

## 3. Маршрут в Картах — одна функция вместо двух копий

`openDirections(to:)` продублирован в `MapRoute` и `FavoritesRoute`. Выносим в расширение модели (рядом с существующим `map/states/MapPoint+Coordinate.swift`) — `map/states/MapPoint+Directions.swift`:

```swift
import MapKit

extension MapPoint {
    func openDirections() {
        let item = mapItem
        item.name = name
        item.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDefault])
    }

    private var mapItem: MKMapItem {
        if #available(iOS 26, *) {
            return MKMapItem(location: CLLocation(latitude: latitude, longitude: longitude), address: nil)
        }
        return MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude)))
    }
}
```

`MKPlacemark` устарел в iOS 26, но при минимальной версии 18 и ветке после `#available` предупреждения не будет. В обоих Route: `onRoute: { point.openDirections() }`, приватные `openDirections` и лишний `import MapKit` (если больше не нужен) удаляются.

## 4. Предупреждение на `MapPointSheet.swift:69`

Моя позиция: **это не ошибка в нашем коде, и правки кода здесь не нужны.** Строка 69 — начало `.onGeometryChange` в `MapPointSheetPresentation`; там нет ни чтения файлов, ни `UserDefaults`, ни `Bundle`. Thread Performance Checker помечает первую строку *нашего* кода в стеке вызовов, а сам ввод-вывод происходит ниже, внутри SwiftUI. Скорее всего, при первом показе шторки система подгружает с диска ресурсы для кнопок `.glass`/`.glassProminent` (шейдеры Liquid Glass) и SF Symbols. Это разовая загрузка при первом открытии шторки, а не при запуске, и «slow launches» здесь не грозит.

Как подтвердить без догадок: в Issue navigator развернуть фиолетовое предупреждение и посмотреть стек. Если сверху кадры `SwiftUI` / `CoreUI` / `Metal` / `CoreText` — это система, оставляем. Если в стеке окажется наш кадр с `UserDefaults` / `Data(contentsOf:)` — пришли стек, перенесу чтение с главного потока.

Если очень хочется убрать сам маркер: сделать нечего, кроме отключения Thread Performance Checker в схеме, а этого я не советую — он ловит и настоящие проблемы.

## 5. Документы
- `CLAUDE.md`: «iOS deployment target 26.5» → «iOS deployment target 18.0; iOS 26-only APIs (Liquid Glass button styles, `glassEffect`, `Button(role: .close)`, `MKMapItem(location:address:)`) go only through `View+AdaptiveGlass`, `CloseButton` and `MapPoint+Directions`, which fall back to bordered styles, material and an `xmark` button on iOS 18». В раздел Conventions — правило: новые API новее iOS 18 только через `#available` в общих компонентах.
- `README.md:36`: «iOS 26.5 SDK» оставить (собираем тем же Xcode 26), дописать «runs on iOS 18+».
- `claude/ux-spec.ru.md` (обе копии), строка про Liquid Glass в таблице панелей: добавить «на iOS 18 — системный вид без стекла».

## Верификация

Одна сборка с новой минимальной версией, только чтобы компилятор подтвердил, что ошибок доступности не осталось:
```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
```
Если она выдаст ещё что-то `is only available in iOS 26` — чиню тем же способом (обёртка с `#available`) и добавляю в таблицу выше.

Вручную (делаешь ты): симулятор с iOS 18.x — приложение запускается; кнопки на шторке точки карты, в модерации, на кнопке `AppButton` — системные bordered; крестик закрытия в сканере QR, фильтрах заданий, купоне, участниках группы, игре; «Построить маршрут» открывает Карты. На iOS 26 всё выглядит как раньше.
