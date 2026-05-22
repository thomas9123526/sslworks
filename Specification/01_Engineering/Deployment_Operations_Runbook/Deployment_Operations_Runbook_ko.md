---
title: "vLearn2 (VFLS) — 배포 및 운영 런북"
author: "vLearn2 엔지니어링"
date: "2026-05-22"
---

# 배포 및 운영 런북

**프로젝트:** vLearn2 (VFLS) · **버전:** 1.0 · **작성일:** 2026-05-22

---

## 1. 목적

vLearn2 백엔드와 관리자 패널의 배포·구성·실행·모니터링·복구를 위한
운영 참조 문서이다. Flutter 앱은 앱 스토어/직접 배포로 제공되며 구성
파일을 제외하고는 본 문서의 범위 밖이다.

## 2. 대상 환경

- **호스트 OS:** Linux(RHEL 계열) 또는 Windows.
- **런타임:** Node.js 22+.
- **데이터베이스:** PostgreSQL 16.
- **리버스 프록시:** TLS를 종단하는 nginx.
- **프로세스 관리자:** `pm2` 또는 제공된 `cmds/` 런처.

## 3. 구성 요소 & 포트

| 구성 요소 | 프로세스 | 내부 포트 |
|-----------|----------|-----------|
| 백엔드 API | `node dist/main` | 3000(또는 `PORT`) |
| 관리자 패널 | `next start` | 4100 |
| PostgreSQL | 서비스/컨테이너 | 5432 |

> `cmds/` 시작 스크립트는 기본 포트가 상충한다(일부 위치에서 백엔드
> 4101 / 관리자 5101). 의존하기 전에 단일 표준 매핑으로 정리하라;
> 위 값은 코드 기본값이다.

nginx 라우팅: `/vfls/*` → 백엔드 `/api/*`; `/vAdmin/*` → 관리자 패널.

## 4. 배포 절차

### 4.1 데이터베이스

```bash
# PostgreSQL 16 프로비저닝(관리형 서비스, 또는 개발용:)
docker compose up -d postgres
# 스키마 적용
cd backend && npm run db:migrate
# 참조 콘텐츠 시딩(멱등)
npm run db:seed
```

### 4.2 백엔드

```bash
cd backend
npm ci
npm run build            # nest build -> dist/
# .env 구성(§5 참조)
npm run start:prod       # node dist/main
```

### 4.3 관리자 패널

```bash
cd admin_panel
npm ci
# NEXT_PUBLIC_API_BASE_URL 및 BACKEND_BASE_URL 설정(§5 참조)
npm run build            # next build
npm run start            # next start -p 4100
```

`NEXT_PUBLIC_*` 값은 빌드 시 인라인된다 — 변경 후 재빌드하라.

### 4.4 리버스 프록시

nginx가 TLS를 종단하고 `/vfls/*`와 `/vAdmin/*`를 라우팅하도록 구성한다.
전체 API에 HTTPS를 시행하라(HTTP 80 포트는 443으로 `301` 리디렉션만).
SELinux가 enforcing인 RHEL에서는 아웃바운드 프록시 연결을 허용하라:
`setsebool -P httpd_can_network_connect 1`.

### 4.5 서비스 관리

`cmds/` 런처 또는 `pm2`를 사용한다:

```bash
./cmds/start_service_linux.sh 3000 4100
# 또는 pm2: pm2 start ... ; pm2 save ; pm2 startup
```

## 5. 구성 참조

### 백엔드 `.env`

| 변수 | 목적 |
|------|------|
| `NODE_ENV`, `PORT` | 환경, 리스닝 포트 |
| `PUBLIC_BASE_URL`, `CORS_ORIGINS` | 공개 URL, CORS 허용 목록 |
| `DB_HOST/PORT/NAME/USER/PASSWORD`, `DB_LOGGING` | 데이터베이스 |
| `JWT_ACCESS_SECRET/EXPIRES`, `JWT_REFRESH_SECRET/EXPIRES` | JWT |
| `AI_PROVIDER`, `AI_CHAT_MODEL`, `AI_ANALYSIS_MODEL`, `ANTHROPIC_API_KEY` / `OPENAI_*` | AI 제공자 |
| `STORAGE_PROVIDER`, `LOCAL_UPLOAD_DIR` / `S3_*`, `UPLOADS_DIR` | 파일 스토리지 |
| `THROTTLE_TTL_SECONDS`, `THROTTLE_LIMIT`, `MAX_AI_MESSAGES_PER_DAY` | 한도 |
| `GZIP_ENABLED`, `GZIP_THRESHOLD_BYTES` | 압축 |

