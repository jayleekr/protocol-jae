# Protocol Jae: 차세대 개발을 위한 에이전틱 워크플로우

## 개요

프로젝트 "Jae"는 소프트웨어 개발 라이프사이클(SDLC)을 증강시키기 위해 설계된 다중 에이전트 프레임워크입니다. 
개발자를 대체하는 것이 아닌, 반복적인 작업을 자동화하고 코드 품질을 향상시키며 혁신을 가속하는 지능적인 협력 시스템입니다.

## 해커톤 MVP: 품질 트리오

본 MVP는 세 가지 핵심 에이전트에 집중합니다:

1. **jae-polish-specialist**: 코드 품질 개선 및 리팩토링
2. **jae-code-reviewer**: 자동화된 코드 리뷰
3. **jae-test-engineer**: 테스트 자동 생성 및 커버리지 분석

## 프로젝트 구조

```
agentic-workflow/
├── src/
│   ├── agents/         # 각 에이전트 구현
│   ├── tools/          # 에이전트가 사용하는 도구들
│   └── workflows/      # 에이전트 간 워크플로우
├── tests/              # 테스트 코드
├── docs/               # 문서
└── requirements.txt    # 의존성
```

## 시작하기

```bash
# 가상환경 생성 및 활성화
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt
```

## 사용법

### 환경 설정

1. 환경변수 설정:
```bash
cp .env.example .env
# .env 파일을 편집하여 API 키 설정
```

2. 가상환경 생성 및 의존성 설치:
```bash
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate
pip install -r requirements.txt
```

### 실행 방법

#### 데모 실행
```bash
python main.py --demo
```

#### 단일 파일 처리
```bash
python main.py --file path/to/your/file.py
```

#### 디렉토리 처리
```bash
python main.py --directory src/
```

### 워크플로우 단계

1. **Polish Specialist**: 코드 품질 개선 및 리팩토링
2. **Code Reviewer**: 자동화된 코드 리뷰 및 보안 검사
3. **Test Engineer**: 포괄적인 테스트 생성

### 예상 결과

- 개선된 코드 품질
- 자동 생성된 테스트
- 상세한 코드 리뷰 리포트
- DORA 메트릭 개선

## 라이선스

(추후 결정)