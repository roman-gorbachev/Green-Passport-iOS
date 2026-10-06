# Глобальный план развития Green Passport

> Сейчас не реализуется. После одобрения план сохраняется как `claude/product-roadmap-plan.ru.md` в iOS- и Android-репозиториях. Каждый этап перед стартом уточняется отдельным детальным планом.

## Контекст

Ядро продукта готово:
- задания, события, очки, XP и серия;
- магазин купонов, карта, советы, игры;
- сообщество, уведомления, админка.

Анализ показал, чего не хватает:
- присутствия вне приложения (виджеты, ярлыки);
- снятия ручной работы с модераторов;
- видимого смысла очков и соревновательности;
- «вау»-функции для продвижения.

Выбраны четыре направления, ИИ — **Gemini через Vertex AI**. Вызовы только из Cloud Functions, в приложения ключи не попадают.

Подписку сознательно не делаем: она противоречит модели массового городского участия, на iOS требует платного Apple Developer Program (In-App Purchase) и отдаёт 15–30% Apple. Монетизация — B2B через партнёров и корпоративные челленджи (вне этого плана).

Порядок этапов — от дешёвого и независимого к тяжёлому:
1. Виджеты и ярлыки.
2. ИИ-проверка фото заданий.
3. Эко-вклад и рейтинги.
4. «Куда выбросить?».

Правила для каждого этапа как в репозиториях:
- сначала `claude/ux-spec.ru.md` (обе копии);
- затем бэкенд (Android-репо: `functions/`, `firestore.rules`, тесты правил), деплой только после подтверждения;
- затем iOS, затем Android;
- в конце `CLAUDE.md` обоих репозиториев;
- строки во всех трёх языках, никаких комментариев в коде, именованные константы.

---

## Этап 1. Виджеты и ярлыки

**Зачем:** напоминание об очках, серии и ближайшем событии без открытия приложения, быстрый вход в сканер QR. Бэкенд не меняется.

### 1.1 Общие данные для виджетов
Виджет не должен ходить в Firestore сам (нет сессии, лимиты обновлений). Приложение пишет снимок при каждом обновлении кошелька и событий:
```swift
nonisolated struct WidgetSnapshot: Codable, Sendable {
    let points: Int
    let level: Int
    let levelProgress: Double
    let streakDays: Int
    let isStreakCountedToday: Bool
    let nextEventTitle: String?
    let nextEventStartAt: Date?
    let updatedAt: Date
}
```
- **iOS:** `WidgetSnapshotStore` пишет JSON в контейнер App Group `group.com.smartcity.greenpassport` и вызывает `WidgetCenter.shared.reloadAllTimelines()`. Источники — `HomeViewModel` (кошелёк, серия) и `CalendarViewModel` / ближайшее событие.
  - ⚠️ **Ограничение:** App Groups не поддерживаются бесплатной командой разработчика. Расширение с виджетом соберётся, но на устройство с App Group установится только с платным аккаунтом. До его появления этап на iOS — только ярлыки (1.3) и кнопка в Пункте управления, а виджет делается, когда аккаунт будет.
- **Android:** `WidgetSnapshotRepository` в DataStore (core). Glance-виджет читает его через `GlanceStateDefinition`, обновление через `GlanceAppWidget.updateAll(context)` из тех же мест.

### 1.2 Виджеты
- **«Мой прогресс»** (маленький): уровень, очки с молнией Lime, полоса XP, огонёк серии. Если сегодня ещё не засчитано, огонёк серым и подпись `widget_streak_pending`.
- **«Ближайшее событие»** (средний): название, дата и время, кнопка-ссылка в шторку события.
- Тёмная тема — токены «лесной ночи». Нажатие открывает приложение по ссылке `greenpassport://home` / `greenpassport://event/{id}`.

