# project_config.md
_Last updated: 2025-07-26_

## Goal  
프로젝트 "Jae" - 차세대 개발을 위한 에이전틱 워크플로우 MVP 구축
- 다중 에이전트 협업 프레임워크를 통한 SDLC 자동화
- 기술 부채 감소 및 코드 품질 향상
- 해커톤 MVP: "품질 트리오" (polish-specialist, code-reviewer, test-engineer)

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

## Changelog
- 2025-07-13: Cleansed out.
