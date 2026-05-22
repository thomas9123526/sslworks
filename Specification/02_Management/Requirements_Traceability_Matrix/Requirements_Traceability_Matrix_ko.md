---
title: "vLearn2 (VFLS) — 요구사항 추적 매트릭스"
author: "vLearn2 엔지니어링"
date: "2026-05-22"
---

# 요구사항 추적 매트릭스

**프로젝트:** vLearn2 (VFLS) · **버전:** 1.0 · **작성일:** 2026-05-22

본 매트릭스는 요구사항 명세서(SRS)의 모든 요구사항을 그것을 실현하는
시스템 설계 명세서(SDS) 절 및 그것을 검증하는 테스트 명세서 테스트
케이스와 연결한다. 커버리지 및 영향 분석을 위한 통제 산출물이다.

**범례** — SDS 참조는 시스템 설계 명세서의 절 번호이며, TC 참조는
테스트 명세서의 테스트 케이스 ID이다.

---

## 1. 기능 요구사항

| 요구사항 | 설명(요약) | SDS 절 | 테스트 케이스 |
|----------|------------|--------|---------------|
| FR-AUTH-1 | 학습자 가입 | 6.2 | TC-AUTH-1, TC-AUTH-2 |
| FR-AUTH-2 | 학습자 로그인 | 6.2 | TC-AUTH-3, TC-AUTH-4 |
| FR-AUTH-3 | 토큰 갱신/회전 | 6.2 | TC-AUTH-5, TC-AUTH-6 |
| FR-AUTH-4 | 로그아웃 | 6.2 | TC-AUTH-7 |
| FR-AUTH-5 | 무효 토큰 거부 | 3.3, 6.2 | TC-AUTH-8, TC-AUTH-9 |
| FR-AUTH-6 | 자격 증명 기억 | 8.5 | TC-AUTH-12 |
| FR-AUTH-7 | 관리자 계정 생성 | 6.2 | TC-AUTH-10 |
| FR-AUTH-8 | 첫 관리자 = superadmin | 6.2 | TC-AUTH-11 |
| FR-PROF-1 | 프로필 조회 | 6.1 | TC-PROF-1 |
| FR-PROF-2 | 프로필 수정 | 6.1 | TC-PROF-2 |
| FR-PROF-3 | 비밀번호 변경 | 6.1, 6.2 | TC-PROF-3, TC-PROF-4 |
| FR-PROF-4 | 온보딩 추적 | 8.3 | TC-PROF-5 |
| FR-CONT-1 | 페르소나 카탈로그 | 6.1 | TC-CONT-1 |
| FR-CONT-2 | 시나리오 카탈로그+필터 | 6.1 | TC-CONT-2, TC-CONT-3 |
| FR-CONT-3 | 시나리오 상세 | 6.1 | TC-CONT-4 |
| FR-CONT-4 | 카테고리 목록 | 6.1 | TC-CONT-1 |
| FR-CONT-5 | 코스 | 6.1 | TC-CONT-5 |
| FR-CONT-6 | 지역화 콘텐츠 | 9.3 | TC-CONT-6 |
| FR-CONV-1 | 세션 시작 | 6.1, 6.3 | TC-CONV-1, TC-CONV-2 |
| FR-CONV-2 | 채팅/얼굴 모드 | 8.3 | TC-CONV-1 |
| FR-CONV-3 | 메시지 전송+응답 | 6.3 | TC-CONV-3, TC-CONV-4 |
| FR-CONV-4 | 메시지 영속화 | 5.2 | TC-CONV-5 |
| FR-CONV-5 | 유휴 추천 | 6.3 | TC-CONV-6 |
| FR-CONV-6 | 세션 종료 | 6.1 | TC-CONV-7 |
| FR-CONV-7 | 세션 목록/삭제 | 6.1 | TC-CONV-8, TC-CONV-9 |
| FR-CONV-8 | AI 대체 응답 | 6.3 | TC-CONV-10 |
| FR-CONV-9 | 일일 AI 메시지 한도 | 6.3, 6.6 | TC-CONV-11 |
| FR-SCORE-1 | 다중 스킬 점수 | 5.2, 6.3 | TC-SCORE-1 |
| FR-SCORE-2 | 강점/개선점 | 5.2 | TC-SCORE-2 |
| FR-SCORE-3 | 알고리즘 채점 대체 | 6.3 | TC-SCORE-3 |
| FR-SCORE-4 | 세션 리포트 | 8.3 | TC-SCORE-4 |
| FR-PROG-1 | 종합 진행도 | 5.2 | TC-PROG-1 |
| FR-PROG-2 | 일별 스킬 스냅샷 | 5.2 | TC-PROG-2 |
| FR-PROG-3 | 시나리오 완료 | 5.2 | TC-PROG-3 |
| FR-PROG-4 | XP와 레벨 | 5.2 | TC-PROG-4 |
| FR-PROG-5 | 업적 부여 | 5.2 | TC-PROG-5 |
| FR-PROG-6 | 업적 조회 | 6.1 | TC-PROG-6 |
| FR-NEWS-1 | 뉴스 목록 | 6.1 | TC-NEWS-1 |
| FR-NEWS-2 | 읽음 상태/미읽음 수 | 5.2 | TC-NEWS-2 |
| FR-NEWS-3 | 읽음 처리 | 6.1 | TC-NEWS-3 |
| FR-CFG-1 | 앱 노출 구성 플래그 | 6.6 | TC-ADM-16 |
| FR-OFF-1 | 로컬 캐시 | 8.5 | TC-OFF-1 |
| FR-OFF-2 | 오프라인 읽기 모드 | 8.5, 9.2 | TC-OFF-2 |
| FR-OFF-3 | 보안 토큰 저장 | 8.5 | TC-OFF-3 |
| FR-SPCH-1 | STT/TTS | 8.6 | TC-SPCH-4 |
| FR-SPCH-2 | 음성 모델 게이트 | 8.3, 8.6 | TC-SPCH-1, TC-SPCH-2 |
| FR-SPCH-3 | `.ddp` 서명 검증 | 8.6, 2.5 | TC-SPCH-3, TC-SPCH-4 |
| FR-ADM-1 | 시나리오 관리 | 6.1 | TC-ADM-1 |
| FR-ADM-2 | 페르소나 관리 | 6.1 | TC-ADM-2 |
| FR-ADM-3 | 카테고리 관리 | 6.1 | TC-ADM-3 |
| FR-ADM-4 | 이미지 업로드 | 6.5 | TC-ADM-4 |
| FR-ADM-5 | 뉴스 관리 | 6.1 | TC-ADM-5 |
| FR-ADM-6 | 프롬프트 템플릿 | 6.3 | TC-ADM-6 |
| FR-ADM-7 | 사용자 조회 | 6.1 | TC-ADM-7 |
| FR-ADM-8 | 사용자 정지/재설정 | 6.1 | TC-ADM-7 |
| FR-ADM-9 | 요약 통계 | 6.1 | TC-ADM-8 |
| FR-ADM-10 | 리더보드 | 6.1 | TC-ADM-9 |
| FR-ADM-11 | 서브 관리자·권한 | 6.2 | TC-ADM-10 |
| FR-ADM-12 | 부여 불가 권한 | 6.2 | TC-ADM-11 |
| FR-ADM-13 | 관리자 수명주기 | 6.2 | TC-ADM-10 |
| FR-ADM-14 | 감사 로그 | 6.2, 9.2 | TC-ADM-14, TC-ADM-15 |
| FR-ADM-15 | 런타임 구성 | 6.6 | TC-ADM-16 |
| FR-ADM-16 | RBAC 시행 | 6.2, 7.3 | TC-ADM-12, TC-ADM-13 |
| FR-SAFE-1 | 서버 콘텐츠 가드 | 6.4 | TC-SAFE-1 |
| FR-SAFE-2 | 클라이언트 콘텐츠 가드 | 8.1 | TC-SAFE-2 |
| FR-PKG-1 | `.ddp` 패키징 | 4.4 | TC-PKG-1 |
| FR-PKG-2 | 서명/암호화/압축 | 2.5, 4.4 | TC-PKG-2, TC-PKG-3 |
| FR-PKG-3 | GUI/CLI 모드 | 4.4 | TC-PKG-1 |

