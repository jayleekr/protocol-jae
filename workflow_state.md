# workflow_state.md
_Last updated: 2025-07-26_

## State
Phase: ANALYZE  
Status: RUNNING  
CurrentItem: Project Jae MVP Implementation  

## Plan
1. 프로젝트 구조 설정 (src/, tests/, docs/)
2. CrewAI 환경 구성 및 기본 에이전트 정의
3. jae-polish-specialist 에이전트 구현
4. jae-code-reviewer 에이전트 구현
5. jae-test-engineer 에이전트 구현
6. 에이전트 간 워크플로우 연결
7. 통합 테스트 및 데모 준비

## Rules
### [PHASE: ANALYZE]  
Read project_config.md & context; write summary.

### [PHASE: BLUEPRINT]  
Archive current plan; draft new steps; set `NEEDS_PLAN_APPROVAL`.

### [PHASE: CONSTRUCT]  
Follow approved plan; run tests; log; set `VALIDATE`.

### [PHASE: VALIDATE]  
Full test pass → `COMPLETED`; trigger `RULE_ITERATE_01`, `RULE_GIT_COMMIT_01`.

### RULE_INIT_01  
Phase == INIT → ask task → `ANALYZE, RUNNING`.

### RULE_ITERATE_01  
Status == COMPLETED && Items left → next item, reset.

### RULE_LOG_ROTATE_01  
Log > 5000 chars → top 5 lines to ArchiveLog, clear.

### RULE_SUMMARY_01  
VALIDATE && COMPLETED → prepend one-liner to Changelog.

### Git Rules
- RULE_GIT_COMMIT_01: prompt commit on VALIDATE pass.  
- RULE_GIT_ROLLBACK_01: checkout SHA by description.  
- RULE_GIT_DIFF_01: diff two SHAs.  
- RULE_GIT_GUIDANCE_01: help on request.

### RULE_BLUEPRINT_ARCHIVE_01  
Before overwrite → save to Blueprint History with time+ID.

### RULE_BLUEPRINT_REFERENCE_01  
User request → restore/show blueprint.

## Items
| id | description | status |
| 1 | 프로젝트 구조 및 초기 설정 | pending |
| 2 | CrewAI 기반 에이전트 프레임워크 구축 | pending |
| 3 | 품질 트리오 에이전트 구현 | pending |
| 4 | 통합 테스트 및 검증 | pending |

## Log
- 2025-07-26: 프로젝트 Jae 시작, git 저장소 초기화
- 2025-07-26: project_config.md 업데이트 - 목표 및 기술 스택 정의
- 2025-07-26: ANALYZE 단계로 전환, MVP 구현 계획 수립
- 2025-07-26: GitHub Actions CI/CD 파이프라인 구성 및 검증 완료
- 2025-07-26: 프로젝트 구조 설정 완료 (src/, tests/, docs/)

## Workflow History
<!-- commit SHA & msg -->

## ArchiveLog
<!-- rotated log summaries -->

## Blueprint History
<!-- archived plans -->