### 관리자 패널 `.env`

| 변수 | 목적 |
|------|------|
| `NEXT_PUBLIC_API_BASE_URL` | 브라우저 측 API 기준(동일 출처 `/vfls` 경로 사용) |
| `BACKEND_BASE_URL` | 서버 측 재작성 대상 |

### Flutter `app_config.json` (기기 내)

`baseurl`(API 기준), `reqTout`, `tSync`, `dev`. Windows `.exe` 옆 또는
Android 공유 구성 폴더에 위치한다.

## 6. 헬스 & 모니터링

- **라이브니스:** `GET /health` → `{ "status": "ok" }`. 로드 밸런서/
  업타임 모니터에 연결하라.
- **로그:** 백엔드는 NestJS 로거를 사용한다; Linux 런처는
  `<repo>/logs/`에 기록한다. `DB_LOGGING=true`는 짧은 진단에만 설정
  하라.
- **핵심 신호:** 5xx 비율, `/vfls/*`의 p95 지연, PostgreSQL 연결 수,
  AI 제공자 오류율, `429` 비율.

## 7. 정기 운영

| 작업 | 절차 |
|------|------|
| 새 버전 배포 | 빌드 → (스키마 변경 시) 마이그레이션 → 백엔드/관리자 재시작 |
| DB 마이그레이션 적용 | `npm run db:migrate`(먼저 백업) |
| 비밀값 회전 | `.env` 갱신, 해당 서비스 재시작 |
| 첫 관리자 | 부트스트랩 `admin/auth/signup`을 한 번 사용한 후 라우트 차단 |
| 기능 플래그 전환 | 관리자 패널 → 설정 페이지 |

## 8. 백업 & 복구

- **데이터베이스:** `pg_dump`(또는 관리형 스냅샷)를 스케줄링한다.
  복원을 주기적으로 검증하라.
- **업로드:** `UPLOADS_DIR`(로컬 제공자)를 백업하거나 S3 내구성에
  의존한다.
- **복구:** PostgreSQL 프로비저닝, 덤프 복원, `db:migrate`로 헤드
  확인, 서비스 재시작.
- **RPO/RTO:** 환경별로 정의하고 달성값을 문서화하라.

## 9. 인시던트 대응

| 증상 | 1차 점검 |
|------|----------|
| nginx `502` | 백엔드/관리자 프로세스 다운 — `pm2 status` / `ss -ltnp`; 재시작 |
| 로그인 실패 | JWT 비밀값 불일치; DB 접근성; 시계 오차 |
| 회화 오류 | AI 제공자 접근성; `MAX_AI_MESSAGES_PER_DAY` 미초과; 대체 경로 확인 |
| 느린 응답 | DB 연결/잠금; AI 지연; CPU |
| `429` 급증 | 속도 제한; 남용 대 정상 부하 확인 |

롤백: 이전 빌드 산출물을 재배포한다; 마이그레이션이 관련되면 백업에서
복원한다(프로덕션에서 TypeORM 마이그레이션은 자동 다운되지 않는다).

## 10. 프로덕션 준비 체크리스트

- [ ] 전체 API에 HTTPS 시행; HTTP는 HTTPS로 리디렉션.
- [ ] 첫 관리자 생성 후 `admin/auth/signup` 차단.
- [ ] `CORS_ORIGINS`를 명시적 허용 목록으로 설정.
- [ ] 강력하고 고유한 JWT 비밀값과 DB 비밀번호.
- [ ] 프로덕션 Android 키스토어 구성.
- [ ] 백업 스케줄링 및 복원 테스트 완료.
- [ ] `/health`를 모니터링에 연결.
- [ ] CI 트리거 브랜치를 배포 브랜치와 정렬.

---

*배포 및 운영 런북 끝.*
