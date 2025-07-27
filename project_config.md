# project_config.md
_Last updated: 2025-07-27_

## Goal  
프로젝트 "Jae" - 차세대 개발을 위한 에이전틱 워크플로우 MVP 구축
- 다중 에이전트 협업 프레임워크를 통한 SDLC 자동화
- 기술 부채 감소 및 코드 품질 향상
- 해커톤 MVP: "품질 트리오" (polish-specialist, code-reviewer, test-engineer)
- 확장 목표: 9개 전문화된 에이전트의 유기적 워크플로우 시스템

## Tech Stack  
- Language: Python 3.11+  
- Framework: CrewAI (에이전트 오케스트레이션)
- LLM: Claude, GPT-4
- Tools: Git integration, Static analysis (pylint, ruff), Testing frameworks
- Infrastructure: Docker, GitHub Actions

## Patterns  
- Functional core, imperative shell.  
- kebab-case files; camelCase variables.  
- No `any`; strict null checks on.  
- Secrets via env vars only.

## Constraints  
- Bundle ≤ 250 KB.  
- SSR TTFB < 150 ms.  
- Rate-limit GitHub API: 500 req/hr.

## Tokenization  
- 3.5 ch/token, 8 K cap.  
- Summarize when `workflow_state.md` > 12 K.

## JAE Agent Architecture
9개 전문화된 에이전트로 구성된 3-Phase 워크플로우:

**Phase 1: 핵심 워크플로우**
- jae-vibe-specialist: BDD/아이디어 구체화 전문가
- jae-flow-specialist: PR/TDD 워크플로우 최적화 전문가  
- jae-polish-specialist: 코드 품질 개선 및 리팩토링 전문가

**Phase 2: 품질 및 보안 보증**
- jae-security-guardian: ISMS-P/보안 규정 준수 전문가
- jae-code-reviewer: 코드 리뷰 및 표준 준수 전문가
- jae-test-engineer: 테스트 자동화 및 커버리지 전문가

**Phase 3: 도메인 특화**
- jae-ui-architect: UI 컴포넌트 설계 및 생성 전문가
- jae-performance-optimizer: 성능 분석 및 최적화 전문가
- jae-documentation-scribe: 기술 문서 작성 및 관리 전문가

## Deliverables
- `/agents/`: 9개 에이전트 역할 정의 문서 (markdown)
- `jae-integrated-workflow.md`: 통합 워크플로우 설계 문서
- CrewAI 기반 구현 준비 완료

## Changelog
- 2025-07-13: Cleansed out.
- 2025-07-27: JAE 에이전트 아키텍처 설계 및 문서화 완료
