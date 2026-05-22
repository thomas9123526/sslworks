---
title: "vLearn2 (VFLS) — 시스템 설계 명세서"
subtitle: "Virtual Foreign Language — 회화 중심 언어 학습 플랫폼"
author: "vLearn2 엔지니어링"
date: "2026-05-22"
---

# 시스템 설계 명세서

**프로젝트:** vLearn2 — 제품명 *Virtual Foreign Language* (VFLS)
**문서 종류:** 시스템 설계 명세서 (System Design Specification, SDS)
**버전:** 1.0 (초안)
**작성일:** 2026-05-22
**근거:** `C:\project\vLearn2` 코드베이스 조사 결과를 바탕으로 작성.

---

## 1. 개요

### 1.1 목적

본 문서는 vLearn2 시스템의 기술 설계 — 아키텍처, 기술 스택, 데이터
모델, 구성 요소 설계, 배포 토폴로지 — 를 기술한다. 시스템이 *어떻게*
구축되는지에 대한 엔지니어링 기준 문서이다. 시스템이 *무엇을* 해야
하는지는 별도의 요구사항 명세서에서, *어떻게 검증되는지*는 테스트
명세서에서 다룬다.

### 1.2 범위

vLearn2는 회화 중심의 언어 학습 플랫폼이다. 최종 사용자는 페르소나
기반 AI 튜터와 영어 회화(음성 및 텍스트)를 연습하고, 말하기 능력에
대한 자동 채점을 받으며, 학습 진행도·연속 학습일(streak)·업적을
추적한다. 관리자는 웹 콘솔을 통해 콘텐츠(시나리오, 페르소나, 코스,
뉴스), 사용자, AI 프롬프트 템플릿, 런타임 설정을 관리한다.

본 시스템은 다음 네 개의 서브시스템으로 구성된다.

1. **Flutter 앱** — Android 및 Windows용 학습자 클라이언트.
2. **백엔드 API** — REST API를 제공하는 NestJS 서비스.
3. **관리자 패널** — 운영 인력을 위한 Next.js 웹 콘솔.
4. **DataManage 도구** — Flutter 앱이 사용하는 음성 모델 번들(`.ddp`)을
   생성하는 Win32 C++ 유틸리티.

PostgreSQL 데이터베이스가 시스템을 뒷받침한다.

### 1.3 용어 및 약어

| 용어 | 의미 |
|------|------|
| VFLS | Virtual Foreign Language — 배포 산출물에 사용된 제품명 |
| 페르소나(Persona) | AI 튜터 캐릭터(억양, 스타일, 전문 분야, 아바타) |
| 시나리오(Scenario) | 구조화된 역할극 회화 연습 |
| 코스(Course) | 순서가 정해진 시나리오 모음 |
| 세션(Session) | 학습자와 튜터 간의 한 번의 회화 |
| `.ddp` | DataManage 패키지 — 서명된, 선택적으로 암호화·압축된 모델 번들 |
| RBAC | 역할 기반 접근 제어(Role-Based Access Control) |
| STT / TTS | 음성 인식 / 음성 합성 |
| XP | 학습자에게 부여되는 경험치 |
| JWT | JSON Web Token |
| SDS / SRS | 시스템 설계 명세서 / 소프트웨어 요구사항 명세서 |

### 1.4 참고 문서

- vLearn2 저장소의 `README.md` 및 서브시스템별 `README.md`.
- `/api/docs`에서 제공되는 백엔드 OpenAPI 명세.
- 요구사항 명세서(`vLearn2_Requirements_Specification_ko`).
- 테스트 명세서(`vLearn2_Testing_Specification_ko`).

---

## 2. 시스템 개관

vLearn2는 전형적인 3계층 구조에 오프라인 자산 패키징 파이프라인이
추가된 형태를 따른다.

- **표현 계층** — Flutter 앱(학습자)과 Next.js 관리자 패널(운영 인력).
- **응용 계층** — 모든 비즈니스 로직, 인증, AI 오케스트레이션, 영속화를
  담당하는 NestJS 백엔드.
- **데이터 계층** — PostgreSQL 16.
- **자산 파이프라인** — DataManage C++ 도구가 오프라인에서 `.ddp` 음성
  모델 번들을 생성하고, Flutter 앱이 기기에서 이를 검증·해제한다.

모든 클라이언트–서버 통신은 HTTP/HTTPS 기반 REST이다. 프로덕션
환경에서는 nginx 리버스 프록시가 TLS를 종단하고 두 Node 서비스로
트래픽을 라우팅한다.

