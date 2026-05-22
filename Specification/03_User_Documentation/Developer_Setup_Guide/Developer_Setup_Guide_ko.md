---
title: "vLearn2 (VFLS) — 개발자 설정 가이드"
author: "vLearn2 엔지니어링"
date: "2026-05-22"
---

# 개발자 설정 가이드

**프로젝트:** vLearn2 (VFLS) · **버전:** 1.0 · **작성일:** 2026-05-22
**대상:** 로컬 환경을 설정하는 개발자.

---

## 1. 개요

vLearn2는 하나의 저장소에 네 개의 서브시스템을 가진다.

```
vLearn2/
├── backend/        NestJS API
├── admin_panel/    Next.js 관리자 콘솔
├── flutter_app/    Flutter 앱(Android + Windows)
├── datamanage/     Win32 C++ 패키징 도구
└── docker-compose.yml   로컬 개발용 PostgreSQL
```

다른 서브시스템을 설정하지 않고 하나의 서브시스템만 작업할 수 있다.

## 2. 사전 요구사항

| 도구 | 버전 | 용도 |
|------|------|------|
| Node.js | 22+ | 백엔드, 관리자 패널 |
| npm | Node에 포함 | 패키지 관리 |
| Docker | 최신 | 로컬 PostgreSQL |
| PostgreSQL | 16 | (Docker 미사용 시) |
| Flutter SDK | 3.41+ (Dart 3.11) | Flutter 앱 |
| Android SDK | API 24+ | Android 빌드 |
| Visual Studio + "C++를 사용한 데스크톱 개발" | 2022 | Windows Flutter 빌드 |
| JDK | 17 | Android Gradle |

## 3. 데이터베이스

```bash
# 저장소 루트에서
docker compose up -d postgres
```

이는 PostgreSQL 16(`vlearn2-postgres`, 포트 5432, 데이터베이스
`vlearn2`)을 시작한다. PostgreSQL을 직접 실행한다면 `vlearn2`
데이터베이스를 생성하고 `DB_*` 변수를 그에 맞게 설정하라.

## 4. 백엔드

```bash
cd backend
npm install
cp .env.example .env          # 그 후 값 편집(아래 참조)
npm run db:migrate            # 스키마 적용
npm run db:seed               # 참조 콘텐츠 적재
npm run start:dev             # 워치 모드
```

설정해야 할 최소 `.env` 값: `DB_*`, `JWT_ACCESS_SECRET`,
`JWT_REFRESH_SECRET`, AI 제공자 키(`ANTHROPIC_API_KEY` 또는 `OPENAI_*`
그룹). API는 `PORT`(기본 3000)에서 제공되며, Swagger UI는
`/api/docs`에 있다.

유용한 스크립트: `npm run start`(워치 없음), `npm run build`,
`npm test`, `npm run test:e2e`, `npm run db:migrate:generate`.

## 5. 관리자 패널

```bash
cd admin_panel
npm install
cp .env.example .env          # NEXT_PUBLIC_API_BASE_URL, BACKEND_BASE_URL 설정
npm run dev                   # http://localhost:4100/vAdmin/
```

`NEXT_PUBLIC_API_BASE_URL`은 백엔드를 가리켜야 한다(로컬 개발 시
`http://localhost:3000/api`). `NEXT_PUBLIC_*` 값은 빌드 시 인라인됨을
기억하라. 기타 스크립트: `npm run build`, `npm run start`,
`npm run typecheck`, `npm test`.

## 6. Flutter 앱

```bash
cd flutter_app
flutter pub get
dart run build_runner build   # Riverpod / freezed / drift 코드 생성
flutter run -d windows        # 또는: flutter run -d <android-기기>
```

API 기준 URL은 기기 내 `app_config.json`에서 런타임에 읽거나, 빌드
시 재정의할 수 있다.

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:3000/vfls
```

빌드: `flutter build apk --release`,
`flutter build windows --release`. 테스트: `flutter test`.

> 기기 내 음성 기능은 `.ddp` 모델 번들이 필요하다. 없으면 앱은 음성을
> 플레이스홀더 모드로 실행한다. 개발 시 정상적인 상태이다.

## 7. DataManage 도구 (선택)

`datamanage/` Win32 C++ 도구는 `.ddp` 모델 번들을 빌드한다. 모델
패키징 작업을 할 때만 빌드하라; `datamanage/README.md` 참조.

## 8. 전체 함께 실행

통합 로컬 스택의 경우:

1. PostgreSQL 시작(`docker compose up -d postgres`).
2. 백엔드 시작(`npm run start:dev`).
3. 관리자 패널 시작(`npm run dev`).
4. 로컬 백엔드를 가리키도록 Flutter 앱 실행.

또는 `cmds/` 스크립트가 백엔드와 관리자 패널을 함께 실행한다.

## 9. 코드 생성 참고

Flutter 앱은 코드 생성(Riverpod, freezed, json_serializable, drift)을
사용한다. 어노테이션된 파일을 변경한 후 다음을 다시 실행하라.

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 10. 테스트 및 CI

- 백엔드 / 관리자: `npm test`(Jest).
- Flutter: `flutter test`.
- CI(GitHub Actions)는 푸시 시 각 서브시스템을 빌드·테스트한다.
  워크플로가 현재 `master`/`dev`에서 트리거됨에 유의하라; 본인의
  브랜치가 포함되는지 확인하라.

## 11. 흔한 문제

| 증상 | 해결 |
|------|------|
| 백엔드가 DB에 연결 불가 | `DB_*`와 PostgreSQL 실행 여부 확인 |
| pull 후 Flutter 빌드 오류 | `build_runner build` 재실행 |
| 관리자 패널이 잘못된 API 대상 표시 | `NEXT_PUBLIC_*` 변경 후 재빌드 |
| Windows Flutter 빌드 실패 | Visual Studio C++ 워크로드 설치 |
| 오프라인에서 `flutter pub get` 실패 | 먼저 온라인 상태에서 pub 캐시 채우기 |

---

*개발자 설정 가이드 끝.*
