---
title: "vLearn2 (VFLS) — 데이터베이스 설계 문서"
subtitle: "PostgreSQL 16 데이터 모델"
author: "vLearn2 엔지니어링"
date: "2026-05-22"
---

# 데이터베이스 설계 문서

**프로젝트:** vLearn2 (VFLS) · **버전:** 1.0 · **작성일:** 2026-05-22
**DBMS:** PostgreSQL 16 · **ORM:** TypeORM 0.3

---

## 1. 개요

vLearn2 데이터베이스는 모든 영속 데이터의 기록 원본이다. NestJS
백엔드가 TypeORM(26개 엔티티)을 통해 독점적으로 접근한다. 규약:

- **기본 키:** UUID, `gen_random_uuid()`(pgcrypto)로 생성.
- **테이블 접두사:** 대부분의 테이블에 `vl_`(`users` 테이블은 예외).
- **지역화 텍스트:** 다국어 콘텐츠를 위해 JSONB(`I18nText`)로 저장.
- **타임스탬프:** `timestamptz`.
- **스키마 변경:** 순서가 있는 13개 TypeORM 마이그레이션;
  `vl_migrations`에서 추적.
- **시딩:** 시드 러너가 기본 업적·앱 설정·코스·페르소나·시나리오를
  적재.

## 2. 개체-관계 개요

```
users 1───1 vl_user_info
users 1───N vl_refresh_tokens
vl_admins 1───N vl_admin_refresh_tokens
vl_admins 1───N vl_admin_audit_log (행위자)

vl_categories 1───N vl_scenarios
vl_courses N───M vl_scenarios  (vl_course_scenarios 경유)

users 1───N vl_conversation_sessions
vl_conversation_sessions 1───N vl_conversation_messages
vl_conversation_sessions 1───1 vl_session_scores
vl_scenarios 0..1───N vl_conversation_sessions  (null = 자유 대화)
vl_personas 1───N vl_conversation_sessions

users 1───1 vl_user_progress
users 1───N vl_skill_snapshots
users 1───N vl_user_scenario_completions
users N───M vl_achievements  (vl_user_achievements 경유)
users N───M vl_news_posts    (vl_news_read_status 경유)
```

## 3. 도메인 그룹

### 3.1 식별 및 접근

**`users`** — 학습자 계정. `id`(PK, uuid), `password_hash`(varchar
255, 기본 미선택), `name`(varchar 100), `cid`(varchar 10, nullable),
`cid_username`(varchar 50, nullable), `gender`(varchar 20, 기본
`unspecified`), `created_at`, `updated_at`. 일대일 `info` →
`vl_user_info`(eager, cascade).

**`vl_user_info`** — 학습자 프로필. `user_id`(PK/FK → `users`,
`ON DELETE CASCADE`), `email`(varchar 255, unique), `avatar_emoji`,
`native_language`/`ui_language`(기본 `en`), `current_level`(smallint,
기본 1), `xp_total`(int), `streak_days`(smallint), `last_active_date`,
`active_persona_id`, `active_theme`, `onboarding_done`(bool), `role`,
`status`, `suspended_until`, `suspended_reason`,
`leaderboard_opt_in`(기본 true). `xp_total`, `streak_days` 인덱스.

**`vl_refresh_tokens`** — `id`(PK), `user_id`, `token_hash`(SHA-256),
`expires_at`, `created_at`.

**`vl_admins`** — 운영 인력 계정. `id`(PK), `email`(unique),
`password_hash`(미선택), `display_name`, `role`(기본 `admin`),
`status`(기본 `active`), `last_login_at`, `created_at`, `updated_at`.

**`vl_admin_refresh_tokens`** — `id`, `admin_id`, `token_hash`,
`expires_at`, `created_at`.

**`vl_admin_permissions`** — 복합 PK(`user_id`, `permission`),
`granted_by`, `granted_at`.

**`vl_admin_audit_log`** — `id`(PK), `user_id`(행위자, nullable),
`action`, `target_type`, `target_id`, `old_value`/`new_value`/
`metadata`(jsonb). 쿼리 성능을 위한 3개 복합 인덱스.

### 3.2 학습 콘텐츠

**`vl_personas`** — `id`(PK), `slug`(unique), `name`, `accent`,
`style`, `specialties`(jsonb string[]), `gradient_from`/`gradient_to`,
`rive_asset`, `image_url`, `image_storage_key`, `is_active`(기본
true), `gender`(`female`/`male`/`neutral`), `voice_id`.

**`vl_categories`** — `id`(PK), `slug`(unique, 불변),
`title`(jsonb I18nText), `description`(jsonb), `order_index`,
`is_active`, `created_at`.

**`vl_scenarios`** — `id`(PK), `slug`(unique), `category`(slug,
비정규화), `category_id`(FK → `vl_categories`, `ON DELETE RESTRICT`),
`difficulty`(smallint), `title`/`description`/`scene_description`/
`user_role`/`tutor_role`(jsonb I18nText), `objectives`(jsonb),
`key_phrases`(jsonb), `estimated_minutes`, `xp_reward`, `order_index`,
`image_*`, `author_id`, `status`, `published_at`, `created_at`.
`status`, `category`, `difficulty`, `category_id` 인덱스.

**`vl_courses`** — `id`(PK), `slug`(unique), `title`/`description`
(jsonb), `level_range`, `total_xp`, `order_index`, `image_url`,
`status`, `published_at`.

**`vl_course_scenarios`** — `id`(PK), `course_id`, `scenario_id`,
`order_index`. 코스↔시나리오 다대다 조인 테이블.

**`vl_prompt_templates`** — `id`(PK), `kind`(unique), `label`,
`description`, `template`(text), `is_active`, `updated_at`.

