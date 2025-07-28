# VELOCITY-X Commands 사용 가이드

## 개요

VELOCITY-X Commands는 `temp_hooks/commands/` 기반의 워크플로우 시스템으로, 각 에이전트가 자동 호출되며 전문화된 도구에 접근할 수 있는 통합 환경을 제공합니다.

## 시스템 아키텍처

### 디렉토리 구조
```
temp_hooks/commands/
├── README.md                    # 시스템 개요
├── config/                      # 설정 파일들
│   ├── agents.yaml             # 에이전트 설정
│   ├── tools.yaml              # 도구 설정
│   └── workflow.yaml           # 워크플로우 설정
├── core/                       # 핵심 시스템
│   ├── common.sh               # 공통 함수
│   └── workflow_engine.py      # 워크플로우 엔진
├── agents/                     # 에이전트별 명령어
│   ├── velocity-x-polish-specialist/  # 코드 품질 개선
│   └── velocity-x-code-reviewer/      # 코드 리뷰
├── scripts/                    # 유틸리티 스크립트
│   ├── run-workflow.sh         # 범용 워크플로우 실행기
│   └── run-quality-trio.sh     # Quality Trio 워크플로우
└── docs/                       # 문서
    └── USAGE_GUIDE.md          # 이 파일
```

## 빠른 시작

### 1. 환경 설정

```bash
# 환경 변수 설정 (선택사항)
export VELOCITY-X_COMMANDS_DIR="./temp_hooks/commands"
export VELOCITY-X_CONFIG_DIR="./temp_hooks/commands/config"
export VELOCITY-X_OUTPUT_DIR="./velocity-x-output"
export VELOCITY-X_LOG_LEVEL="INFO"  # DEBUG, INFO, WARN, ERROR
```

### 2. 개별 에이전트 실행

```bash
# Polish Specialist 실행 (코드 품질 개선)
./temp_hooks/commands/agents/velocity-x-polish-specialist/run.sh test_sample.py

# Code Reviewer 실행 (코드 리뷰)
./temp_hooks/commands/agents/velocity-x-code-reviewer/run.sh test_sample.py

# 분석만 수행 (파일 수정 안함)
./temp_hooks/commands/agents/velocity-x-polish-specialist/run.sh --analyze-only test_sample.py

# 보안 중심 리뷰
./temp_hooks/commands/agents/velocity-x-code-reviewer/run.sh --focus security test_sample.py
```

### 3. 워크플로우 실행

```bash
# Quality Trio 워크플로우 (Polish → Review)
./temp_hooks/commands/scripts/run-quality-trio.sh test_sample.py

# 상세 로그와 함께 실행
./temp_hooks/commands/scripts/run-quality-trio.sh --verbose test_sample.py

# 사용 가능한 워크플로우 목록 확인
./temp_hooks/commands/scripts/run-workflow.sh --list
```

## 에이전트별 상세 가이드

### VELOCITY-X Polish Specialist (코드 품질 개선)

**역할**: 코드의 가독성, 유지보수성, 성능을 향상시키는 리팩토링 전문가

**주요 기능**:
- 코드 스멜 탐지 및 제거
- DRY, KISS, SOLID 원칙 적용
- 코드 포맷팅 (Black, isort)
- 복잡도 분석 (Radon)
- 정적 분석 (Ruff, Pylint)

**사용법**:
```bash
# 기본 실행 (분석 + 포맷팅 + 개선 제안)
./agents/velocity-x-polish-specialist/run.sh src/example.py

# 분석만 수행
./agents/velocity-x-polish-specialist/run.sh --analyze-only src/example.py

# 포맷팅만 수행
./agents/velocity-x-polish-specialist/run.sh --format-only src/example.py

# 상세 로그
./agents/velocity-x-polish-specialist/run.sh --verbose src/example.py
```

**출력 파일**:
- `ruff_report.json/txt`: Ruff 정적 분석 결과
- `pylint_report.json/txt`: Pylint 분석 결과
- `complexity_report.json/txt`: 복잡도 분석 결과
- `code_smells.json`: 코드 스멜 탐지 결과
- `improvement_suggestions.json`: 개선 제안사항
- `{filename}`: 포맷팅된 코드 파일

