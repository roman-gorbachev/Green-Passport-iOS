# История правок постов форума и новая тёмная тема

## Контекст

1. **История постов.** Правка перезаписывает `text`, удаление стирает его, прежние версии нигде не хранятся. Модератор в админке не видит, что было написано до правки или удаления. Так можно спрятать нарушение, на которое уже пожаловались. Решение — история версий на сервере, видимая только модераторам.
2. **Тёмная тема (iOS и Android).** Претензии пользователя: чёрный фон скучный, нет акцентов, нет фирменного зелёного, карточки сливаются с фоном, акценты тусклые. Причины:
   - фон экрана — чистый `#000000`, карточки — нейтральный серый `#1C1C1E`, без намёка на зелёный;
   - `Forest` в тёмной теме `#2E8C5E` тусклый на почти чёрном;
   - подложки плиток `MintSurfaceHigh #32443A` серые;
   - на iOS фоны берутся из системных `systemGroupedBackground` / `secondarySystemGroupedBackground`, поэтому своих цветов у них нет вообще.

Первым действием план копируется в `claude/forum-history-dark-theme-plan.ru.md` обоих приложений и админки.

---

## Часть 1. История правок постов форума

### 1.1 Данные

Подколлекция `posts/{postId}/revisions/{autoId}`:

| Поле | Тип | Что |
|---|---|---|
| `text` | string | текст до изменения |
| `kind` | `EDIT` \| `DELETE` | что произошло |
| `changedAtEpochMillis` | int | когда (для правки — `editedAtEpochMillis`, для удаления — время триггера) |
| `authorId` | string | автор поста |

Пишет только сервер. Клиенты приложений историю не читают и не меняют.

### 1.2 Функция (`functions/src/community/triggers.ts`)

`onForumPostUpdated` уже реагирует на правку и удаление. Перед своей текущей работой он сохраняет прежний текст:
```ts
async function saveRevision(before: DocumentSnapshot, after: DocumentSnapshot): Promise<void> {
  const previousText = String(before.get('text') ?? '');
  const isDeletion = becameDeleted(before, after);
  const isEdit = !isDeletion && after.get('text') !== previousText;
  if (!previousText || (!isEdit && !isDeletion)) return;
  await before.ref.collection('revisions').add({
    text: previousText,
    kind: isDeletion ? 'DELETE' : 'EDIT',
    changedAtEpochMillis: Number(after.get('editedAtEpochMillis') ?? Date.now()),
    authorId: String(before.get('authorId') ?? ''),
  });
}
```
Решение «правка это или удаление» — чистая функция `revisionKind(before, after)` в `chatPayload.ts` с unit-тестом (правка, удаление, смена только служебных полей вроде `hidden`/`reportCount` → без записи).

`moderateContent` с действием `delete` удаляет пост вместе с историей: `db.recursiveDelete(postRef)` вместо `postRef.delete()`. Иначе останутся «осиротевшие» версии.

### 1.3 Правила (`firestore.rules`)

Общее правило для подколлекций сейчас открывает их на чтение всем вошедшим. Историю нужно закрыть:
```
match /apps/greenpassport/posts/{postId}/revisions/{revisionId} {
  allow read: if isAdmin();
  allow write: if false;
}

match /apps/greenpassport/{collection}/{docId}/{subcollection}/{rest=**} {
  allow read: if request.auth != null && !isClosedCollection(collection) &&
    !(subcollection in ['codePool', 'revisions']);
  allow write: if false;
}
```
Тесты в `rules-tests/rules.test.js`:
- пользователь, даже автор поста, не читает `revisions`;
- модератор читает;
- никто не пишет.

### 1.4 Админка (`greenpassport-admin`)

- `src/domain/moderation.ts`: `PostRevision { id, text, kind, changedAtEpochMillis }` и `decodePostRevision`, с тестом в существующем наборе vitest.
- `ReportsPage.tsx`: в карточке поста под текстом сворачиваемый блок «История изменений (N)». Его компонент `PostRevisions` подписывается на `posts/{id}/revisions` по `changedAtEpochMillis desc`. Строка: дата, бейдж «Изменено» / «Удалено автором», прежний текст с переносами. Блок не показывается, если версий нет.
- Удалённый автором пост: под плашкой «Удалено автором» сразу виден удалённый текст из последней версии `DELETE`.

### 1.5 Спека

