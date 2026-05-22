---
title: "vLearn2 (VFLS) — API 레퍼런스"
subtitle: "백엔드 REST API"
author: "vLearn2 엔지니어링"
date: "2026-05-22"
---

# API 레퍼런스

**프로젝트:** vLearn2 (VFLS) · **버전:** 1.0 · **작성일:** 2026-05-22
**근거:** 백엔드 NestJS 서비스; 기준 명세는 `/api/docs`.

---

## 1. 규약

- **기본 경로:** 모든 엔드포인트는 `/api` 접두사를 가진다(`GET /health`
  제외). 프로덕션에서 nginx는 공개 경로 `/vfls/*`를 `/api/*`로
  매핑한다.
- **형식:** JSON 요청·응답 본문. 이미지 업로드는
  `multipart/form-data`를 사용한다.
- **인증:** 엔드포인트가 **공개(Public)**로 표시되지 않는 한
  `Authorization: Bearer <액세스 토큰>`. 모든 라우트는 기본적으로
  보호된다.
- **액터:** JWT는 `actor` 클레임(`user` 또는 `admin`)을 담는다. 학습자
  엔드포인트는 `actor=user`, 관리자 엔드포인트는 `actor=admin`과
  해당 권한을 요구한다.
- **속도 제한:** 기본 클라이언트당 60초당 120요청. 초과 시
  `429 Too Many Requests`.
- **오류:** 2xx가 아닌 응답은 `i18nKey`(예:
  `auth.invalid_credentials`)를 담은 NestJS 오류 본문을 반환한다.

## 2. 표준 상태 코드

| 코드 | 의미 |
|------|------|
| 200 | 성공 |
| 201 | 리소스 생성됨 |
| 204 | 성공, 본문 없음 |
| 400 | 검증 오류(잘못되거나 알 수 없는 필드) |
| 401 | 토큰 누락/무효/만료 |
| 403 | 인증되었으나 권한 없음 |
| 404 | 리소스 없음 |
| 409 | 충돌(예: 사용 중인 카테고리 삭제) |
| 429 | 속도 제한 초과 |
| 5xx | 서버 오류 |

---

## 3. 헬스

### `GET /health` — **공개**

라이브니스 프로브. 접두사·인증 없음. 응답 `200`: `{ "status": "ok" }`.

---

## 4. 학습자 인증 — `/api/auth`

| 메서드 & 경로 | 인증 | 설명 |
|---------------|------|------|
| `POST /auth/signup` | 공개 | 학습자 계정 생성. 본문: `cid`, `cidUsername`, `password`(6–128), `displayName`, `uiLanguage`. 액세스+리프레시 토큰 반환. |
| `POST /auth/signin` | 공개 | 인증; 액세스+리프레시 토큰 반환. |
| `POST /auth/refresh` | 공개 | 리프레시 토큰을 새 액세스 토큰으로 교환; 리프레시 토큰은 회전(1회용). |
| `POST /auth/signout` | JWT | 현재 리프레시 토큰 무효화. `204`. |
| `GET /auth/me` | JWT | 현재 학습자의 디코딩된 토큰 페이로드 반환. |

## 5. 학습자 프로필 — `/api/users`

| 메서드 & 경로 | 인증 | 설명 |
|---------------|------|------|
| `GET /users/profile` | JWT | 현재 학습자 프로필(레벨, XP, streak, 환경설정). |
| `PATCH /users/profile` | JWT | 표시 이름·아바타·성별·언어·테마·페르소나·온보딩 플래그 또는 비밀번호 수정(비밀번호 변경은 현재 비밀번호 필요). |

## 6. 학습 콘텐츠 (학습자)

| 메서드 & 경로 | 인증 | 설명 |
|---------------|------|------|
| `GET /personas` | JWT | 활성 튜터 페르소나 목록. |
| `GET /personas/:id` | JWT | 페르소나 상세. |
| `GET /scenarios` | JWT | 게시 시나리오 목록. 쿼리: `category`, `difficulty`, `q`. |
| `GET /scenarios/:idOrSlug` | JWT | 시나리오 상세(목표, 핵심 표현, 역할). |
| `GET /categories` | JWT | 활성 시나리오 카테고리 목록. |
| `GET /courses` | JWT | 게시 코스 목록. |
| `GET /courses/:idOrSlug` | JWT | 순서화된 시나리오를 포함한 코스 상세. |

## 7. 회화 — `/api/conversations`

| 메서드 & 경로 | 인증 | 설명 |
|---------------|------|------|
| `POST /conversations/sessions` | JWT | 세션 시작. 본문: `personaId`(UUID), 선택 `scenarioId`, `mode`(`chat`\|`face`). |
| `GET /conversations/sessions` | JWT | 학습자 세션 목록(필터링 가능). |
| `GET /conversations/sessions/:id` | JWT | 메시지를 포함한 세션 상세. |
| `POST /conversations/sessions/:id/messages` | JWT | 학습자 메시지(1–5000자) 전송; 튜터 응답 반환. |
| `POST /conversations/sessions/:id/end` | JWT | 세션 종료; 소요 시간·턴·단어·XP 기록. |
| `DELETE /conversations/sessions/:id` | JWT | 세션과 메시지 삭제. |
| `POST /conversations/sessions/:id/suggest` | JWT | 유휴 프롬프트 추천 요청. |

