# JAE Commands Directory

이 디렉토리는 JAE 에이전트들의 자동 호출 및 전문화된 도구 통합을 위한 command 스크립트들을 포함합니다.

## 디렉토리 구조

```
temp_hooks/commands/
├── README.md                    # 이 파일
├── config/                      # 설정 파일들
│   ├── agents.yaml             # 에이전트 설정
│   ├── tools.yaml              # 도구 설정
│   └── workflow.yaml           # 워크플로우 설정
├── core/                       # 핵심 시스템
│   ├── agent_registry.py       # 에이전트 등록 및 관리
│   ├── tool_manager.py         # 도구 관리자
│   ├── workflow_engine.py      # 워크플로우 엔진
│   └── hook_system.py          # Hook 시스템
├── agents/                     # 에이전트별 명령어
│   ├── jae-vibe-specialist/    # BDD/아이디어 구체화
│   ├── jae-flow-specialist/    # PR/TDD 워크플로우
│   ├── jae-polish-specialist/  # 코드 품질 개선
│   ├── jae-security-guardian/  # 보안 규정 준수
│   ├── jae-code-reviewer/      # 코드 리뷰
│   ├── jae-test-engineer/      # 테스트 자동화
│   ├── jae-ui-architect/       # UI 컴포넌트
│   ├── jae-performance-optimizer/ # 성능 최적화
│   └── jae-documentation-scribe/  # 문서화
├── tools/                      # 전문화된 도구들
│   ├── git/                    # Git 관련 도구
│   ├── analysis/               # 코드 분석 도구
│   ├── security/               # 보안 도구
│   ├── testing/                # 테스트 도구
│   ├── performance/            # 성능 도구
│   └── documentation/          # 문서화 도구
├── scripts/                    # 유틸리티 스크립트
│   ├── install.sh              # 의존성 설치
│   ├── setup.sh                # 초기 설정
│   └── validate.sh             # 환경 검증
└── hooks/                      # Hook 스크립트들
    ├── pre-commit              # 커밋 전 훅
    ├── post-commit             # 커밋 후 훅
    ├── pre-push                # 푸시 전 훅
    └── workflow-trigger        # 워크플로우 트리거
```

## 작동 원리

1. **Hook 기반 트리거**: Git hooks 또는 이벤트를 통해 워크플로우 자동 시작
2. **에이전트 자동 호출**: 워크플로우 엔진이 순서에 따라 에이전트 호출
3. **도구 자동 제공**: 각 에이전트가 필요한 전문 도구에 자동 접근
4. **데이터 핸드오프**: 에이전트 간 결과물 자동 전달

## 사용법

```bash
# 수동 워크플로우 실행
./temp_hooks/commands/scripts/run-workflow.sh --type=quality-trio

# 특정 에이전트 실행
./temp_hooks/commands/agents/jae-polish-specialist/run.sh --file=src/example.py

# 전체 워크플로우 실행
./temp_hooks/commands/scripts/run-full-workflow.sh
```