### 2.1 컨텍스트 다이어그램

```
        ┌──────────────┐         ┌──────────────────┐
        │  학습자      │         │  관리자          │
        │  (Flutter:   │         │  (브라우저)      │
        │  Android,    │         │                  │
        │  Windows)    │         │                  │
        └──────┬───────┘         └────────┬─────────┘
               │ HTTPS                    │ HTTPS
               │ /vfls/*                  │ /vAdmin/*
               ▼                          ▼
        ┌───────────────────────────────────────────┐
        │            nginx 리버스 프록시            │
        │   /vfls/*  → 백엔드  /api/*                │
        │   /vAdmin/* → 관리자 패널                  │
        └───────┬──────────────────────┬─────────────┘
                │                      │
                ▼                      ▼
        ┌───────────────┐      ┌────────────────┐
        │ NestJS 백엔드 │◄────►│ Next.js 관리자 │
        │  (REST API)   │ 재작성│  패널         │
        └───────┬───────┘      └────────────────┘
                │
        ┌───────┼────────────────────┐
        ▼       ▼                    ▼
   ┌─────────┐ ┌──────────────┐ ┌──────────────┐
   │Postgres │ │ AI 제공자    │ │ 파일 스토리지│
   │  16     │ │ (Anthropic / │ │ (로컬 / S3)  │
   │         │ │  OpenAI 호환)│ │              │
   └─────────┘ └──────────────┘ └──────────────┘

   오프라인:  DataManage (C++) ──생성──► .ddp 번들 ──► Flutter 해제
```

### 2.2 서브시스템 역할

| 서브시스템 | 역할 |
|-----------|------|
| Flutter 앱 | 학습자 UX, 회화 UI(채팅 + 튜터 "얼굴" 모드), 기기 내 음성(STT/TTS), 오프라인 읽기 캐시, `.ddp` 모델 설치 |
| 백엔드 API | 인증, RBAC, 모든 도메인 로직, AI 오케스트레이션, 채점, 영속화, 파일 업로드, OpenAPI 문서 |
| 관리자 패널 | 콘텐츠·사용자·프롬프트·감사·런타임 설정을 위한 운영 콘솔 |
| DataManage | 음성 모델 번들을 서명된 `.ddp` 파일로 오프라인 패키징 |
| PostgreSQL | 모든 영속 데이터의 기록 원본(system of record) |

---

## 3. 아키텍처

### 3.1 아키텍처 스타일

- **백엔드:** 모듈형 모놀리식. NestJS가 도메인 로직을 14개의 기능
  모듈로 구성하여 단일 배포 프로세스로 묶는다. 전역 JWT 가드에 의해
  모든 라우트는 기본적으로 보호되며, 라우트는 `@Public()` 데코레이터로
  보호에서 제외한다.
- **관리자 패널:** Next.js App Router 기반의 서버 렌더링 React이며,
  상호작용이 필요한 페이지는 클라이언트 컴포넌트로 구성한다. 백엔드
  API의 얇은 클라이언트이다.
- **Flutter 앱:** 계층형 클라이언트 — `core/`(인프라: 네트워킹,
  스토리지, 라우팅, 음성, datapack)와 `features/`(화면 단위 기능
  모듈)로 구성되며, Riverpod 프로바이더가 조합 계층 역할을 한다.
- **DataManage:** 독립 실행형 네이티브 도구로, 서비스와 함께 배포되지
  않는다.

### 3.2 백엔드 모듈 구조

백엔드(`backend/src/`)는 `app.module.ts`에 등록된 다음 NestJS 모듈로
구성된다.

| 모듈 | 역할 |
|------|------|
| `AuthModule` | 학습자 가입/로그인/갱신/로그아웃, JWT 발급 |
| `UsersModule` | 학습자 프로필 조회/수정 |
| `PersonasModule` | AI 튜터 페르소나 카탈로그 |
| `ScenariosModule` | 역할극 시나리오 카탈로그 |
| `CategoriesModule` | 시나리오 카테고리 |
| `CoursesModule` | 코스 카탈로그(순서화된 시나리오 집합) |
| `ConversationsModule` | 회화 세션, 메시지, 채점 |
| `ProgressModule` | 진행도, 스킬 스냅샷, 완료 기록 |
| `AchievementsModule` | 업적 카탈로그 및 부여 |
| `AiModule` | AI 제공자 추상화, 프롬프트 생성, 오케스트레이션 |
| `GuardModule` (전역) | 콘텐츠 안전 가드 |
| `AdminModule` (전역) | 모든 관리자 기능 및 RBAC |
| `AppConfigModule` | 런타임 구성 플래그 |
| `NewsModule` | 인앱 뉴스/공지 |