iOS — новое расширение `GreenPassportWidgets` (WidgetKit, SwiftUI):
```swift
struct ProgressWidget: Widget {
    private static let kind = "ProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            ProgressWidgetView(snapshot: entry.snapshot)
                .containerBackground(Palette.forestDeep.gradient, for: .widget)
        }
        .configurationDisplayName(Text(.widgetProgressTitle))
        .supportedFamilies([.systemSmall])
    }
}
```
Android — `feature/widgets` (новый модуль) с `ProgressWidget : GlanceAppWidget` и `ProgressWidgetReceiver`, регистрация в манифесте модуля.

### 1.3 Ярлыки и быстрые действия
- **iOS:** App Intents.
  - `OpenQrScannerIntent` открывает сканер, `ShowPointsIntent` отвечает «У вас N очков» в Siri и Spotlight. Работают и без App Group: интент запускает приложение или берёт значение из `UserDefaults` основного приложения.
  - `AppShortcutsProvider` с фразами на русском, белорусском и английском.
  - Кнопка в Пункте управления (iOS 18, `ControlWidget`) «Сканировать QR» — тоже часть расширения виджетов.
- **Android:**
  - статические ярлыки в `res/xml/shortcuts.xml` («Сканировать QR», «Календарь», «Задания»), подключаются к каждому `activity-alias` иконки через `<meta-data android:name="android.app.shortcuts">`;
  - плитка быстрых настроек `QrScannerTileService` («Сканер QR»).
- **Глубокие ссылки:** схема `greenpassport://` (`scan`, `calendar`, `tasks`, `event/{id}`). iOS — `onOpenURL` в `RootRoute` → `AppRouter`. Android — intent-filter на `MainActivity` → `pendingChatId`-подобный механизм `pendingDeepLink` в `GreenPassportAppShell`.

### Проверка этапа
- Сборки.
- Добавить виджеты на рабочий стол: значения совпадают с Главной и обновляются после выполнения задания.
- Ярлык «Сканировать QR» открывает сканер.
- Siri: «Сколько у меня очков в Зелёном паспорте».
- Плитка в шторке Android.

---

## Этап 2. ИИ-проверка фото заданий

**Зачем:** сейчас каждое фото-задание вручную проверяет модератор (`reviewSubmission`). Модель сама одобряет очевидные случаи и отклоняет явный мусор, а спорные оставляет человеку.

### 2.1 Сервер
Расширяем существующий триггер `screenSubmissionPhoto` (`functions/src/moderation/triggers.ts`): после проверки безопасности Cloud Vision вызываем Gemini (Vertex AI, `@google-cloud/vertexai`, модель `gemini-2.5-flash`, регион `europe-central2` или ближайший доступный).
```ts
interface PhotoVerdict {
  decision: 'APPROVE' | 'REJECT' | 'UNSURE';
  confidence: number;
  reason: string;
}

async function judgePhoto(task: TaskForReview, photoUri: string): Promise<PhotoVerdict> {
  const model = vertex.getGenerativeModel({
    model: GEMINI_MODEL,
    generationConfig: { responseMimeType: 'application/json', responseSchema: PHOTO_VERDICT_SCHEMA, temperature: 0 },
  });
  const result = await model.generateContent({
    contents: [{
      role: 'user',
      parts: [
        { text: photoReviewPrompt(task.title, task.description) },
        { fileData: { mimeType: 'image/jpeg', fileUri: photoUri } },
      ],
    }],
  });
  return parseVerdict(result.response);
}
```
Правила решения — чистая функция `aiDecision(verdict)` с unit-тестами:
- `APPROVE` и `confidence ≥ 0.85` → одобрить автоматически. Используется та же транзакция, что в `reviewSubmission`, вынесенная в общую `approveSubmission(tx, submission, reviewer)`; `reviewedBy: 'ai'`.
- `REJECT` и `confidence ≥ 0.9` → отклонить с причиной `ai_rejected` и коротким пояснением модели.
- Иначе → `PENDING` с полями `aiDecision`, `aiReason` для модератора.

