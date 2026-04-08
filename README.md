# SeniorEase

Plataforma de acessibilidade para idosos em ambientes acadêmicos e profissionais.  
Flutter (Web + Mobile) · Firebase · Clean Architecture

## Como rodar

```bash
# Instalar dependências
flutter pub get

# Verifica dispositivos disponíveis
flutter devices

# Rodar no Chrome (web)
flutter run -d chrome --web-port 8080

# Rodar no emulador Android
flutter run -d emulator-5554

# Rodar testes
flutter test

# Rodar testes com cobertura
flutter test --coverage
```

## Configurar Firebase

Os arquivos `lib/firebase_options.dart` e `android/app/google-services.json` não são versionados por segurança. Para gerar localmente:

**Opção A — FlutterFire CLI (recomendado):**

1. Crie um projeto no [Firebase Console](https://console.firebase.google.com)
2. Instale o Firebase CLI: `npm install -g firebase-tools`
3. Faça login: `firebase login`
4. Rode os comandos abaixo:

```bash
# Instalar FlutterFire CLI (se ainda não tiver)
dart pub global activate flutterfire_cli

# Configurar (selecione o seu projeto Firebase)
flutterfire configure
```

**Opção B — Manual:**

1. Copie `lib/firebase_options_template.dart` para `lib/firebase_options.dart`
2. Substitua os placeholders `{{...}}` pelos valores do seu projeto Firebase
3. Baixe o `google-services.json` do Firebase Console (Configurações > Android) e coloque em `android/app/`

### Secrets para CI/CD

No GitHub, vá em **Settings > Secrets and variables > Actions** e crie os seguintes secrets:

| Secret | Descrição |
| --- | --- |
| `FIREBASE_WEB_API_KEY` | API Key do app web |
| `FIREBASE_WEB_APP_ID` | App ID do app web |
| `FIREBASE_ANDROID_API_KEY` | API Key do app Android |
| `FIREBASE_ANDROID_APP_ID` | App ID do app Android |
| `FIREBASE_MESSAGING_SENDER_ID` | Messaging Sender ID |
| `FIREBASE_PROJECT_ID` | Project ID |
| `FIREBASE_AUTH_DOMAIN` | Auth Domain |
| `FIREBASE_STORAGE_BUCKET` | Storage Bucket |
| `FIREBASE_MEASUREMENT_ID` | Measurement ID (web) |
| `GOOGLE_ANDROID_CLIENT_ID` | OAuth client_id do Android (client_type 1) |
| `GOOGLE_WEB_CLIENT_ID` | OAuth client_id Web (client_type 3) |
| `ANDROID_CERT_HASH` | SHA-1 do keystore de debug Android |

## Convenção de Commits

| Prefixo | Uso |
| --- | --- |
| `feat:` | Nova funcionalidade |
| `fix:` | Correção de bug |
| `refactor:` | Refatoração sem mudança de comportamento |
| `style:` | Mudanças visuais sem lógica |
| `test:` | Adição ou correção de testes |
| `chore:` | Tarefas de manutenção, configs |
| `ci:` | Mudanças em CI/CD |
| `docs:` | Documentação |