### VELOCITY-X Code Reviewer (코드 리뷰)

**역할**: 인간 리뷰어 관점에서 체계적이고 일관된 코드 리뷰 수행

**주요 기능**:
- 기능성 검토 (네이밍, 문서화, 설계)
- 보안 검토 (취약점 탐지, 하드코딩된 시크릿)
- 성능 검토 (알고리즘 복잡도, 최적화 기회)
- 스타일 검토 (PEP 8 준수, 일관성)

**사용법**:
```bash
# 전체 리뷰 수행
./agents/velocity-x-code-reviewer/run.sh src/example.py

# 특정 영역에 집중
./agents/velocity-x-code-reviewer/run.sh --focus security src/example.py
./agents/velocity-x-code-reviewer/run.sh --focus performance src/example.py
./agents/velocity-x-code-reviewer/run.sh --focus style src/example.py

# 엄격 모드
./agents/velocity-x-code-reviewer/run.sh --strict src/example.py

# 컨텍스트 파일 제공
./agents/velocity-x-code-reviewer/run.sh --context context.txt src/example.py
```

**출력 파일**:
- `functionality_review.json`: 기능성 검토 결과
- `security_review.json`: 보안 검토 결과
- `performance_review.json`: 성능 검토 결과
- `style_review.json`: 스타일 검토 결과
- `review_summary.json`: 종합 리뷰 요약

## 워크플로우 가이드

### Quality Trio Workflow

Polish Specialist → Code Reviewer 순서로 실행되는 코드 품질 개선 워크플로우

**특징**:
- 순차적 실행으로 안정성 보장
- 에이전트 간 결과 전달
- 통합 보고서 생성
- 에러 시 적절한 복구

**실행**:
```bash
./scripts/run-quality-trio.sh test_sample.py
```

**출력**:
- `workflow_{timestamp}/workflow_report.json`: 워크플로우 실행 보고서
- 각 에이전트의 개별 출력 디렉토리

## 설정 가이드

### 에이전트 설정 (agents.yaml)

```yaml
agents:
  velocity-x-polish-specialist:
    phase: 1
    order: 1
    enabled: true
    timeout: 300
    required_tools:
      - static_analyzer
      - code_formatter
    dependencies: []
```

**주요 설정**:
- `phase`: 실행 단계 (1: 핵심, 2: 품질/보안, 3: 도메인 특화)
- `order`: 단계 내 실행 순서
- `enabled`: 에이전트 활성화 여부
- `timeout`: 최대 실행 시간 (초)
- `dependencies`: 의존 에이전트 목록

### 도구 설정 (tools.yaml)

```yaml
tools:
  static_analyzer:
    name: "Static Code Analyzer"
    tools:
      - name: "ruff"
        executable: "ruff"
        args: ["check", "--format=json"]
```

### 환경 변수

| 변수명 | 기본값 | 설명 |
|--------|--------|------|
| `VELOCITY-X_COMMANDS_DIR` | `./temp_hooks/commands` | Commands 디렉토리 |
| `VELOCITY-X_CONFIG_DIR` | `./temp_hooks/commands/config` | 설정 디렉토리 |
| `VELOCITY-X_OUTPUT_DIR` | `./velocity-x-output` | 출력 디렉토리 |
| `VELOCITY-X_TEMP_DIR` | `/tmp/velocity-x-workflow` | 임시 디렉토리 |
| `VELOCITY-X_LOG_LEVEL` | `INFO` | 로그 레벨 |

## 결과 해석 가이드

### Polish Specialist 결과

**코드 스멜 예시**:
```json
{
  "type": "too_many_parameters",
  "line": 24,
  "message": "Function 'add_user' has too many parameters (11)",
  "severity": "medium"
}
```

**심각도 기준**:
- `high`: 즉시 수정 필요
- `medium`: 개선 권장
- `low`: 선택적 개선

### Code Reviewer 결과