루트 `HealthController`가 인증이 필요 없는 라이브니스 엔드포인트를
제공한다.

### 3.3 요청 처리 파이프라인 (백엔드)

수신 요청은 다음 순서로 처리된다.

1. `helmet` 보안 헤더와 `compression`(gzip).
2. 전역 `ValidationPipe`(`whitelist`, `forbidNonWhitelisted`,
   `transform`) — 알 수 없는 필드를 거부하고 DTO 타입을 강제한다.
3. 전역 `JwtAuthGuard`(`APP_GUARD`) — 핸들러가 `@Public()`이 아닌 한
   모든 요청을 인증한다.
4. 전역 `ThrottlerGuard` — 속도 제한(기본 60초당 120요청).
5. 관리자 라우트의 `PermissionGuard` — RBAC 시행.
6. 컨트롤러 → 서비스 → 리포지토리(TypeORM) → PostgreSQL.

전역 API 접두사는 `/api`이며, `health`와 `uploads/(.*)`는 제외된다.

### 3.4 배포 토폴로지

| 구성 요소 | 프로세스 | 기본 포트 | 공개 경로 (nginx 경유) |
|-----------|----------|-----------|------------------------|
| 백엔드 API | `node dist/main` | 3000(개발) / 4101(서비스 스크립트) | `/vfls/*` → `/api/*`로 재작성 |
| 관리자 패널 | `next start` | 4100(개발) / 5101(서비스 스크립트) | `/vAdmin/*` |
| PostgreSQL | `postgres:16-alpine` | 5432 | 내부 전용 |

> **참고 — 포트 불일치.** `cmds/`의 시작 스크립트는 Windows `.bat`,
> Linux `.sh`, 그리고 해당 문서 사이에서 기본 포트 값이 서로 다르다.
> 단일 표준 매핑으로 정리해야 한다. §11 참조.

nginx는 TLS를 종단하고, 관리자 패널을 `/vAdmin/` 아래에서 제공하며,
`/vfls/*`를 백엔드의 `/api/*`로 매핑한다. 프로덕션에서 서비스는 `pm2`
또는 `nohup` 기반 `start_service_linux.sh`로 관리된다.

---

## 4. 기술 스택

### 4.1 백엔드

| 항목 | 기술 |
|------|------|
| 런타임 | Node.js 22+ |
| 프레임워크 | NestJS 11 |
| 언어 | TypeScript 5.7 |
| ORM | TypeORM 0.3.29 |
| DB 드라이버 | `pg` 8.20 |
| 인증 | `@nestjs/jwt`, `@nestjs/passport`, `passport-jwt`, `passport-local`, `bcrypt` |
| 검증 | `class-validator`, `class-transformer` |
| AI | `@anthropic-ai/sdk`, `openai` |
| API 문서 | `@nestjs/swagger` |
| 속도 제한 | `@nestjs/throttler` |
| 보안 / 성능 | `helmet`, `compression` |
| 국제화 | `nestjs-i18n` |
| 이미지 처리 | `sharp` |
| 테스트 | Jest 30, `ts-jest`, `supertest` |

### 4.2 관리자 패널

| 항목 | 기술 |
|------|------|
| 프레임워크 | Next.js 14.2 (App Router) |
| UI 라이브러리 | React 18.3 |
| 언어 | TypeScript 5.5 |
| 데이터 페칭 | TanStack Query 5 |
| 테이블 | TanStack Table 8 |
| 폼 / 검증 | React Hook Form 7, Zod 3 |
| 차트 | Recharts 2 |
| 스타일링 | Tailwind CSS 3.4 |
| 아이콘 | `lucide-react` |
| 테스트 | Jest 30, `ts-jest` |

### 4.3 Flutter 앱

| 항목 | 기술 |
|------|------|
| SDK | Dart 3.11; Flutter 3.41+ |
| 상태 관리 | Riverpod 2 |
| 내비게이션 | `go_router` 14 |
| 네트워킹 | `dio` 5 (`retrofit`는 선언되었으나 아직 미사용) |
| 로컬 DB | `drift` 2 (SQLite) |
| 모델 / 코드 생성 | `freezed`, `json_serializable`, `build_runner` |
| 보안 스토리지 | `flutter_secure_storage` |
| 환경설정 | `shared_preferences` |
| 음성 | `sherpa_onnx`(STT/TTS), `record`(마이크), `audioplayers`(재생) |
| 애니메이션 | `rive` |
| 차트 | `fl_chart` |
| 국제화 | `intl`, 생성된 `app_localizations`(영어, 중국어) |
| `.ddp` 암호화 | `pointycastle`, `archive`, `asn1lib` |

