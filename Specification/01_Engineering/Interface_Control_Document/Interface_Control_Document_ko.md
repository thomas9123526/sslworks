---
title: "vLearn2 (VFLS) — 인터페이스 통제 문서"
author: "vLearn2 엔지니어링"
date: "2026-05-22"
---

# 인터페이스 통제 문서

**프로젝트:** vLearn2 (VFLS) · **버전:** 1.0 · **작성일:** 2026-05-22

---

## 1. 목적

본 문서는 vLearn2 서브시스템 간 및 외부 시스템과의 인터페이스 —
프로토콜, 데이터 형식, 계약 — 를 정의하여, 각 측이 안정적인 합의에
대해 개발·변경될 수 있도록 한다.

## 2. 인터페이스 목록

| ID | 출발 | 도착 | 프로토콜 |
|----|------|------|----------|
| IF-1 | Flutter 앱 | 백엔드 API | HTTPS / REST |
| IF-2 | 관리자 패널(브라우저) | 백엔드 API | HTTPS / REST |
| IF-3 | 관리자 패널(서버) | 백엔드 API | HTTP(S) / REST(재작성 프록시) |
| IF-4 | 백엔드 | PostgreSQL | TCP / SQL(TypeORM) |
| IF-5 | 백엔드 | AI 제공자 | HTTPS / 벤더 SDK |
| IF-6 | 백엔드 | 파일 스토리지 | 로컬 FS 또는 S3 API |
| IF-7 | DataManage 도구 | Flutter 앱 | `.ddp` 파일(오프라인 산출물) |
| IF-8 | 클라이언트 | nginx | HTTPS(TLS 종단) |

---

## 3. IF-1 — Flutter 앱 ↔ 백엔드 API

- **프로토콜:** HTTPS 기반 REST; JSON 본문.
- **공개 경로:** `https://<host>/vfls/*`, nginx가 `/api/*`로 매핑.
- **인증:** `Authorization: Bearer <액세스 토큰>`; 갱신은
  `POST /vfls/auth/refresh`.
- **기준 URL 구성:** `app_config.json`(`baseurl`)에서 런타임에 읽음;
  빌드 시 `--dart-define=API_BASE_URL` 재정의.
- **오류 계약:** 2xx가 아닌 본문은 `i18nKey`를 포함; 앱은 실패를
  사용자 안전 메시지로 매핑한다.
- **버전 관리:** `/api/docs`의 OpenAPI 명세가 기록상의 계약이다.

## 4. IF-2 / IF-3 — 관리자 패널 ↔ 백엔드 API

- **IF-2(브라우저):** `NEXT_PUBLIC_API_BASE_URL`로의 `fetch` 기반
  클라이언트; `sessionStorage`의 베어러 토큰; `401` 시 자동 1회 갱신.
- **IF-3(서버):** Next.js 재작성 — `/api/backend/*` →
  `${BACKEND_BASE_URL}/api/*` — 서버 측 호출용.
- **인증:** 관리자 JWT(`actor=admin`) + 서버 측 권한 검사.

## 5. IF-4 — 백엔드 ↔ PostgreSQL

- **프로토콜:** TypeORM이 관리하는 `pg` 드라이버를 통한 PostgreSQL
  와이어 프로토콜.
- **연결:** `DB_HOST/PORT/NAME/USER/PASSWORD`.
- **스키마 계약:** 26개 엔티티; 변경은 순서화된 마이그레이션을 통해서만
  (데이터베이스 설계 문서 참조).
- **무결성:** `ON DELETE CASCADE`(사용자 정보), `ON DELETE
  RESTRICT`(시나리오 카테고리).

## 6. IF-5 — 백엔드 ↔ AI 제공자

- **프로토콜:** 벤더 SDK(`@anthropic-ai/sdk` 또는 `openai`)를 통한
  HTTPS.
- **선택:** `AI_PROVIDER` 환경 변수(`anthropic` |
  `openai-compatible`); 모델은 `AI_CHAT_MODEL` / `AI_ANALYSIS_MODEL`.
- **인증:** API 키(`ANTHROPIC_API_KEY` / `OPENAI_API_KEY`).
- **실패 계약:** `AiProviderError` 시 백엔드는 미리 준비된 대체 응답을
  반환하고 알고리즘 문법 채점을 사용한다 — 클라이언트 인터페이스는
  영향받지 않는다.
- **할당량:** 학습자당 `MAX_AI_MESSAGES_PER_DAY`.

## 7. IF-6 — 백엔드 ↔ 파일 스토리지

- **프로토콜:** `STORAGE_PROVIDER`에 따라 로컬 파일시스템 또는 S3 API.
- **입력:** 이미지 `jpeg`/`png`/`webp`, ≤ 5 MB.
- **계약:** 저장 객체는 `storage_key`로 키잉; 메타데이터는
  `vl_uploaded_files`; 정적 파일은 `/uploads/`에서 제공.

## 8. IF-7 — DataManage ↔ Flutter 앱

- **산출물:** `.ddp` 번들 — 서명되고 선택적으로 암호화·압축됨.
- **생산자:** DataManage Win32 도구(오프라인).
- **소비자:** Flutter 앱의 `core/datapack/` 해제기, 백그라운드
  아이솔레이트에서.
- **신뢰 계약:** 앱은 `root_ca.crt`를 고정한다; 고정 CA에 대해 서명이
  검증되지 않는 번들은 거부된다.
- **전송:** 대역 외(다운로드/사이드로드) — 네트워크 API가 아니다.

## 9. IF-8 — 클라이언트 ↔ nginx

- **프로토콜:** HTTPS; nginx가 TLS를 종단한다.
- **라우팅 계약:** `/vfls/*` → 백엔드, `/vAdmin/*` → 관리자 패널;
  HTTP는 HTTPS로 `301` 리디렉션.
- **헤더:** `X-Forwarded-Proto`, `X-Forwarded-For`, `Host`를 상위로
  전달.

## 10. 변경 통제

인터페이스 계약의 변경(라우트, 페이로드 형태, 환경 변수 이름,
`.ddp` 형식, nginx 경로 매핑)은 다음을 요구한다.

1. 본 문서와 영향받는 상세 명세(API 레퍼런스 / 데이터베이스 설계
   문서) 갱신.
2. 해당 인터페이스의 모든 소비자에 대한 호환성 평가.
3. 생산자와 소비자가 함께 이동해야 하는 조율된 릴리스.

---

*인터페이스 통제 문서 끝.*