Раздел модерации: «Правки и удаления постов форума сервер сохраняет в закрытую историю (`posts/{id}/revisions`). Её видят только модераторы в веб-админке. Удаление модератором стирает пост вместе с историей».

### 1.6 Деплой (после вашего «да»)
```bash
cd ~/Personal/greenpassport-android
firebase deploy --only firestore:rules,functions:onForumPostUpdated,functions:moderateContent
cd ~/Personal/greenpassport-admin && npm run build && firebase deploy --only hosting
```
История начнёт копиться с момента деплоя. Прежние правки и удаления восстановить нельзя.

---

## Часть 2. Тёмная тема: «лесная ночь»

Идея: фон и карточки не нейтрально-серые, а очень тёмные зеленоватые. Акцент — более яркий изумрудный, крупные зелёные поверхности — глубокий лесной зелёный, на котором ярко смотрится лайм. **Светлая тема не меняется:** все новые токены в светлом режиме равны текущим значениям.

### 2.1 Токены (одинаковые имена и значения на обеих платформах)

| Токен | Светлая (как сейчас) | Тёмная: было → станет | Где |
|---|---|---|---|
| `ScreenBackground` | `#F2F2F7` | `#000000` → `#08120D` | фон экранов, шторок |
| `CardBackground` | `#FFFFFF` | `#1C1C1E` → `#13211A` | карточки, строки списков |
| `FieldBackground` | iOS `tertiarySystemFill`, Android `#E5E5EA` | `#2C2C2E` → `#1C2E24` | поля ввода |
| `Separator` | `#C6C6C8` | `#38383A` → `#22362B` | разделители |
| `SecondaryText` | iOS `secondaryLabel`, Android `#8A8A8E` | `#98989F` → `#8FA598` | второстепенный текст |
| `Forest` | `#1F6B47` | `#2E8C5E` → `#34A86E` | акцент: иконки, ссылки, кнопки, выбранное |
| `ForestDeep` (новый) | `#1F6B47` | `#17553A` | большие зелёные плашки: карточка прогресса, купон, обложка совета без фото |
| `MintSurface` | `#E6F5EC` | `#1E2A24` → `#16271E` | мягкие подложки |
| `MintSurfaceHigh` | `#C9E6D3` | `#32443A` → `#1E3D2C` | плитки иконок |

`Lime`, `OnLime`, `OnForest`, цвета разделов (`Section*`) не меняются.

Контраст:
- `Forest #34A86E` на карточке `#13211A` — около 6:1;
- белый текст на `#34A86E` — около 3:1, этого хватает для текста кнопок (жирный, крупный);
- лайм на `ForestDeep #17553A` — около 7:1.

### 2.2 Акценты, которых не хватало (только тёмная тема)

- **Карточка прогресса** (Главная, Профиль, Магазин) переходит на `ForestDeep` и в тёмной теме получает мягкое зелёное свечение: тень `Forest` с прозрачностью 0.35 и радиусом 20. Она выделяется на тёмном фоне, а не проваливается в него.
- **Плитки быстрых действий и иконок** — на насыщенном `MintSurfaceHigh` с изумрудной иконкой `Forest` (уже так устроены, станут заметнее за счёт новых значений).

### 2.3 iOS

1. **Color sets.** В `Assets.xcassets` добавляются `ScreenBackground`, `CardBackground`, `FieldBackground`, `Separator`, `SecondaryText`, `ForestDeep`. Светлые варианты равны системным цветам. Меняются тёмные варианты `Forest`, `AccentColor` (= `Forest`), `MintSurface`, `MintSurfaceHigh`.
2. **`Palette`** читает фоны и второстепенный текст из этих color sets вместо системных:
   ```swift
   static let screenBackground = Color(.screenBackground)
   static let cardBackground = Color(.cardBackground)
   static let fieldBackground = Color(.fieldBackground)
   static let separator = Color(.separator)
   static let secondaryText = Color(.secondaryText)
   static let forestDeep = Color(.forestDeep)
   ```
3. **Списки.** `List` и `Form` рисуют системные фоны сами, поэтому общий модификатор `presentation/components/View+ThemedList.swift`:
   ```swift
   extension View {
       func themedListBackground() -> some View {
           return scrollContentBackground(.hidden)
               .background(Palette.screenBackground)
       }

       func themedRowBackground() -> some View {
           return listRowBackground(Palette.cardBackground)
               .listRowSeparatorTint(Palette.separator)
       }
   }
   ```
   `themedListBackground()` ставится на каждый `List`/`Form`: «Сообщество», архив, форум, отзывы, профиль, история, уведомления, избранное, задания, фильтры, модерация, пересылка, участники группы. `themedRowBackground()` — на их секции и строки.