### 4.4 DataManage 도구

Win32 C++ GUI/CLI 애플리케이션. `zlib`(압축), `mbedTLS`(암호화/서명),
JSON 라이브러리를 내장한다. 서명되고 선택적으로 암호화·압축된 `.ddp`
번들을 생성한다.

---

## 5. 데이터 설계

### 5.1 개요

PostgreSQL 16이 기록 원본이다. 영속화에는 26개의 엔티티를 가진
TypeORM이 사용된다. 대부분의 테이블은 `vl_` 접두사를 가지며, 기본 키는
`gen_random_uuid()`(pgcrypto)로 생성된 UUID이다. 스키마 변경은 순서가
있는 13개의 마이그레이션 파일로 관리되며, 시드 러너가 기본 업적,
앱 설정, 코스, 페르소나, 시나리오를 채운다.

지역화 텍스트 필드는 다국어 콘텐츠를 위해 JSONB(`I18nText`)로
저장된다.

### 5.2 엔티티 그룹

**식별 및 접근**

| 엔티티 | 테이블 | 용도 |
|--------|--------|------|
| `UserEntity` | `users` | 학습자 계정(자격 증명, 이름, CID) |
| `UserInfoEntity` | `vl_user_info` | 학습자 프로필(이메일, 레벨, XP, streak, 역할, 상태, 환경설정) |
| `RefreshTokenEntity` | `vl_refresh_tokens` | 해시된 학습자 리프레시 토큰 |
| `AdminEntity` | `vl_admins` | 운영 인력 계정 |
| `AdminRefreshTokenEntity` | `vl_admin_refresh_tokens` | 해시된 관리자 리프레시 토큰 |
| `AdminPermissionEntity` | `vl_admin_permissions` | 관리자별 부여 권한 |
| `AdminAuditLogEntity` | `vl_admin_audit_log` | 관리자 행위의 불변 기록 |

**학습 콘텐츠**

| 엔티티 | 테이블 | 용도 |
|--------|--------|------|
| `PersonaEntity` | `vl_personas` | AI 튜터 캐릭터 |
| `CategoryEntity` | `vl_categories` | 시나리오 카테고리 |
| `ScenarioEntity` | `vl_scenarios` | 역할극 연습 |
| `CourseEntity` | `vl_courses` | 순서화된 시나리오 모음 |
| `CourseScenarioEntity` | `vl_course_scenarios` | 코스↔시나리오 조인 |
| `PromptTemplateEntity` | `vl_prompt_templates` | 편집 가능한 AI 프롬프트 템플릿 |

**회화 및 채점**

| 엔티티 | 테이블 | 용도 |
|--------|--------|------|
| `ConversationSessionEntity` | `vl_conversation_sessions` | 한 번의 회화 인스턴스 |
| `ConversationMessageEntity` | `vl_conversation_messages` | 세션 내 메시지 |
| `SessionScoreEntity` | `vl_session_scores` | 세션별 다중 스킬 점수 |

**진행도 및 게임화**

| 엔티티 | 테이블 | 용도 |
|--------|--------|------|
| `UserProgressEntity` | `vl_user_progress` | 학습자 종합 진행도 |
| `SkillSnapshotEntity` | `vl_skill_snapshots` | 일별 스킬별 스냅샷 |
| `UserScenarioCompletionEntity` | `vl_user_scenario_completions` | 시나리오별 완료 기록 |
| `AchievementEntity` | `vl_achievements` | 업적 카탈로그 |
| `UserAchievementEntity` | `vl_user_achievements` | 학습자가 획득한 업적 |

**플랫폼**

| 엔티티 | 테이블 | 용도 |
|--------|--------|------|
| `AppConfigEntity` | `vl_app_config` | 런타임 구성 플래그 |
| `NewsPostEntity` | `vl_news_posts` | 인앱 공지 |
| `NewsReadStatusEntity` | `vl_news_read_status` | 사용자별 뉴스 읽음 상태 |
| `GuardViolationEntity` | `vl_guard_violations` | 콘텐츠 안전 위반 로그 |
| `UploadedFileEntity` | `vl_uploaded_files` | 업로드 파일 메타데이터(참조 카운트 포함) |

