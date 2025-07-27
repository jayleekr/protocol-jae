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
14개 전문화된 에이전트로 구성된 4-Phase 워크플로우:

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

**Phase 4: 분석 및 인텔리전스**
- jae-repo-analyzer: GitHub 저장소 분석 전문가
- jae-code-metrics-collector: 코드 정량화 분석 전문가
- jae-project-health-evaluator: 프로젝트 건강도 종합 평가 전문가
- jae-improvement-strategist: 발전 전략 수립 전문가
- jae-repo-insights-orchestrator: GitHub 저장소 인사이트 통합 오케스트레이터

## Deliverables
- `/agents/`: 9개 에이전트 역할 정의 문서 (markdown) ✅
- `jae-integrated-workflow.md`: 통합 워크플로우 설계 문서 ✅
- `/temp_hooks/commands/`: 워크플로우 통합 시스템 ✅
  - 에이전트별 command 스크립트 (polish-specialist, code-reviewer)
  - 자동 호출 메커니즘 및 데이터 핸드오프
  - 전문화된 도구 통합 (ruff, pylint, black, radon)
- 통합 테스트 검증 ✅
- 사용법 가이드 문서 ✅
- `/jae-book/`: JAE 마스터링 기술서 ✅
  - 영문판: 14개 챕터 완성 (+ 1개 새로운 GitHub 분석 챕터) ✅
  - 한국어판: 14개 챕터 완성 (100%) ✅
  - 서브에이전트: book-content-writer, translator, diagram-creator, formatter ✅
  - GitHub 분석 시스템: 5개 새로운 에이전트 추가 ✅

## Changelog
- 2025-07-13: Cleansed out.
- 2025-07-27: JAE 에이전트 아키텍처 설계 및 문서화 완료
- 2025-07-27: temp_hooks/commands/ 기반 워크플로우 시스템 구현 완룈
- 2025-07-27: Polish Specialist & Code Reviewer 에이전트 작동 확인
- 2025-07-27: JAE 마스터링 북 제작 프로젝트 완료
  ✅ 성과: 영문 14개 챕터, 한국어 14개 챕터, 4개 서브에이전트
  ✅ GitHub 분석 시스템: 5개 새로운 에이전트 추가
  ✅ 새로운 챕터 13: GitHub Analytics and Repository Insights
  🔄 완성: 자동 번역 파이프라인 및 품질 관리 시스템 구축

## Lessons Learned
- 다국어 컨텐츠 제작 시 자동화 워크플로우의 중요성
- 수동 번역 프로세스의 한계와 누락 위험성
- 서브에이전트 간 연계 워크플로우 설계의 필요성
- 컨텐츠 생성과 번역의 동기화 메커니즘 필수
- 품질 관리와 완료율 검증 시스템의 중요성