### 3.3 회화 및 채점

**`vl_conversation_sessions`** — `id`(PK), `user_id`,
`scenario_id`(nullable; null = 자유 대화), `persona_id`, `mode`,
`status`(기본 `active`), `started_at`, `ended_at`,
`duration_seconds`, `turn_count`, `word_count`, `xp_earned`.

**`vl_conversation_messages`** — `id`(PK), `session_id`, `role`,
`content`(text), `sequence`(int), `audio_url`, `created_at`.

**`vl_session_scores`** — `id`(PK), `session_id`(unique),
`overall_score` 및 스킬별 점수(`pronunciation`, `fluency`,
`vocabulary`, `grammar`, `engagement`, `listening` — smallint,
nullable), 스킬별 `*_metrics`(jsonb), `strengths`/`improvements`
(text[]), `ai_feedback`(text), `evaluator_versions`(jsonb),
`computed_at`.

### 3.4 진행도 및 게임화

**`vl_user_progress`** — `id`(PK), `user_id`(unique),
`sessions_total`, `sessions_this_week`, `minutes_spoken_total`,
`minutes_spoken_this_week`, `words_spoken_total`,
`scenarios_completed`, `current_streak`, `longest_streak`,
`level_history`(jsonb), `updated_at`.

**`vl_skill_snapshots`** — `id`(PK), unique(`user_id`,
`snapshot_date`), `pronunciation`/`fluency`/`listening`(nullable),
`vocabulary`/`grammar`(기본 0), `sessions_in_window`,
`confidence`(기본 50).

**`vl_user_scenario_completions`** — `id`(PK), `user_id`,
`scenario_id`, `best_score`, `completion_count`(기본 1),
`first_completed_at`, `last_completed_at`.

**`vl_achievements`** — `id`(PK), `key`(unique),
`title`/`description`(jsonb), `icon`, `xp_reward`, `condition_type`,
`condition_value`.

**`vl_user_achievements`** — 복합 PK(`user_id`, `achievement_id`),
`earned_at`.

### 3.5 플랫폼

**`vl_app_config`** — `key`(PK), `value`(jsonb), `value_type`,
`category`, `description`, `default_value`(jsonb),
`is_visible_to_app`(기본 true), `updated_at`, `updated_by`.

**`vl_news_posts`** — `id`(PK), `slug`(unique), `title`/`body`(jsonb),
`summary`(jsonb), `image_*`, `author_id`, `status`(기본 `draft`),
`pinned`(bool), `published_at`, `created_at`, `updated_at`.

**`vl_news_read_status`** — 복합 PK(`user_id`, `news_post_id`),
`read_at`.

**`vl_guard_violations`** — `id`(PK), `user_id`,
`session_id`(nullable), `attempted_content`(text),
`matched_terms`(text[]), `severity`, `language`, `source`,
`user_acknowledged_warn`(bool), `created_at`.

**`vl_uploaded_files`** — `id`(PK), `storage_key`(unique),
`original_filename`, `mime_type`, `size_bytes`, `width`/`height`,
`content_hash`(varchar 64), `reference_count`(int, 기본 1),
`uploader_id`, `folder`, `storage_provider`, `created_at`.

## 4. 열거형

| 열거형 | 값 |
|--------|-----|
| `UserRole` | `user`, `admin`, `superadmin` |
| `UserStatus` / `AdminStatus` | `active`, `suspended`, `deleted` |
| `AdminRole` | `admin`, `superadmin` |
| `ScenarioStatus` / `CourseStatus` / `NewsStatus` | `draft`, `published`, `archived` |
| `ConversationMode` | `chat`, `face` |
| `SessionStatus` | `active`, `completed`, `abandoned` |
| `MessageRole` | `user`, `assistant` |
| `GuardSeverity` | `block`, `warn` |
| `GuardSource` | `client`, `server` |
| `PromptKind` | `tutor_system`, `grammar`, `feedback` |
| `AppConfigCategory` | `home`, `evaluation`, `progress`, `conversation`, `scenarios`, `settings`, `system` |
| `AppConfigValueType` | `boolean`, `string`, `number`, `object`, `array` |

열거 값은 네이티브 PostgreSQL `ENUM`이 아니라 `varchar`로 저장되며
애플리케이션 계층에서 제약된다.

## 5. 참조 무결성

- `vl_user_info.user_id` → `users.id` — `ON DELETE CASCADE`.
- `vl_scenarios.category_id` → `vl_categories.id` — `ON DELETE
  RESTRICT`(사용 중인 카테고리는 삭제 불가; API는 `409` 반환).
- 회화 메시지와 점수는 논리적으로 해당 세션에 속한다.

## 6. 인덱싱 요약

| 테이블 | 인덱스 컬럼 | 목적 |
|--------|-------------|------|
| `vl_user_info` | `xp_total`, `streak_days` | 리더보드 순위 |
| `vl_scenarios` | `status`, `category`, `difficulty`, `category_id` | 카탈로그 필터링 |
| `vl_admin_audit_log` | 복합 인덱스 3개 | 감사 검색 |
| `vl_skill_snapshots` | unique(`user_id`,`snapshot_date`) | 일별 단일 스냅샷 |

## 7. 마이그레이션 & 시딩

13개 마이그레이션 파일이 초기 스키마부터 `vl_` 접두사 도입, 관리자
별도 테이블 분리, 페르소나 성별/음성 필드, 프롬프트 템플릿, 카테고리에
이른다. 시드 러너(`run-seeds.ts`)는 멱등이며 참조 콘텐츠를 채운다.
개발 데이터베이스는 `docker-compose.yml`(`postgres:16-alpine`)로
프로비저닝된다.

---

*데이터베이스 설계 문서 끝.*