Дополнительно:
- Пороги — константы в `config.ts`.
- Флаг в документе задания `aiReviewEnabled` (по умолчанию true) позволяет выключить ИИ для отдельного задания из админки.
- Защита от промпт-инъекций: текст на фото — данные, а не инструкции (явно в промпте). Решение «одобрить» доступно только с высокой уверенностью.
- Ограничение затрат: не больше N вызовов на пользователя в сутки (`dailyCounters`); при превышении — сразу модератору.
- В эмуляторе модель не вызывается (как сейчас Cloud Vision).

### 2.2 Клиенты
- В шторке задания для статуса «на проверке» ничего не меняется, для «отклонено ИИ» — причина `photo_rejected_by_ai_msg` и кнопка «Отправить другое фото».
- Модерация (приложения и админка): у спорных фото бейдж «ИИ: не уверен» и пояснение модели. Фильтр «Решено ИИ» показывает автоматические решения для выборочной проверки и отмены.

### 2.3 Правила и данные
Поля `aiDecision`, `aiReason`, `reviewedBy: 'ai'` пишет только сервер; клиентское правило создания запрещает их задавать. Включение Vertex AI API в проекте `chatroom-85fb8` и роль `aiplatform.user` для сервисного аккаунта функций.

### Проверка этапа
- Unit-тесты `aiDecision`.
- Тесты правил.
- Ручные сценарии на эмуляторе: модель подменяется заглушкой; уверенное «да», уверенное «нет», «не уверен».
- На проде: 20 реальных фото, сверка с решениями модератора до включения автоматического одобрения. Сначала режим «только подсказка», затем автоодобрение.

---

## Этап 3. Эко-вклад и рейтинги

**Зачем:** очки становятся понятным результатом («сдал 12 кг пластика»), а соревнование по городу и в группах удерживает пользователей.

### 3.1 Эко-вклад
- **Данные:** у задания и события в админке новое поле `impact { kind, amount }`, где `kind` ∈ `PLASTIC_KG | PAPER_KG | BATTERIES | TREES | CO2_KG | WASTE_KG`. Для CO₂ — коэффициенты в `config.ts`.
- **Сервер:** `award()` дополнительно увеличивает `users/{uid}/stats/impact` (`FieldValue.increment` по виду). Сюда же — недельные и месячные агрегаты для рейтингов (3.2).
- **Клиенты:** в профиле карточка «Мой вклад»: плитки по видам с иконками и числами, а также «Поделиться» — картинка-открытка (iOS `ImageRenderer`, Android `GraphicsLayer` → bitmap) через системный шаринг.

### 3.2 Рейтинги
- **Сервер:** в той же транзакции `award()` очки периода пишутся в `leaderboards/{period}_{scope}/entries/{uid}`:
  - `period` — `week-2026-41` / `month-2026-10`;
  - `scope` — `city-Минск` или `group-{id}`.

  Плановая функция раз в час собирает топ-50 в документ `leaderboards/{id}` (чтение одним запросом), а «моё место» считает агрегатом `count()` с `points > myPoints`.
- **Приватность:** `users/{uid}.leaderboardVisible` (по умолчанию true). Скрытые пользователи не попадают в топ, но видят своё место. Имя в рейтинге — имя из профиля или «Участник №…».
- **Клиенты:** экран «Рейтинг» с Главной и из профиля. Переключатели «Неделя / Месяц» и «Мой город / Мои группы». Топ-10 и закреплённая строка «Вы — 23 место».
- **Групповые челленджи:** у группы поле `challenge { goalTasks, endsAt, progress }`, создаёт владелец группы. Прогресс увеличивает `award()`, если пользователь в группе. В чате группы — плашка с прогресс-баром. При достижении цели всем участникам бонус (callable `claimChallengeBonus` — один раз, идемпотентно).