### 5.3 주요 관계

- `UserEntity` 1—1 `UserInfoEntity`(eager, cascade, `ON DELETE CASCADE`).
- `UserEntity` 1—N `RefreshTokenEntity`.
- `ScenarioEntity` N—1 `CategoryEntity`(`ON DELETE RESTRICT`).
- `CourseEntity` N—M `ScenarioEntity` — `CourseScenarioEntity` 경유(순서화).
- `ConversationSessionEntity` 1—N `ConversationMessageEntity`;
  1—1 `SessionScoreEntity`.
- `ConversationSessionEntity`는 `ScenarioEntity`(nullable — null은 자유
  대화를 의미)와 `PersonaEntity`를 참조.
- `AdminEntity` 1—N `AdminRefreshTokenEntity`.

### 5.4 열거형

열거 값은 `varchar`로 저장되고 애플리케이션 계층에서 제약된다.

- `UserRole`: `user | admin | superadmin`
- `UserStatus` / `AdminStatus`: `active | suspended | deleted`
- `AdminRole`: `admin | superadmin`
- `ScenarioStatus` / `CourseStatus` / `NewsStatus`: `draft | published | archived`
- `ConversationMode`: `chat | face`
- `SessionStatus`: `active | completed | abandoned`
- `MessageRole`: `user | assistant`
- `GuardSeverity`: `block | warn`; `GuardSource`: `client | server`
- `PromptKind`: `tutor_system | grammar | feedback`
- `AppConfigCategory`: `home | evaluation | progress | conversation | scenarios | settings | system`
- `AppConfigValueType`: `boolean | string | number | object | array`

---

## 6. 백엔드 설계

### 6.1 API 표면

모든 엔드포인트는 `/api` 접두사 아래에 있다(`/health` 제외). 모든
라우트는 공개로 표시되지 않는 한 JWT로 보호된다.

**공개(Public)**

- `GET /health` — 라이브니스.
- `POST /api/auth/signup`, `signin`, `refresh` — 학습자 인증.
- `POST /api/admin/auth/signup`, `signin`, `refresh` — 관리자 인증.

**학습자용(JWT, `actor = user`)**

- `auth` — `signout`, `me`.
- `users` — `GET/PATCH /profile`.
- `personas`, `scenarios`(필터링 가능), `categories`, `courses` — 조회.
- `conversations` — 세션 시작, 세션 목록, 메시지 포함 세션 조회, 메시지
  전송(+튜터 응답), 세션 종료, 세션 삭제, 추천 요청.
- `progress` — 진행도/스냅샷/완료 조회, 일별 스냅샷 업서트.
- `achievements` — 카탈로그, 획득 목록.
- `news` — 목록(페이지네이션), 미읽음 수, 읽음 처리, 조회.
- `app-config` — 앱에 노출되는 구성 플래그.

**관리자용(JWT `actor = admin` + `PermissionGuard`)**

- `admin/auth`, `admin/admins`, `admin/stats`, `admin/users`,
  `admin/scenarios`, `admin/personas`, `admin/categories`,
  `admin/leaderboard`, `admin/prompt-templates`, `admin/news`,
  `admin/audit`, `admin/config`.

전체 라우트 목록은 `/api/docs`의 OpenAPI 명세가 기준이다.

### 6.2 인증 및 인가

vLearn2는 **이중 액터(dual-actor) JWT** 모델을 사용한다.

- 단일 JWT 구조가 `sub`(주체 ID), 신원 클레임, `role`,
  `permissions[]`, 그리고 `sub`가 어느 테이블을 가리키는지 가드에
  알려주는 `actor` 구분자(`user` | `admin`)를 담는다.
- **액세스 토큰**은 HS256 서명, 단기 유효(기본 15분).
- **리프레시 토큰**은 무작위 48바이트 비밀값으로, SHA-256 해시로만
  저장되고, 1회용(갱신 시마다 회전)이며, 기본 수명 7일이다. 학습자와
  관리자는 별도의 리프레시 토큰 테이블을 사용한다.
- **비밀번호**는 bcrypt 해시(10라운드). 관리자 비밀번호는 학습자보다
  강한 구성 규칙을 가진다.