## 2. 비기능 요구사항

| 요구사항 | 설명(요약) | SDS 절 | 테스트 케이스 |
|----------|------------|--------|---------------|
| NFR-SEC-1 | bcrypt 비밀번호 해싱 | 6.2, 9.4 | TC-NFR-SEC-1 |
| NFR-SEC-2 | 해시된 1회용 리프레시 토큰 | 6.2 | TC-NFR-SEC-2 |
| NFR-SEC-3 | 기본 인증 요구 | 3.3 | TC-NFR-SEC-3 |
| NFR-SEC-4 | 서버 측 인가 | 6.2, 7.3 | TC-ADM-12 |
| NFR-SEC-5 | 속도 제한 | 3.3 | TC-NFR-SEC-4 |
| NFR-SEC-6 | 환경 변수 비밀값 | 6.6, 9.4 | TC-NFR-SEC-5 |
| NFR-SEC-7 | 서명 모델 번들 | 2.5, 8.6 | TC-SPCH-3 |
| NFR-SEC-8 | TLS 전용 토큰 전송 | 9.4 | TC-NFR-SEC-3 |
| NFR-PERF-1 | gzip 압축 | 3.3 | TC-NFR-PERF-1 |
| NFR-PERF-2 | 캐시된 읽기 화면 | 8.5, 9.2 | TC-OFF-2 |
| NFR-PERF-3 | 스레드 외 `.ddp` 해제 | 8.6 | TC-NFR-PERF-2 |
| NFR-REL-1 | 헬스 엔드포인트 | 10.2 | TC-NFR-REL-1 |
| NFR-REL-2 | 우아한 AI 성능 저하 | 6.3 | TC-NFR-REL-2 |
| NFR-REL-3 | 원자적 감사 기록 | 9.2 | TC-NFR-REL-3 |
| NFR-USE-1 | 사용자 안전 오류 | 9.2 | TC-NFR-USE-1 |
| NFR-USE-2 | 지역화 표시 | 9.3 | TC-CONT-6 |
| NFR-USE-3 | 온보딩 | 8.3 | TC-PROF-5 |
| NFR-PORT-1 | Android + Windows | 8.7 | TC-NFR-PORT-1 |
| NFR-PORT-2 | Linux + Windows 백엔드 | 10 | — (배포 검증) |
| NFR-MAINT-1 | 모듈형 백엔드 | 3.2 | — (설계 검토) |
| NFR-MAINT-2 | 버전 관리 마이그레이션 | 5.1 | — (설계 검토) |
| NFR-MAINT-3 | 편집 가능 프롬프트 템플릿 | 6.3 | TC-ADM-6 |
| NFR-AUD-1 | 감사 완전성 | 6.2 | TC-ADM-14 |

## 3. 커버리지 참고

- 모든 `FR-*`는 최소 한 개의 테스트 케이스에 매핑된다.
- `NFR-PORT-2`, `NFR-MAINT-1`, `NFR-MAINT-2`는 자동화 테스트 케이스가
  아닌 배포 점검과 설계 검토로 검증된다 — 이는 의도적으로 기록된다.
- 요구사항·설계 절·테스트 케이스가 추가·변경될 때마다 매트릭스를
  갱신해야 한다. 매칭되지 않은 요구사항은 릴리스 차단 항목으로 취급
  하라.

---

*요구사항 추적 매트릭스 끝.*
