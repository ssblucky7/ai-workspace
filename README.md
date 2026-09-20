# AI Workspace

A Flutter + Firebase academic assignment application for managing AI conversations with user-configured, OpenAI-compatible AI providers.

> **Original work.** AI Workspace is not affiliated with, and does not copy the trademarks, logos, wording, or interfaces of, ChatGPT, Gemini, Copilot, or any other AI vendor. All branding, colors, and interactions are original designs for this project.

---

## 1. Project overview

AI Workspace lets an authenticated user:

- create and manage **AI conversations** (the assignment's CRUD resource),
- configure their own **OpenAI-compatible AI providers** (base URL, API key stored locally, model, temperature, token limit),
- send messages and receive AI replies through a configurable provider,
- switch between **light and dark themes** instantly with the choice persisted,
- and have all data stored in **Cloud Firestore** under their own account path, protected by security rules.

**Supported targets:** Android and Web. (iOS/macOS/Windows/Linux folders were intentionally removed per project scope.)

**Organization identifier:** `com.aiworkspace.app` (Android `applicationId`, web app id). To change it: update `android/app/build.gradle.kts` → `applicationId`, then re-run `flutterfire configure` with the new identifiers so `lib/firebase_options.dart` matches.

---

## 2. Assignment objective

Demonstrated, end-to-end:

| # | Requirement | Where |
|---|---|---|
| 1 | Firebase Authentication (Email/Password) | `lib/services/auth_service.dart` |
| 2 | Sign Up / Sign In / Forgot Password / Sign Out flows | `lib/screens/auth/` |
| 3 | Persistent authentication state | Firebase session + `AppAuthProvider.authStateChanges` |
| 4 | Protected screens | `lib/core/routing/app_router.dart` (global redirect) |
| 5 | Cloud Firestore real-time operations | `ConversationService.watch*` streams |
| 6 | Complete CRUD | Create/rename/delete conversations, add/resolve/delete messages |
| 7 | UID-scoped data | `FirestorePaths` — everything under `users/{uid}` |
| 8 | Provider state management | `lib/providers/` (5 ChangeNotifiers) |
| 9 | UI / logic / data separation | `screens` → `providers` → `services` → Firestore |
| 10 | Custom light & dark themes | `lib/theme/` |
| 11 | Theme switching without state reset | `ThemeProvider` + `MaterialApp.themeMode` |
| 12 | Persistent theme preference | SharedPreferences |
| 13 | Responsive UI | `lib/widgets/responsive_scaffold.dart` (bottom nav / rail) |
| 14 | Validation & error handling | `lib/core/utils/validators.dart`, `lib/core/errors/` |
| 15 | Null-safe, organized Dart | 0 analyzer issues |
| 16 | Firestore security rules | `firestore.rules` (deployed) |
| 17 | Tests & documentation | 69 tests in `test/`, this README |

---

## 3. Implemented features

- **Authentication** — sign up (full name, email, password, confirm), sign in, forgot-password email, sign out (with confirmation), friendly mapped error messages, password visibility toggles, duplicate-submission guard.
- **Conversations (CRUD)** — real-time list sorted by recency, create with derived title, rename (validated dialog), delete (confirmation + messages cleanup), search/filter, last-message preview, model indicator, formatted timestamps, empty/loading/error states.
- **Chat** — real-time messages, send/receive, typing indicator, auto-scroll, copy message, retry failed response, regenerate last response, clear chat (confirmation), helpful suggestion chips, provider-not-configured notice that keeps the user's message saved.
- **AI providers** — add/edit/delete providers, masked API key display (`sk-••••••1234`), secure storage (never Firestore), test connection, fetch models from `{baseUrl}/models`, searchable model selection, manual model entry, exactly-one-active-provider.
- **Theming** — Material 3, custom warm-light & charcoal-dark palettes, system/light/dark choice, persisted.
- **Responsive** — phone bottom NavigationBar; tablet/desktop NavigationRail; keyboard-safe composer.
- **Navigation** — GoRouter push/pop back stack: the Android system back button (and app-bar back arrows) return to the previous screen instead of closing the app; the app only exits from root screens. Intentional stack resets happen only after sign-in/sign-up and on tab switches; the transient `/chat/new` page is *replaced* by `/chat/{id}` once the first message creates the conversation (see §9.1).

**Out of scope (marked "coming soon" in About screen, not implemented):** image/audio/video generation, real-time voice or video calls, internet search, web scraping, MCP servers/tools/skills, tool calling, document analysis, multi-agent workflows, local models, RAG, file attachments.

---

## 4. Technology stack

| Layer | Choice |
|---|---|
| Framework | Flutter 3.44.x, Dart 3.12 (null-safe), Material 3 |
| Auth / DB | Firebase Core 4.x, Firebase Auth 6.x, Cloud Firestore 6.x |
| State | provider 6.x (5 ChangeNotifiers) |
| Routing | go_router 17.x (global auth redirect, push/pop back stack) |
| Persistence | shared_preferences (theme), flutter_secure_storage (API keys) |
| AI HTTP | http 1.x (`/chat/completions`, `/models`) |
| Formatting | intl (timestamps) |
| Testing | flutter_test (69 tests) |

---

## 5. Screens

| Screen | File |
|---|---|
| Splash / init | `lib/screens/splash/splash_screen.dart` |
| Sign in | `lib/screens/auth/sign_in_screen.dart` |
| Sign up | `lib/screens/auth/sign_up_screen.dart` |
| Forgot password | `lib/screens/auth/forgot_password_screen.dart` |
| Home | `lib/screens/home/home_screen.dart` |
| Chat | `lib/screens/chat/chat_screen.dart` |
| All conversations | `lib/screens/conversations/conversation_history_screen.dart` |
| Rename dialog | `lib/screens/conversations/rename_conversation_dialog.dart` |
| AI providers | `lib/screens/providers/ai_providers_screen.dart` |
| Add / edit provider | `lib/screens/providers/add_edit_provider_screen.dart` |
| Model selection | `lib/screens/providers/model_selection_screen.dart` |
| Settings | `lib/screens/settings/settings_screen.dart` |
| Profile | `lib/screens/profile/profile_screen.dart` |
| About | `lib/screens/about/about_screen.dart` |

---

## 6. Architecture

```
UI (screens, widgets)
   │  calls methods / watches state only
Providers (ChangeNotifier)      ← state + orchestration
   │  no Firebase / HTTP inside widgets
Services (AuthServiceBase, ConversationService,
   │   ProviderConfigService, ChatService, SecureStorageService)
Firestore / HTTP / Secure storage   ← data only
```

- **Screens** never import Firebase or HTTP packages.
- **Providers** expose state + methods; they don't show SnackBars/dialogs themselves.
- **Services** map every SDK error into typed, user-safe `AppException`s via `ErrorMapper`.
- **Constructor injection** everywhere; `AuthServiceBase` interface keeps auth testable without Firebase.

---

## 7. Folder structure

```
lib/
├── core/
│   ├── constants/    app_constants.dart, firestore_paths.dart
│   ├── errors/       app_exception.dart, error_mapper.dart
│   ├── routing/      app_router.dart, route_names.dart
│   ├── utils/        validators.dart, date_time_utils.dart, api_key_masker.dart
│   └── widgets/      loading, error view, empty state, confirm dialog
├── models/           app_user, conversation, chat_message, ai_provider_config, ai_model_info
├── services/         auth, conversation, provider_config, chat_service,
│                     openai_compatible_chat_service, secure_storage
├── providers/        AppAuthProvider, ConversationProvider, ChatProvider,
│                     ThemeProvider, AIProviderConfigProvider
├── theme/            app_colors, app_theme, light_theme, dark_theme,
│                     chat_theme_extension
├── screens/          auth/ home/ chat/ conversations/ providers/ settings/ profile/ about/ splash/
├── widgets/          responsive_scaffold, conversation_tile, message_bubble,
│                     message_composer, provider_card, initials_avatar
├── firebase_options.dart   (generated by FlutterFire CLI)
└── main.dart
```

---

## 8. Firestore database structure

```
users/{uid}
  ├─ uid, fullName, email, photoUrl, createdAt, updatedAt
  ├─ conversations/{conversationId}
  │    ├─ id, userId, title, lastMessage, providerId, modelId,
  │    │  createdAt, updatedAt
  │    └─ messages/{messageId}
  │         id, conversationId, role (user|assistant|system),
  │         content, createdAt, status (sending|sent|failed), errorMessage?
  └─ providers/{providerId}
       id, userId, name, baseUrl, apiKeyRef (reference ONLY),
       selectedModel, organizationId?, temperature, maxTokens,
       isActive, createdAt, updatedAt
```

- **Why UID nesting:** every document lives under the signed-in user's UID, so one match block scope (`match /users/{uid}` + `isOwner(uid)`) protects everything; a user physically cannot address another user's path.
- **Why subcollections need explicit rules:** Firestore rules do not cascade into subcollections — each `match` block must be written or access would be denied (secure-by-default).
- **Why API keys are not in Firestore:** anything synced to Firestore is readable by whoever the rules allow, exportable, and visible in the console. Keys live in `flutter_secure_storage` (device Keychain/Keystore), referenced only by `apiKeyRef` metadata; the deployed rules **reject any provider document containing an `apiKey` field**.

---

## 9. Authentication flow

1. `main()` initializes Firebase → builds providers → `AppAuthProvider.start()`.
2. GoRouter's global redirect watches `AppAuthProvider`:
   - initializing → splash,
   - signed out + protected route → `/sign-in`,
   - signed in + auth route → `/home`,
   - redirect is idempotent (no loops).
3. Sign-up: create Auth user → write `users/{uid}` profile (server timestamps) → rollback Auth account if profile write fails.
4. Sign-out: confirm → sign out → all user-scoped providers cleared → back button cannot return (redirect sends to sign-in).

### 9.1 Navigation and the Android back button

Navigation deliberately uses three different GoRouter operations:

| Operation | Used for |
|---|---|
| `context.push(...)` | Going *deeper*: Home/History → Chat, Home → All conversations, Settings → Profile / About / Providers, Providers → Add/Edit → Model selection, Sign In → Sign Up / Forgot Password |
| `context.replace(...)` | Swapping `/chat/new` for `/chat/{id}` once the first message creates the conversation, so the placeholder page never lingers in the back stack |
| `context.go(...)` | Intentional stack resets **only**: after sign-in/sign-up → `/home` (auth screens must not be reachable via back), bottom-bar/rail tab switches, explicit "Home" / "Go to home" actions |

- App-bar back buttons call `pop()` (with a `go()` fallback when the stack is empty), so the Android system back button and gesture always return one screen instead of closing the app; the app exits only from root screens (standard Android behavior).
- The global auth redirect still guards every route: popping back can never show an auth screen to a signed-in user, nor a protected screen to a signed-out one.

---

## 10. CRUD operation mapping

| Operation | Trigger | Service call |
|---|---|---|
| **Create** | "New chat" button / first message | `createConversation` + `addMessage(user)` |
| **Read** | Home/history/chat screens | `watchConversations`, `watchMessages` (real-time) |
| **Update** | Rename dialog / send message | `renameConversation`, `addMessage`, `resolveMessage`, `updatePreview` |
| **Delete** | Delete action (confirm) | `deleteConversation` (messages first, paginated batches), `clearMessages` |

Deletion note: Firestore does **not** cascade-delete subcollections. This app deletes messages client-side in batches of 400 (< 500-op write limit) before the parent document. For very large conversations a trusted backend/Cloud Function would be preferable (see Known limitations).

---

## 11. Provider state-management explanation

| Provider | Responsibility |
|---|---|
| `AppAuthProvider` | auth state, profile, signUp/signIn/signOut/resetPassword, busy/error flags |
| `ConversationProvider` | conversation stream subscription, search filter, CRUD orchestration |
| `ChatProvider` | open conversation, message stream, send/retry/regenerate flow, generation state |
| `AIProviderConfigProvider` | provider configs stream, save/delete/activate, key lookup, connection test, model fetch |
| `ThemeProvider` | ThemeMode + SharedPreferences persistence |

Widgets use `context.watch` for state and `context.read` for actions; `Consumer`/`Selector` localize rebuilds. User-scoped state is cleared on sign-out; subscriptions are cancelled on auth change and dispose.

---

## 12. Light and dark theme behavior

- `ThemeProvider` loads the saved mode **before** `runApp` (no flash).
- Switching calls `setThemeMode` → `notifyListeners` → `MaterialApp.themeMode` rebuilds — **no app state is reset** (auth, conversations, chat, navigation all survive; verified by a widget test).
- Chat bubble colors come from a `ThemeExtension` so no widget hardcodes colors.

---

## 13. Prerequisites

- Flutter SDK 3.44+ (`flutter doctor` passes)
- Android Studio (or VS Code) + Android SDK for the Android target
- A browser for the Web target
- Node.js + Firebase CLI (`npm i -g firebase-tools`) and FlutterFire CLI (`dart pub global activate flutterfire_cli`)
- A Firebase project (free Spark plan is enough)

---

## 14. Setup

### Flutter installation check
```bash
flutter doctor
```

### Firebase project creation
1. Go to https://console.firebase.google.com → **Add project** → name it (this project used `aimchat-15b34`).
2. Enable **Google Analytics** if desired (not required).

### Android Firebase registration
Done automatically by `flutterfire configure` (uses `com.aiworkspace.app`). To verify: Firebase console → Project settings → Your apps → Android app listed with `google-services.json` download (already present at `android/app/google-services.json`).

### Web Firebase registration
Also created by the CLI run above (`ai_workspace (web)` app ID `1:442613986021:web:1cd185e08b9658f051da0c`).

### Enable Email/Password Authentication
⚠️ **Manual step (one click):** Firebase console → **Authentication → Sign-in method → Email/Password → Enable** → Save. The CLI cannot do this.

### Create Cloud Firestore
Already done during this project's rule deploy (database `aimchat-15b34`, region `nam5`). For a new project: console → **Firestore Database → Create database**.

### Install Firebase CLI / FlutterFire CLI
```bash
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
```

### Run flutterfire configure / generate firebase_options.dart
Already done for this project. To redo (e.g. after changing the application ID):
```bash
flutterfire configure --project=aimchat-15b34 \
  --platforms=android,web \
  --android-package-name=com.aiworkspace.app \
  --web-app-id=1:442613986021:web:1cd185e08b9658f051da0c
```
This regenerates `lib/firebase_options.dart`.

### Deploy Firestore rules & indexes
Already deployed from this machine. To redeploy:
```bash
firebase deploy --only firestore:rules,firestore:indexes \
  --project=aimchat-15b34 --config=firebase-deploy.json
```
(`firebase-deploy.json` points the CLI at `firestore.rules` / `firestore.indexes.json`; the FlutterFire-managed `firebase.json` stays untouched.)

### Install Flutter dependencies
```bash
flutter pub get
```

---

## 15. Running the application

```bash
flutter run                 # Android device/emulator
flutter run -d chrome       # Web
flutter build apk --debug   # Android APK
flutter build web --no-tree-shake-icons   # Web release bundle
```

> Windows note: this repo sets `kotlin.incremental=false` and
> `kotlin.compiler.execution.strategy=in-process` in
> `android/gradle.properties` because the project path contains a space,
> which corrupts Kotlin incremental caches on Windows. If you move the
> project to a space-free path you may remove those lines for faster builds.
> The web build uses `--no-tree-shake-icons` because Application Control
> on this machine blocks Flutter's `font-subset.exe`; on unrestricted
> machines plain `flutter build web` works.

---

## 16. Testing the app (manual walkthrough)

1. **Create a test user** — run the app → "Create one" → fill name/email/password (≥6 chars)/confirm → account created, profile written to `users/{uid}`, lands on Home.
2. **Sign in / sign out** — sign out from Settings (confirm) → sign back in; session also survives a full app restart (persistent auth).
3. **CRUD** — Home → "New chat" (Create) → conversation appears in the list (Read) → overflow menu → Rename (Update) → Delete with confirmation (Delete). Open two devices with the same account: list updates in real time.
4. **Configure an AI provider** — Settings → AI provider → Add provider → name, base URL (`https://api.openai.com/v1` or any OpenAI-compatible service, `http://localhost:…` allowed for local development), API key, fetch models → pick a model → save → "Set active".
5. **Test provider connection** — provider card menu → "Test connection" (calls `/models`, reports success/failure).
6. **Fetch and select models** — edit screen's download icon or card menu → searchable model list → select → saved to provider.
7. Send a chat message → AI reply streams back and is persisted; retry/regenerate/clear-chat all work.
8. **Back navigation** — open a conversation, visit Settings/Providers/Chat, then press the Android system back button repeatedly: each press returns to the previous screen, and the app closes only from Home (root).

---

## 17. Security considerations

- Firestore rules deny everything by default; every path requires `request.auth.uid == {uid}` and validates field types/sizes/ownership on write.
- Provider docs with an `apiKey` field are **rejected by the rules** — secrets never sync.
- API keys stored in `flutter_secure_storage` (Android Keystore / web local storage with the plugin's web adapter), always displayed masked (`sk-••••••1234`), never logged, never included in error text.
- `.gitignore` excludes service-account JSONs, `.env`, keystores.
- **Production note:** a client-side key is acceptable for an academic project, but production apps should proxy AI requests through a trusted backend/gateway so the key never ships in the client.

---

## 18. Troubleshooting

| Symptom | Fix |
|---|---|
| "Firebase could not start" screen | Run `flutterfire configure` again; check `lib/firebase_options.dart` exists |
| Sign-in error "Email/password not enabled" | Console → Authentication → enable Email/Password |
| `PERMISSION_DENIED` on writes | Re-deploy rules (§14); check you're signed in as the user who owns the path |
| Gradle build: "Could not close incremental caches" | Keep `kotlin.incremental=false` (space-in-path issue); stop other Gradle daemons (`gradlew --stop` in `android/`) before building |
| Web build: `font-subset.exe` blocked | Use `flutter build web --no-tree-shake-icons` |
| Model fetch 401 | API key wrong/expired; base URL missing `/v1` |
| `objective_c` native-assets failure after changes | The `dependency_overrides` pin in `pubspec.yaml` must stay until SDK update |

---

## 19. Testing commands

```bash
dart format .
flutter analyze     # 0 issues
flutter test        # 69 tests, all passing
```

Test files: validators, provider validators, models/serialization, date-time coercion, API-key masking, OpenAI parser (base-URL normalize, chat completion, model list), ThemeProvider (mocked SharedPreferences), provider-config validation, sign-in widget test (fake auth service), theme-switching widget test, root smoke test. No test requires a live Firebase project.

---

## 20. Screenshots

```
docs/screenshots/          ← add screenshots here
  01-sign-in.png
  02-home.png
  03-chat.png
  04-providers.png
  05-settings-dark.png
```

---

## 21. Known limitations

- Messages subcollection deletion is client-side and batched (400/batch); huge conversations would need a Cloud Function.
- The OpenAI adapter targets the standard `/chat/completions` + `/models` shape; providers with proprietary variations may need a dedicated adapter.
- Web "secure storage" uses the plugin's web implementation, which is less isolated than native Keystore/Keychain.
- AI history sent to the provider is capped to the last 30 messages per request.
- No offline message queueing: failed AI turns are marked `failed` and can be retried manually.

---

## 22. Future enhancements

Image generation · Audio/video generation · Real-time AI voice or video calls · Internet searching · Web scraping · MCP server installation & custom MCP tools · Custom skills · Tool calling · Document analysis (PDF/Word) · Multi-agent workflows · Local AI models · Retrieval-augmented generation (RAG) · File attachments.

These are intentionally out of scope; the `ChatService` abstraction keeps the architecture extensible for them.

---

## 23. Assignment Requirements Mapping

### A. Firebase Integration
| Criterion | Implementation | Evidence |
|---|---|---|
| Email/password registration | `AuthService.signUp` → Auth user + `users/{uid}` profile (rolled back on profile failure) | `lib/services/auth_service.dart` |
| Sign In | `AuthService.signIn` + mapped errors | sign_in_screen.dart |
| Sign Out | `AuthService.signOut` with confirmation, state cleared | settings_screen.dart |
| Forgot Password | `sendPasswordResetEmail`, success notice | forgot_password_screen.dart |
| Persistent auth state | Firebase session + authStateChanges listener | AppAuthProvider.start |
| Protected screens | GoRouter global redirect | app_router.dart |
| Firestore user profiles | `users/{uid}` with server timestamps | auth_service.dart |
| UID-specific records | all paths via `FirestorePaths.users/{uid}/…` | firestore_paths.dart |

### B. CRUD
| Criterion | Implementation |
|---|---|
| Create conversation | `ConversationService.createConversation` (FAB "New chat", first-message auto-create) |
| Read (real-time) | `watchConversations` / `watchMessages` snapshot streams, sorted, live UI |
| Update | `renameConversation` (validated dialog), `addMessage`, `resolveMessage`, `updatePreview`, `lastMessage` maintenance |
| Delete | confirmation dialog → `deleteConversation` (messages first, batched ≤400) |

### C. State Management
Five ChangeNotifiers (Auth, Conversation, Chat, Theme, AIProviderConfig) with constructor-injected services, streams cancelled on auth change/dispose, user state cleared on sign-out, no Firebase/HTTP in widgets.

### D. UI/UX
Material 3 custom light/dark themes, responsive nav (bar/rail), form validation, loading/empty/error states with retry, destructive-action confirmations, masked keys, timestamps, search, suggestions, accessible tooltips/labels.

### E. Security
Deployed UID-scoped rules with field validation, no-secret-in-Firestore enforcement (rules + model + tests), secure storage for keys, `.gitignore` hardening, no secrets in logs/errors.

### F. Testing & Docs
69 unit/widget tests (all passing, no live Firebase needed), 0 analyzer issues, this README with setup/deploy/troubleshooting.

---

*Built as an academic assignment. All branding and code are original.*