**종합 점수 해석**:
```json
{
  "overall_score": 83.7,
  "detailed_scores": {
    "functionality": 55,
    "security": 100,
    "performance": 90,
    "style": 96
  },
  "recommendation": "APPROVE"
}
```

**점수 기준**:
- 90-100: 우수
- 80-89: 양호
- 70-79: 보통
- 60-69: 개선 필요
- 60 미만: 상당한 개선 필요

**권장사항**:
- `APPROVE`: 승인 (80점 이상, 중요 이슈 없음)
- `NEEDS_CHANGES`: 수정 필요

## 문제 해결

### 일반적인 오류

**1. 에이전트 스크립트를 찾을 수 없음**
```bash
Agent script not found: ./agents/velocity-x-polish-specialist/run.sh
```
**해결**: 실행 권한 확인 및 경로 검증
```bash
chmod +x ./temp_hooks/commands/agents/*/run.sh
```

**2. 설정 파일을 찾을 수 없음**
```bash
Agent config file not found: ./config/agents.yaml
```
**해결**: VELOCITY-X_CONFIG_DIR 환경 변수 확인

**3. Python 모듈 오류**
```bash
ModuleNotFoundError: No module named 'yaml'
```
**해결**: 필요한 Python 패키지 설치
```bash
pip install pyyaml
```

### 로그 분석

**로그 레벨별 정보**:
- `DEBUG`: 상세한 실행 과정
- `INFO`: 일반적인 진행 상황
- `WARN`: 주의 필요한 상황
- `ERROR`: 오류 발생

**상세 로그 활성화**:
```bash
export VELOCITY-X_LOG_LEVEL=DEBUG
./scripts/run-quality-trio.sh --verbose test_sample.py
```

## 확장 가이드

### 새 에이전트 추가

1. **디렉토리 생성**:
```bash
mkdir ./temp_hooks/commands/agents/velocity-x-new-agent
```

2. **run.sh 스크립트 생성**:
```bash
cp ./agents/velocity-x-polish-specialist/run.sh ./agents/velocity-x-new-agent/run.sh
# 필요에 따라 수정
```

3. **설정 파일 업데이트**:
```yaml
# agents.yaml에 새 에이전트 추가
velocity-x-new-agent:
  phase: 1
  order: 4
  enabled: true
  # ... 기타 설정
```

### 새 워크플로우 생성

1. **워크플로우 스크립트 생성**:
```bash
cp ./scripts/run-quality-trio.sh ./scripts/run-new-workflow.sh
# 에이전트 목록 및 로직 수정
```

2. **설정 파일 업데이트**:
```yaml
# workflow.yaml에 새 워크플로우 추가
workflows:
  new-workflow:
    name: "New Workflow"
    agents:
      - velocity-x-agent-1
      - velocity-x-agent-2
```

## 모범 사례

### 개발 워크플로우

1. **개발 단계**:
```bash
# 개발 중 코드 품질 확인
./agents/velocity-x-polish-specialist/run.sh --analyze-only src/feature.py
```

2. **커밋 전**:
```bash
# 전체 품질 검사
./scripts/run-quality-trio.sh src/feature.py
```

3. **PR 생성 전**:
```bash
# 포맷팅 적용
./agents/velocity-x-polish-specialist/run.sh --format-only src/feature.py
```

### 팀 사용 가이드

1. **코드 리뷰 보조**:
- 리뷰어가 Code Reviewer 결과를 참조하여 리뷰 품질 향상
- 일관된 리뷰 기준 적용

2. **코드 품질 표준화**:
- Polish Specialist로 팀 전체 코딩 스타일 통일
- 자동화된 개선 제안으로 학습 효과

3. **CI/CD 통합**:
```bash
# GitHub Actions에서 실행
- name: Run VELOCITY-X Quality Check
  run: ./temp_hooks/commands/scripts/run-quality-trio.sh src/
```

이 가이드를 통해 VELOCITY-X Commands 시스템을 효과적으로 활용하여 코드 품질을 향상시키고 개발 워크플로우를 자동화할 수 있습니다.