- **RBAC:** `PermissionGuard`가 약 40개 권한 키 카탈로그에 대해
  `@RequirePermission(...)`을 시행한다. `superadmin`은 모든 검사를
  우회한다. 서브 관리자 권한은 `vl_admin_permissions`에서 해결되며,
  개인정보 민감 권한은 서브 관리자에게 부여할 수 없다.
- **감사:** 관리자 변경은 변경과 동일한 DB 트랜잭션 내에서
  `vl_admin_audit_log`에 기록된다 — 감사 항목과 변경이 함께 커밋되거나
  함께 롤백된다.

### 6.3 AI 오케스트레이션

`AiModule`은 팩토리(`AiProviderFactory`)를 통해 LLM 제공자를
추상화하며, `AI_PROVIDER` 환경 변수로 Anthropic 또는 OpenAI 호환
제공자를 선택한다. `ConversationOrchestrator`는 편집 가능한
`PromptTemplateEntity` 레코드로 프롬프트를 구성하고, 튜터 응답과
유휴 추천 생성을 수행하며, 우아하게 성능 저하한다 —
`AiProviderError` 발생 시 미리 준비된 대체 응답을 반환하고, 문법
채점은 모델이 불가용할 때 알고리즘 채점으로 대체된다. 일일 한도
(`MAX_AI_MESSAGES_PER_DAY`)가 AI 사용량을 제한한다.

> 새 세션의 첫 튜터 메시지는 현재 하드코딩된 플레이스홀더이다.
> 세션 시작 경로의 완전한 AI 연동은 미완성이다. §11 참조.

### 6.4 콘텐츠 안전

전역 `GuardModule`이 회화 콘텐츠를 검사한다. 위반은 심각도
(`block`/`warn`), 일치 용어, 언어, 출처(`client`/`server`)와 함께
`vl_guard_violations`에 기록된다. Flutter 앱도 클라이언트 측
`content_guard`를 실행한다.

### 6.5 파일 업로드

이미지(시나리오·페르소나 아트워크)는 관리자 엔드포인트를 통해
업로드되며, MIME 타입(`jpeg`/`png`/`webp`)과 크기(≤ 5 MB)가 검증되고,
`sharp`로 처리되며, 콘텐츠 해시와 참조 카운트와 함께
`vl_uploaded_files`에 기록된다. 스토리지는 플러그형이다
(`STORAGE_PROVIDER` = `local` | `s3`).

### 6.6 구성

구성은 `@nestjs/config`를 통해 읽는 환경 변수(`.env`)로 공급된다. 주요
그룹: 서버(`PORT`, `PUBLIC_BASE_URL`, `CORS_ORIGINS`), 데이터베이스
(`DB_*`), JWT 비밀값 및 수명, AI 제공자 설정, 스토리지, 스로틀링,
gzip.

---

## 7. 관리자 패널 설계

### 7.1 라우팅

관리자 패널은 `basePath: /vAdmin`을 가진 Next.js App Router를
사용하며, 두 개의 라우트 그룹으로 구성된다.

- `(auth)` — `/signin`, `/signup`.
- `(dashboard)` — 인증 게이트가 있는 공용 사이드바 레이아웃. 페이지:
  대시보드, 페르소나(+신규/편집), 프롬프트 템플릿, 시나리오(+신규),
  카테고리, 사용자, 뉴스(+신규), 리더보드, 감사, 관리자, 설정.

### 7.2 백엔드 통신

`fetch` 기반 API 클라이언트(`src/lib/api.ts`)가
`NEXT_PUBLIC_API_BASE_URL`을 대상으로 하며, 베어러 토큰을 첨부하고,
401 발생 시 한 번 토큰을 갱신한 후 재시도한다. `next.config.mjs`는
`/api/backend/*`에서 백엔드 `/api/*`로의 서버 측 재작성도 정의한다.

### 7.3 인증

관리자 액세스·리프레시 토큰은 `sessionStorage`에 보관된다. 대시보드
레이아웃은 **클라이언트 측** 게이트(JWT가 없거나 역할이
`admin`/`superadmin`이 아니면 `/signin`으로 리디렉션)를 수행하며,
`usePermission` 훅이 누락된 권한에 대한 UI를 숨긴다. **백엔드의 서버
측 검사가 권위 있는 시행으로 남는다** — 클라이언트 게이팅은 UX
편의일 뿐이다.

---

## 8. Flutter 앱 설계

### 8.1 계층 구조

- **`core/`** — 인프라: `api/`(Dio 클라이언트 + 인터셉터), `auth/`,
  `config/`, `datapack/`(`.ddp` 해제기), `db/`(Drift), `guard/`,
  `models/`, `providers/`, `router/`(`go_router`), `services/`,
  `speech/`(레코더 + sherpa-onnx STT/TTS), `storage/`, `theme/`,
  `utils/`.