## 8. 진행도 & 업적

| 메서드 & 경로 | 인증 | 설명 |
|---------------|------|------|
| `GET /progress` | JWT | 종합 진행도(세션, 분, 단어, streak). |
| `GET /progress/snapshots` | JWT | 일별 스킬별 스냅샷. |
| `GET /progress/completions` | JWT | 시나리오별 완료 기록. |
| `POST /progress/snapshots` | JWT | 당일 스냅샷 업서트(이동 평균). |
| `GET /achievements` | JWT | 업적 카탈로그. |
| `GET /achievements/mine` | JWT | 학습자가 획득한 업적. |

## 9. 뉴스 & 앱 설정

| 메서드 & 경로 | 인증 | 설명 |
|---------------|------|------|
| `GET /news` | JWT | 학습자별 읽음 플래그를 포함한 페이지네이션 뉴스. |
| `GET /news/unread-count` | JWT | 미읽음 게시물 수. |
| `POST /news/read-all` | JWT | 전체 게시물 읽음 처리. |
| `POST /news/:id/read` | JWT | 게시물 1건 읽음 처리. |
| `GET /news/:idOrSlug` | JWT | 뉴스 게시물 상세. |
| `GET /app-config` | JWT | 앱에 노출되는 구성 플래그. |

---

## 10. 관리자 인증 — `/api/admin/auth`

| 메서드 & 경로 | 인증 | 설명 |
|---------------|------|------|
| `POST /admin/auth/signup` | 공개* | 관리자 생성. 첫 가입 → `superadmin`, 이후 → `admin`. *보안 명세서 참조 — 공개 배포 전 차단 필요.* |
| `POST /admin/auth/signin` | 공개 | 관리자 로그인. |
| `POST /admin/auth/refresh` | 공개 | 관리자 리프레시 토큰 회전. |
| `POST /admin/auth/signout` | JWT | 관리자 리프레시 토큰 무효화. |

## 11. 관리 작업

모두 `actor=admin`과 명시된 권한을 요구한다(`superadmin`은 권한 검사를
우회한다).

| 영역 | 엔드포인트 | 권한 |
|------|-----------|------|
| 관리자 | `GET/POST /admin/admins`, `GET /admin/admins/me/permissions`, `PUT /admin/admins/:id/permissions`, `POST\|DELETE /admin/admins/:id/permissions/:perm`, `POST /admin/admins/:id/suspend\|restore`, `DELETE /admin/admins/:id` | `admins.*`(생성은 superadmin 전용) |
| 통계 | `GET /admin/stats` | 모든 관리자 |
| 사용자 | `GET /admin/users`, `GET /admin/users/:id`, `POST /admin/users/:id/suspend\|restore`, `POST /admin/users/:id/reset-password` | `users.view`, `users.suspend`, `users.reset_password` |
| 시나리오 | `GET/POST /admin/scenarios`, `GET/PATCH /admin/scenarios/:id`, `POST /admin/scenarios/:id/publish\|archive`, `DELETE`, `POST /admin/scenarios/:id/image` | `scenarios.view\|edit\|delete\|upload_image` |
| 페르소나 | `GET/POST /admin/personas`, `GET/PATCH /admin/personas/:id`, `DELETE`, `POST /admin/personas/:id/restore\|image` | `personas.edit` |
| 카테고리 | `GET/POST /admin/categories`, `GET/PATCH /admin/categories/:id`, `DELETE` | `categories.view\|edit\|delete` |
| 리더보드 | `GET /admin/leaderboard`(지표: `xp_total\|streak_days\|current_level`) | `leaderboard.view` |
| 프롬프트 템플릿 | `GET /admin/prompt-templates`, `GET/PATCH /admin/prompt-templates/:kind` | `prompts.view\|edit` |
| 뉴스 | `GET/POST /admin/news`, `GET/PATCH /admin/news/:id`, `POST /admin/news/:id/publish\|archive`, `DELETE` | `news.view\|edit\|delete` |
| 감사 | `GET /admin/audit`(actor/action/target/since/until 필터) | `audit.view` |
| 설정 | `GET /admin/config`, `GET/PATCH /admin/config/:key`, `POST /admin/config/reset/:key`, `POST /admin/config/reset-all` | `config.view\|edit`(reset-all은 superadmin 전용) |

---

## 12. 이미지 업로드

`POST /admin/scenarios/:id/image`와 `POST /admin/personas/:id/image`는
`multipart/form-data`를 받는다. 제약: 타입 `jpeg`/`png`/`webp`, 크기
≤ 5 MB. 저장된 파일 메타데이터를 반환한다.

## 13. OpenAPI

요청·응답 스키마를 포함한 완전한 최신 명세는 `/api/docs`의 Swagger
UI가 제공한다(nginx 뒤에서 스펙 JSON은 `/vfls/docs-json`).

---

*API 레퍼런스 끝.*