4. **Шторки.** У всех `.sheet` (задание, событие, купон, серия, точка карты, фильтры, пересылка, участники) появляется `.presentationBackground(Palette.screenBackground)`. Без этого системный фон шторок останется серым.
5. **`Color(.tertiaryLabel)`** у шевронов меняется на `Palette.secondaryText.opacity(…)` — `private static let`.
6. **Карточка прогресса** (`ProgressHeroCard`) переходит на `Palette.forestDeep.gradient` и получает свечение в тёмной теме:
   ```swift
   .shadow(color: colorScheme == .dark ? Palette.forest.opacity(Self.glowOpacity) : .clear, radius: Self.glowRadius)
   ```
   Купон (`CouponDetailScreen`), обложка совета (`ArticleCoverImage`) и запасная плитка игры тоже переходят на `forestDeep`.

### 2.4 Android

1. **`core/designsystem/theme/Color.kt`.** Новые тёмные значения. `ForestDeep` добавляется в новый `BrandColors` (по образцу `SectionColors`), а через `GreenPassportTheme.brandColors` его получают карточка прогресса, купон и обложка:
   ```kotlin
   data class BrandColors(val forestDeep: Color, val heroGlow: Color)

   val LightBrandColors = BrandColors(forestDeep = Color(0xFF1F6B47), heroGlow = Color.Transparent)
   val DarkBrandColors = BrandColors(forestDeep = Color(0xFF17553A), heroGlow = Color(0x5934A86E))
   ```
2. **Тёмная схема** — те же значения: `background = ScreenBackgroundDark`, `surface…` = `CardBackgroundDark`, `surfaceVariant` = `FieldBackgroundDark`, `outlineVariant` = `SeparatorDark`, `onSurfaceVariant` / `outline` = `SecondaryTextDark`, `primary` = `ForestDark`, `surfaceContainerHigh` / `surfaceContainerHighest` = мятные.
3. **`ProgressHeroCard`** (core) рисуется на `brandColors.forestDeep` и получает свечение `Modifier.shadow(elevation, shape, ambientColor = heroGlow, spotColor = heroGlow)`. Купон и обложка совета — тоже `forestDeep`.
4. Шапки с Haze и нижняя панель используют `background`, поэтому их стекло автоматически становится зеленоватым.

### 2.5 Спека

Раздел 3 «Токены цвета» получает новые тёмные значения, строки `CardBackground`, `FieldBackground`, `Separator`, `SecondaryText`, `ForestDeep` и абзац «Тёмная тема — зеленоватая, не нейтрально-серая; карточка прогресса светится».

---

## Порядок и коммиты
1. Бэкенд: функция, тест, правила, тесты правил, спека → коммит Android. Деплой — после вашего «да».
2. Админка: история в карточке поста → коммит, деплой хостинга вместе с бэкендом.
3. iOS: тёмная тема → коммит.
4. Android: тёмная тема → коммит.

## Проверка
```bash
cd ~/Personal/greenpassport-android/functions && npm run lint && npm test
cd ~/Personal/greenpassport-android && firebase emulators:exec --only firestore,storage "npm --prefix rules-tests test"
cd ~/Personal/greenpassport-admin && npm test && npm run build
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
cd ~/Personal/greenpassport-android && ./gradlew assembleDebug detektAll
```
iOS-симулятор, тёмная тема (Профиль → Тема → Тёмная): скриншоты Главной, «Сообщества», форума, профиля, магазина и шторки задания для сравнения «до/после». Делаю сам через `xcrun simctl io booted screenshot`, насколько позволяет вход в симуляторе. Остальное проверяете вы.

Ручные сценарии:
1. История: изменить пост → в админке у поста «История изменений (1)» с прежним текстом. Удалить пост → «Удалено автором» и удалённый текст. Модератор удаляет пост → история удаляется вместе с ним. Обычный пользователь историю прочитать не может (тест правил).
2. Тёмная тема на обеих платформах: фон тёмно-зелёный, карточки отделяются от фона, иконки и ссылки изумрудные, карточка прогресса светится. Шторки и списки без серых пятен. Светлая тема выглядит как раньше.