- **`features/`** — 화면 단위 모듈: `splash`, `auth`, `onboarding`,
  `home`, `scenarios`, `conversation`, `course`, `report`,
  `progress`, `news`, `settings`, `setup`.
- **`l10n/`** — 생성된 지역화(영어, 중국어).
- **`shared/`** — 공용 위젯.

### 8.2 상태 관리

전반에 Riverpod이 사용된다. `main.dart`는 `runApp` 전에
`appConfigProvider`를 예열한다. 핵심 프로바이더로 `authProvider`(상태
기계: `checking → signedOut | signedIn`), `appSettingsProvider`,
`routerProvider`, `apiClientProvider`가 있다.

### 8.3 내비게이션

`go_router`가 스플래시, 인증, 온보딩, 5탭 셸(홈, 시나리오, 회화 이력,
진행도, 설정), 전체 화면 회화, 세션 리포트, 코스, 뉴스, 음성 모델
설정 화면의 라우트를 정의한다. 리디렉션 핸들러가 인증 게이팅, 온보딩
완료, 그리고 모델 번들 미설치 시 회화 시작을 `/setup/models`로
전환하는 음성 모델 게이트를 처리한다(학습자가 텍스트 전용 모드를
승인한 경우는 예외).

### 8.4 네트워킹

`dio` 클라이언트가 `apiClientProvider`마다 구성된다. 기본 URL은
기기 내 `app_config.json` 파일에서 런타임에 읽으며, 빌드 시
`--dart-define=API_BASE_URL`로 재정의할 수 있다. 인터셉터 순서: 압축,
인증(베어러 첨부 + 자동 갱신 + 무효 세션 시 강제 로그아웃), 요청
로깅(디버그 전용), 오류 정규화.

### 8.5 로컬 스토리지 및 오프라인 동작

- **`flutter_secure_storage`** — JWT 액세스/리프레시 토큰(Windows의
  오래된 읽기 경쟁을 피하기 위한 인메모리 캐시 계층 포함)과 기억된
  자격 증명.
- **`shared_preferences`** — 동기 설정 캐시(테마, 언어, 폰트, 회화
  기본값).
- **Drift (SQLite)** — `vlearn2.sqlite`. 8개 테이블이 사용자,
  시나리오, 세션, 메시지, 진행도, 설정, 레이아웃 구성을 캐시하여
  오프라인 읽기 전용 흐름을 지원한다.

### 8.6 음성 및 모델 패키징

기기 내 STT/TTS는 `sherpa_onnx`를 사용한다. 검증된 모델 번들이 있을
때만 실제 엔진이 활성화되며, 그렇지 않으면 플레이스홀더 무동작
서비스가 사용된다. 모델 번들은 DataManage 도구가 서명된 `.ddp`
파일로 오프라인 생성하고, 순수 Dart 암호화를 사용하여 백그라운드
아이솔레이트에서 해제된다. 커밋된 루트 CA 인증서
(`assets/datamanage/root_ca.crt`)가 서명 검증을 고정한다.

### 8.7 플랫폼별 사항

- **Android** — 패키지 `com.ryongma.vfls`, `minSdk 24`,
  `targetSdk 35`, ABI `arm64-v8a` + `x86_64`. 권한: 인터넷,
  마이크, 스토리지. 릴리스 빌드는 현재 디버그 키로 서명된다(§11 참조).
- **Windows** — 표준 Win32 C++ 러너, 네이티브 스플래시.

---

## 9. 공통 관심사

### 9.1 로깅

- **백엔드** — NestJS `Logger`; `DB_LOGGING`을 통한 선택적 TypeORM
  쿼리 로깅.
- **Flutter** — `logger` 패키지; 베어러 헤더 첨부 후의 디버그 전용
  요청 로깅.
- **관리자** — Next.js/브라우저 기본값에 의존.

### 9.2 오류 처리

- **백엔드** — `nestjs-i18n` 번역을 위한 `i18nKey`를 담은 타입화된
  NestJS HTTP 예외. 관리자 변경은 DB 트랜잭션 내에서 실행된다.
- **Flutter** — `PoliteError` 계층이 원시 실패를 사용자 안전 메시지로
  변환한다. Dio 오류 인터셉터가 실패를 정규화하고, 무효 세션은 강제
  로그아웃을 유발하며, 오프라인 실패는 Drift 캐시로 대체된다.

