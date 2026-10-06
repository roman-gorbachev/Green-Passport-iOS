# Выбор иконки приложения с превью и новые варианты (iOS)

## Контекст

Сейчас в профиле блок «Иконка приложения» — два текстовых пункта «Светлая / Тёмная» с галочкой, без картинок. Нужно:
1. показывать каждую иконку картинкой;
2. кроме светлой и тёмной нарисовать ещё несколько интересных вариантов.

Только iOS: на Android смены иконки нет (пункт Android backlog).

Иконки сейчас: `AppIcon` (маскот на белом, `icon1.png`; в тёмном режиме системы — `icon2.png`) и `AppIconDark` (маскот на зелёном). Маскот с прозрачным фоном лежит в `Assets.xcassets/mascot.imageset/mascot.png` (1068×1104). Из него новые фоны собираются скриптом. Сборка уже регистрирует все наборы иконок как альтернативные (`ASSETCATALOG_COMPILER_INCLUDE_ALL_APPICON_ASSETS = YES`), правка `Info.plist` не нужна.

Первым действием план копируется в `claude/app-icons-plan.ru.md` iOS-репозитория.

---

## 1. Новые иконки

Четыре новых варианта, у всех один и тот же маскот, меняется сцена за ним:

| Вариант | Имя набора | Фон |
|---|---|---|
| Светлая | `AppIcon` | как сейчас |
| Тёмная | `AppIconDark` | как сейчас |
| Закат | `AppIconSunset` | градиент персик → малиновый, большое бледное солнце за маскотом |
| Ночь | `AppIconNight` | тёмно-синий градиент, звёзды, тонкий месяц |
| Океан | `AppIconOcean` | бирюзовый → глубокий синий, две мягкие волны у низа |
| Лайм | `AppIconLime` | фирменный лайм с радиальным свечением в центре |

**Скрипт** — `scripts/app-icons.py` (Pillow, как `scripts/game-icons.py` в Android-репо). Он рисует сцену 1024×1024, кладёт маскот по центру с мягкой тенью и сохраняет:
- `Assets.xcassets/AppIcon<Name>.appiconset/icon.png` + `Contents.json` (один размер 1024, без прозрачности — App Store и SpringBoard требуют непрозрачную иконку);
- превью для экрана выбора: `Assets.xcassets/AppIconPreview<Name>.imageset/preview.png` (180×180) для **всех шести** вариантов, включая светлую и тёмную.

Превью нужны отдельными картинками, потому что наборы `.appiconset` нельзя показать через `Image(...)`.

Каркас сцены:
```python
def compose(background):
    canvas = background.copy()
    mascot = MASCOT.resize(MASCOT_SIZE, Image.LANCZOS)
    shadow = Image.new('RGBA', SIZE_2D, (0, 0, 0, 0))
    shadow.paste((0, 0, 0, SHADOW_ALPHA), MASCOT_OFFSET_SHADOW, mascot.split()[3])
    canvas.alpha_composite(shadow.filter(ImageFilter.GaussianBlur(SHADOW_BLUR)))
    canvas.alpha_composite(mascot, MASCOT_OFFSET)
    return canvas.convert('RGB')
```
Перед коммитом я посмотрю сгенерированные PNG и при необходимости подправлю цвета.

## 2. Код

**`domain/models/AppIcon.swift`:**
```swift
nonisolated enum AppIcon: String, CaseIterable, Hashable, Sendable {
    case standard
    case dark
    case sunset
    case night
    case ocean
    case lime
}
```

**`data/local/UIApplicationAppIconRepository.swift`** сопоставляет вариант с именем набора. `nil` — основная иконка:
```swift
private static func iconName(for icon: AppIcon) -> String? {
    switch icon {
    case .standard:
        return nil
    case .dark:
        return "AppIconDark"
    case .sunset:
        return "AppIconSunset"
    case .night:
        return "AppIconNight"
    case .ocean:
        return "AppIconOcean"
    case .lime:
        return "AppIconLime"
    }
}

var current: AppIcon {
    let name = UIApplication.shared.alternateIconName
    return AppIcon.allCases.first { return Self.iconName(for: $0) == name } ?? .standard
}
```

**`presentation/profile/states/AppIcon+Style.swift`:** `title` (строки ниже) и `preview: ImageResource` (`.appIconPreviewStandard` и т. д.). `systemImage` больше не нужен.

**Экран выбора** — новый компонент `presentation/profile/ui/AppIconPicker.swift`. Это сетка 3 колонки внутри строки секции «Иконка приложения»: превью со скруглением как у иконки на домашнем экране, под ним название. У выбранной иконки обводка `Forest` и галочка.
```swift
struct AppIconPicker: View {
    private static let iconSize: CGFloat = 64
    private static let iconCornerRatio: CGFloat = 0.225
    private static let selectionLineWidth: CGFloat = 3
    private static let columnCount = 3

    let selected: AppIcon
    let onSelect: (AppIcon) -> Void

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: Self.columnCount), spacing: Spacing.medium) {
            ForEach(AppIcon.allCases, id: \.self) { icon in
                Button {
                    onSelect(icon)
                } label: {
                    VStack(spacing: Spacing.xSmall) {
                        Image(icon.preview)
                            .resizable()
                            .frame(width: Self.iconSize, height: Self.iconSize)
                            .clipShape(.rect(cornerRadius: Self.iconSize * Self.iconCornerRatio, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: Self.iconSize * Self.iconCornerRatio, style: .continuous)
                                    .stroke(icon == selected ? Palette.forest : .clear, lineWidth: Self.selectionLineWidth)
                            }
                        Text(icon.title)
                            .font(.caption)
                            .foregroundStyle(icon == selected ? Palette.forest : Color.primary)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(icon == selected ? .isSelected : [])
            }
        }
        .padding(.vertical, Spacing.small)
    }
}
```
`ProfileScreen`: секция «Иконка приложения» вместо шести строк содержит одну строку `AppIconPicker(selected:onSelect:)`. Метод `appIconRow` удаляется.

## 3. Строки (ru / be / en)
`app_icon_sunset` — «Закат» / «Захад» / «Sunset»
`app_icon_night` — «Ночь» / «Ноч» / «Night»
`app_icon_ocean` — «Океан» / «Акіян» / «Ocean»
`app_icon_lime` — «Лайм» / «Лайм» / «Lime»
Плюс существующие `app_icon_standard` («Светлая»), `app_icon_dark` («Тёмная»).

## 4. Документация
- `CLAUDE.md` → Icons: список разрешённых imageset дополняется `AppIconPreview*` (превью для выбора иконки), а список наборов иконок — `AppIconSunset`, `AppIconNight`, `AppIconOcean`, `AppIconLime`. Плюс упоминание `scripts/app-icons.py` для перегенерации.
- Спека, раздел 7 и Android backlog: «Профиль → блок `app_icon`: сетка превью из шести иконок (светлая, тёмная, закат, ночь, океан, лайм)».

## Проверка
```bash
python3 scripts/app-icons.py
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
```
- Смотрю сгенерированные иконки (Read на PNG) до коммита.
- Проверяю, что все пять альтернативных наборов попали в сборку: в `Info.plist` собранного `.app` должны быть `CFBundleAlternateIcons` с `AppIconDark`, `AppIconSunset`, `AppIconNight`, `AppIconOcean`, `AppIconLime`.

Ручная проверка (вы): Профиль → «Иконка приложения» — шесть превью в сетке, выбранная обведена. Нажатие на «Закат» → системное уведомление, на домашнем экране иконка «Закат». Возврат на «Светлую» — основная иконка.