### 3.3 Правила
- `leaderboards`, `stats` — чтение для вошедших, запись только сервером.
- `challenge` у группы меняет только владелец, а `progress` — только сервер.
- Тесты правил.

### Проверка этапа
- Unit-тесты подсчёта периода и места.
- Выполнение задания с `impact` увеличивает вклад и строку рейтинга.
- Скрытый пользователь не виден в топе.
- Челлендж группы достигается, бонус начисляется один раз.

---

## Этап 4. «Куда выбросить?»

**Зачем:** помочь правильно сортировать (частая боль) и показать ближайший пункт приёма. Хорошая функция для продвижения.

### 4.1 Сервер
Callable `identifyWaste` (`europe-central2`):
- принимает фото (загрузка в `Storage` во временную папку `waste/{uid}/…` с правилом «удалить через сутки») или base64 до 1 МБ;
- Gemini возвращает структурированный ответ:
```ts
interface WasteAnswer {
  material: 'PLASTIC' | 'PAPER' | 'GLASS' | 'METAL' | 'BATTERY' | 'ELECTRONICS' | 'ORGANIC' | 'MIXED' | 'UNKNOWN';
  plasticCode: number | null;
  bin: 'YELLOW' | 'BLUE' | 'GREEN' | 'SPECIAL' | 'GENERAL';
  tip: { ru: string; be: string; en: string };
  confidence: number;
}
```
- Лимит вызовов на пользователя в сутки. Без очков: сортировка — справочная функция, а не способ фарма.

### 4.2 Карта пунктов
У точек карты `RECYCLING_POINT` новое поле `accepts: Material[]`, заполняется в админке. Ответ сопоставляется с ближайшими точками, принимающими этот материал (расстояние от геопозиции, как в `ResolveMapFocusUseCase`).

### 4.3 Клиенты
- **Вход:** быстрое действие на Главной (шестая плитка или замена на «Сортировка») и ярлык из этапа 1.
- **Экран:** камера (iOS — `UIImagePickerController` / `PhotosPicker`, Android — `TakePicture`, как в фото-заданиях) → индикатор → карточка:
  - материал и код пластика;
  - цветной бак (`SectionColor` для баков уже есть);
  - совет;
  - «Ближайшие пункты» со ссылкой на карту с фильтром.
- При низкой уверенности — «Не уверены» и ссылка на эко-совет о маркировке.
- **Симулятор** (камеры нет): только выбор из галереи, как сейчас в заданиях.

### Проверка этапа
- Unit-тесты разбора ответа.
- 30 тестовых фото (бутылка PET, банка, батарейка, коробка, смешанное): правильный бак не менее чем в 85% случаев.
- Ближайшие пункты сортируются по расстоянию.
- Лимит запросов работает.

---

## Сводка зависимостей и рисков

| Риск | Где | Решение |
|---|---|---|
| Нет платного Apple Developer Program | 1 (виджеты iOS), push на iOS | ярлыки и Siri без App Group; виджет после покупки аккаунта |
| Стоимость Gemini | 2, 4 | Flash-модель, суточные лимиты, «только подсказка» на старте |
| Ошибки ИИ | 2 | высокие пороги, выборочный аудит в админке, отмена решения |
| Накрутка рейтингов | 3 | очки только с сервера (уже так), лимиты заданий в сутки уже есть |
| Приватность в рейтингах | 3 | скрытие себя, псевдоним |

## Общая проверка в конце каждого этапа
```bash
xcodebuild -project "Green Passport.xcodeproj" -scheme "Green Passport" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Simulator' build
cd ~/Personal/greenpassport-android && ./gradlew assembleDebug detektAll && ./gradlew test
cd functions && npm run lint && npm test
firebase emulators:exec --only firestore,storage "npm --prefix rules-tests test"
```
Плюс ручные сценарии этапа на устройствах и обновлённая спека в обоих репозиториях.