### 9.3 국제화

지역화 콘텐츠는 JSONB `I18nText`로 저장된다. 백엔드는 `nestjs-i18n`로
오류 키를 번역한다. Flutter 앱은 영어와 중국어 지역화를 탑재한다.

### 9.4 보안

- nginx에서 TLS 종단; `helmet`을 통한 HSTS 및 보안 헤더.
- CORS는 `CORS_ORIGINS`로 제한되며 자격 증명이 활성화된다.
- 비밀값은 환경 변수로 공급되며, 예시 파일에는 플레이스홀더만
  포함된다.
- bcrypt 비밀번호 해싱; 해시된 1회용 리프레시 토큰; 학습자/관리자
  별도 토큰 저장소; 전역 속도 제한.
- `.ddp` 번들은 암호학적으로 서명되며, Flutter 앱은 루트 CA를
  고정(pin)한다.

---

## 10. 배포 아키텍처

### 10.1 빌드

| 서브시스템 | 빌드 명령 | 산출물 |
|-----------|-----------|--------|
| 백엔드 | `npm run build`(`nest build`) | `dist/` |
| 관리자 패널 | `npm run build`(`next build`) | `.next/` |
| Flutter(Android) | `flutter build apk --release` | 서명된 APK |
| Flutter(Windows) | `flutter build windows --release` | Windows 번들 |

### 10.2 런타임

프로덕션은 nginx 뒤에서 두 Node 서비스를 실행하며, `cmds/` 런처 또는
`pm2`로 시작한다. PostgreSQL은 관리형 서비스 또는 제공된
`docker-compose.yml`(개발)로 실행된다.

### 10.3 지속적 통합(CI)

GitHub Actions 워크플로(경로 필터링)가 각 서브시스템을 빌드·테스트한다.

- `backend_ci.yml` — Node 22, 임시 PostgreSQL 서비스, 린트, 빌드, 단위
  테스트, 비차단 e2e, 커버리지 아티팩트.
- `admin_ci.yml` — Node 20, 린트, 타입체크, `next build`.
- `flutter_ci.yml` — Flutter 3.41.9, 포맷 검사, 분석, 테스트, 디버그
  Android + Windows 빌드.

> CI는 `master`/`dev`에서 트리거된다. 저장소의 기본 브랜치는
> `main`이므로 트리거 브랜치를 정렬해야 한다. §11 참조.

---

## 11. 알려진 제약사항 및 기술 부채

설계 투명성을 위해 다음 사항을 기록하며, 해결을 위해 추적해야 한다.

1. **AI 세션 시작 경로 일부 미구현** — 새 회화의 첫 튜터 메시지가
   하드코딩된 플레이스홀더이다.
2. **gzip 런타임 차단 스위치 비활성화** — 압축 필터의
   `system.gzip_enabled` 플래그 / `GZIP_ENABLED` 환경 검사가
   주석 처리되어 런타임 효과가 없다.
3. **음성 엔진 게이팅** — 검증된 `.ddp` 모델 번들이 설치될 때까지
   STT/TTS는 플레이스홀더 무동작 서비스를 사용한다.
4. **Retrofit 미사용** — Flutter 의존성으로 선언되었으나 Retrofit
   클라이언트가 생성되지 않았다. API 호출은 수작업 Dio 코드이다.
5. **Android 릴리스 서명** — 릴리스 빌드가 디버그 키로 서명된다.
   배포 전 프로덕션 키스토어가 필요하다.
6. **CI 브랜치 불일치** — 워크플로가 `master`/`dev`에서 트리거되나
   기본 브랜치는 `main`이다.
7. **시작 스크립트 포트 불일치** — `cmds/` 런처들이 기본 백엔드/관리자
   포트에 대해 서로 다르다.
8. **개방형 관리자 가입** — `POST /admin/auth/signup`은 부트스트랩을
   위해 의도적으로 미인증 상태이다(첫 가입 → superadmin). 공개 배포
   전 반드시 차단해야 한다.
9. **관리자 토큰 저장** — 관리자 토큰이 `sessionStorage`에 있어 XSS에
   노출된다. httpOnly 쿠키 대비 문서화된 트레이드오프이다.
10. **문서 불일치** — 일부 README가 오래되었다.
11. **불필요 디렉터리** — 중첩된 `backend/flutter_app/` 중복본이
    존재하므로 제거해야 한다.

---

*시스템 설계 명세서 끝.*
