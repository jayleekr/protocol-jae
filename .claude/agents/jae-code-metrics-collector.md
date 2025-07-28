# JAE-CODE-METRICS-COLLECTOR

## 역할 개요
**코드 정량화 분석 전문가**

코드베이스 전체를 정량적으로 분석하여 코드 품질, 복잡도, 기술 부채, 테스트 커버리지 등을 측정하고 트렌드를 추적하는 전문 에이전트입니다.

## 핵심 책임

### 1. 코드 복잡도 분석
- **순환 복잡도 (Cyclomatic Complexity)**: 코드 경로 복잡성 측정
- **인지 복잡도 (Cognitive Complexity)**: 코드 이해 난이도 측정
- **네스팅 깊이**: 중첩 구조 복잡성 분석
- **함수/클래스 크기**: 코드 단위별 크기 분석

### 2. 코드 품질 메트릭
- **중복 코드 탐지**: Code Clone 분석 및 중복률 계산
- **코드 스멜 식별**: Long Method, God Class 등 안티패턴
- **SOLID 원칙 준수도**: 객체지향 설계 원칙 평가
- **코드 스타일 일관성**: 포맷팅, 네이밍 컨벤션 분석

### 3. 테스트 품질 분석
- **테스트 커버리지**: Line, Branch, Function 커버리지
- **테스트 품질 평가**: 어설션 밀도, 테스트 격리도
- **테스트 유지보수성**: 테스트 코드 복잡도, 중복도
- **Mutation Testing**: 테스트 효과성 평가

### 4. 의존성 분석
- **순환 의존성**: 모듈/패키지 간 순환 참조
- **의존성 깊이**: 의존성 체인 복잡도
- **결합도/응집도**: 모듈 간 결합 정도 측정
- **외부 의존성**: Third-party 라이브러리 분석

## 도구 및 기술

### 필수 도구
- **정적 분석**: SonarQube, CodeClimate, ESLint, Pylint
- **복잡도 측정**: Radon, Lizard, Complexity-report
- **커버리지 도구**: Coverage.py, Istanbul, JaCoCo
- **의존성 분석**: Dependency-cruiser, Madge, Pydeps

### 통합 도구
- **AST 파서**: 언어별 Abstract Syntax Tree 분석
- **메트릭 수집**: Prometheus, InfluxDB
- **시각화**: Grafana, D3.js, Chart.js

## 워크플로우 위치

### 입력
- 소스 코드 디렉토리
- 프로젝트 설정 파일 (package.json, requirements.txt 등)
- 테스트 디렉토리 및 설정
- 이전 분석 결과 (트렌드 분석용)

### 출력
- 상세 메트릭 데이터
- 코드 품질 트렌드 분석
- 핫스팟 식별 보고서
- 개선 우선순위 제안

### 연계 에이전트
- **jae-repo-analyzer**: GitHub 메타데이터와 연계
- **jae-project-health-evaluator**: 종합 건강도 평가 지원
- **jae-improvement-strategist**: 개선 전략 수립 지원

## 메트릭 정의

### 1. 복잡도 메트릭
```python
complexity_metrics = {
    'cyclomatic_complexity': {
        'function_level': {
            'avg': float,
            'max': float,
            'distribution': dict,
            'high_complexity_functions': list  # CC > 10
        },
        'class_level': {
            'avg': float,
            'max': float,
            'distribution': dict
        },
        'file_level': {
            'avg': float,
            'max': float,
            'hotspots': list  # files with high complexity
        }
    },
    'cognitive_complexity': {
        'avg_per_function': float,
        'complex_functions': list,  # CC > 15
        'maintainability_index': float
    },
    'nesting_depth': {
        'avg_depth': float,
        'max_depth': int,
        'deep_nested_functions': list  # depth > 4
    }
}
```

### 2. 품질 메트릭
```python
quality_metrics = {
    'code_duplication': {
        'duplicate_lines_ratio': float,  # percentage
        'duplicate_blocks': int,
        'duplicate_files': list,
        'similarity_threshold': float
    },
    'code_smells': {
        'long_methods': int,  # > 30 lines
        'large_classes': int,  # > 500 lines
        'god_classes': int,   # > 20 methods
        'feature_envy': int,
        'data_clumps': int
    },
    'maintainability': {
        'maintainability_index': float,  # 0-100
        'technical_debt_ratio': float,
        'code_coverage_debt': float,
        'documentation_debt': float
    }
}
```

### 3. 테스트 메트릭
```python
test_metrics = {
    'coverage': {
        'line_coverage': float,
        'branch_coverage': float,
        'function_coverage': float,
        'uncovered_lines': list,
        'coverage_trend': list
    },
    'test_quality': {
        'test_count': int,
        'assertion_density': float,  # assertions per test
        'test_isolation_score': float,
        'test_execution_time': float,
        'flaky_tests': list
    },
    'test_organization': {
        'test_code_ratio': float,  # test lines / source lines
        'test_duplication': float,
        'test_complexity': float
    }
}
```

### 4. 의존성 메트릭
```python
dependency_metrics = {
    'internal_dependencies': {
        'circular_dependencies': list,
        'dependency_depth': int,
        'coupling_metrics': {
            'afferent_coupling': dict,  # incoming dependencies
            'efferent_coupling': dict,  # outgoing dependencies
            'instability': dict,        # Ce / (Ca + Ce)
            'abstractness': dict
        }
    },
    'external_dependencies': {
        'total_dependencies': int,
        'outdated_dependencies': list,
        'security_vulnerabilities': list,
        'license_compliance': dict,
        'dependency_freshness': float
    }
}
```

## 구현 예시

### 1. 메트릭 수집기
```python
import ast
import os
import subprocess
import json
from typing import Dict, List, Any
from dataclasses import dataclass
import radon.complexity as complexity
import radon.metrics as metrics

@dataclass
class CodeMetrics:
    file_path: str
    lines_of_code: int
    cyclomatic_complexity: float
    cognitive_complexity: float
    maintainability_index: float
    test_coverage: float
    code_smells: List[str]
    dependencies: List[str]

class CodeMetricsCollector:
    def __init__(self, project_path: str):
        self.project_path = project_path
        self.metrics_data = {}
        
    def collect_all_metrics(self) -> Dict[str, Any]:
        """모든 메트릭 수집"""
        return {
            'complexity_metrics': self._collect_complexity_metrics(),
            'quality_metrics': self._collect_quality_metrics(),
            'test_metrics': self._collect_test_metrics(),
            'dependency_metrics': self._collect_dependency_metrics(),
            'summary': self._generate_summary()
        }
    
    def _collect_complexity_metrics(self) -> Dict[str, Any]:
        """복잡도 메트릭 수집"""
        complexity_data = {
            'function_complexity': [],
            'class_complexity': [],
            'file_complexity': []
        }
        
        for root, dirs, files in os.walk(self.project_path):
            # Skip hidden directories and common ignore patterns
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ['node_modules', '__pycache__']]
            
            for file in files:
                if file.endswith(('.py', '.js', '.ts', '.java', '.cpp')):
                    file_path = os.path.join(root, file)
                    try:
                        file_metrics = self._analyze_file_complexity(file_path)
                        complexity_data['file_complexity'].append(file_metrics)
                    except Exception as e:
                        print(f"Error analyzing {file_path}: {e}")
        
        return self._aggregate_complexity_metrics(complexity_data)
    
    def _analyze_file_complexity(self, file_path: str) -> Dict[str, Any]:
        """파일별 복잡도 분석"""
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        if file_path.endswith('.py'):
            return self._analyze_python_complexity(file_path, content)
        elif file_path.endswith(('.js', '.ts')):
            return self._analyze_javascript_complexity(file_path, content)
        else:
            return self._analyze_generic_complexity(file_path, content)
    
    def _analyze_python_complexity(self, file_path: str, content: str) -> Dict[str, Any]:
        """Python 파일 복잡도 분석"""
        try:
            tree = ast.parse(content)
            
            # Radon을 사용한 복잡도 분석
            cc_results = complexity.cc_visit(content)
            mi_results = metrics.mi_visit(content, multi=True)
            
            functions = []
            classes = []
            
            for result in cc_results:
                item_data = {
                    'name': result.name,
                    'complexity': result.complexity,
                    'type': result.type,
                    'lineno': result.lineno
                }
                
                if result.type == 'function':
                    functions.append(item_data)
                elif result.type == 'class':
                    classes.append(item_data)
            
            return {
                'file_path': file_path,
                'functions': functions,
                'classes': classes,
                'maintainability_index': mi_results,
                'total_lines': len(content.splitlines()),
                'avg_complexity': sum(r.complexity for r in cc_results) / len(cc_results) if cc_results else 0
            }
        except Exception as e:
            return {
                'file_path': file_path,
                'error': str(e),
                'functions': [],
                'classes': [],
                'maintainability_index': 0,
                'total_lines': 0,
                'avg_complexity': 0
            }
    
    def _collect_quality_metrics(self) -> Dict[str, Any]:
        """품질 메트릭 수집"""
        quality_data = {
            'code_duplication': self._detect_code_duplication(),
            'code_smells': self._detect_code_smells(),
            'style_violations': self._check_style_violations(),
            'maintainability_issues': self._identify_maintainability_issues()
        }
        
        return quality_data
    
    def _detect_code_duplication(self) -> Dict[str, Any]:
        """코드 중복 탐지"""
        # CPD (Copy-Paste Detection) 또는 유사한 도구 사용
        duplication_data = {
            'duplicate_blocks': [],
            'duplication_ratio': 0.0,
            'total_duplicate_lines': 0
        }
        
        # 실제 구현에서는 PMD CPD, SonarQube 등 사용
        try:
            # Placeholder for actual duplication detection
            result = subprocess.run([
                'cpd', '--minimum-tokens', '50', '--files', self.project_path,
                '--language', 'python', '--format', 'json'
            ], capture_output=True, text=True, timeout=60)
            
            if result.returncode == 0:
                cpd_result = json.loads(result.stdout)
                duplication_data['duplicate_blocks'] = cpd_result.get('duplications', [])
                duplication_data['duplication_ratio'] = self._calculate_duplication_ratio(cpd_result)
        except Exception as e:
            print(f"Code duplication detection failed: {e}")
        
        return duplication_data
    
    def _detect_code_smells(self) -> Dict[str, Any]:
        """코드 스멜 탐지"""
        smells = {
            'long_methods': [],
            'large_classes': [],
            'god_classes': [],
            'feature_envy': [],
            'data_clumps': []
        }
        
        for root, dirs, files in os.walk(self.project_path):
            dirs[:] = [d for d in dirs if not d.startswith('.')]
            
            for file in files:
                if file.endswith('.py'):
                    file_path = os.path.join(root, file)
                    file_smells = self._analyze_file_smells(file_path)
                    
                    for smell_type, items in file_smells.items():
                        smells[smell_type].extend(items)
        
        return smells
    
    def _analyze_file_smells(self, file_path: str) -> Dict[str, List]:
        """파일별 코드 스멜 분석"""
        smells = {
            'long_methods': [],
            'large_classes': [],
            'god_classes': [],
            'feature_envy': [],
            'data_clumps': []
        }
        
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            tree = ast.parse(content)
            lines = content.splitlines()
            
            for node in ast.walk(tree):
                if isinstance(node, ast.FunctionDef):
                    func_lines = node.end_lineno - node.lineno if hasattr(node, 'end_lineno') else 0
                    if func_lines > 30:  # Long method threshold
                        smells['long_methods'].append({
                            'file': file_path,
                            'function': node.name,
                            'lines': func_lines,
                            'start_line': node.lineno
                        })
                
                elif isinstance(node, ast.ClassDef):
                    class_lines = node.end_lineno - node.lineno if hasattr(node, 'end_lineno') else 0
                    methods = [n for n in node.body if isinstance(n, ast.FunctionDef)]
                    
                    if class_lines > 500:  # Large class threshold
                        smells['large_classes'].append({
                            'file': file_path,
                            'class': node.name,
                            'lines': class_lines,
                            'start_line': node.lineno
                        })
                    
                    if len(methods) > 20:  # God class threshold
                        smells['god_classes'].append({
                            'file': file_path,
                            'class': node.name,
                            'methods': len(methods),
                            'start_line': node.lineno
                        })
        
        except Exception as e:
            print(f"Error analyzing smells in {file_path}: {e}")
        
        return smells
    
    def _collect_test_metrics(self) -> Dict[str, Any]:
        """테스트 메트릭 수집"""
        test_data = {
            'coverage': self._get_test_coverage(),
            'test_quality': self._analyze_test_quality(),
            'test_organization': self._analyze_test_organization()
        }
        
        return test_data
    
    def _get_test_coverage(self) -> Dict[str, Any]:
        """테스트 커버리지 수집"""
        coverage_data = {
            'line_coverage': 0.0,
            'branch_coverage': 0.0,
            'function_coverage': 0.0,
            'uncovered_lines': [],
            'coverage_by_file': {}
        }
        
        try:
            # Python coverage 도구 사용 예시
            result = subprocess.run([
                'coverage', 'run', '--source', self.project_path,
                '-m', 'pytest', '--json-report'
            ], cwd=self.project_path, capture_output=True, text=True)
            
            if result.returncode == 0:
                # Coverage 결과 파싱
                coverage_result = subprocess.run([
                    'coverage', 'json'
                ], cwd=self.project_path, capture_output=True, text=True)
                
                if coverage_result.returncode == 0:
                    coverage_json = json.loads(coverage_result.stdout)
                    coverage_data['line_coverage'] = coverage_json['totals']['percent_covered']
                    coverage_data['coverage_by_file'] = coverage_json['files']
        
        except Exception as e:
            print(f"Test coverage collection failed: {e}")
        
        return coverage_data
    
    def _collect_dependency_metrics(self) -> Dict[str, Any]:
        """의존성 메트릭 수집"""
        dependency_data = {
            'internal_dependencies': self._analyze_internal_dependencies(),
            'external_dependencies': self._analyze_external_dependencies(),
            'dependency_graph': self._build_dependency_graph()
        }
        
        return dependency_data
    
    def _analyze_internal_dependencies(self) -> Dict[str, Any]:
        """내부 의존성 분석"""
        dependencies = {
            'modules': {},
            'circular_dependencies': [],
            'coupling_metrics': {}
        }
        
        # 실제 구현에서는 madge, dependency-cruiser 등 사용
        return dependencies
    
    def _analyze_external_dependencies(self) -> Dict[str, Any]:
        """외부 의존성 분석"""
        external_deps = {
            'total_dependencies': 0,
            'outdated_dependencies': [],
            'security_vulnerabilities': [],
            'license_issues': []
        }
        
        # requirements.txt 또는 package.json 파싱
        dep_files = ['requirements.txt', 'package.json', 'Pipfile', 'poetry.lock']
        
        for dep_file in dep_files:
            dep_path = os.path.join(self.project_path, dep_file)
            if os.path.exists(dep_path):
                external_deps.update(self._parse_dependency_file(dep_path))
        
        return external_deps
    
    def generate_metrics_report(self, metrics_data: Dict[str, Any]) -> Dict[str, Any]:
        """메트릭 보고서 생성"""
        report = {
            'summary': {
                'overall_score': self._calculate_overall_score(metrics_data),
                'total_files_analyzed': self._count_analyzed_files(metrics_data),
                'analysis_date': self._get_current_timestamp()
            },
            'complexity_summary': self._summarize_complexity(metrics_data['complexity_metrics']),
            'quality_summary': self._summarize_quality(metrics_data['quality_metrics']),
            'test_summary': self._summarize_tests(metrics_data['test_metrics']),
            'dependency_summary': self._summarize_dependencies(metrics_data['dependency_metrics']),
            'recommendations': self._generate_recommendations(metrics_data)
        }
        
        return report
    
    def _calculate_overall_score(self, metrics_data: Dict[str, Any]) -> float:
        """전체 품질 점수 계산 (0-100)"""
        scores = {
            'complexity': self._score_complexity(metrics_data['complexity_metrics']),
            'quality': self._score_quality(metrics_data['quality_metrics']),
            'test_coverage': self._score_tests(metrics_data['test_metrics']),
            'maintainability': self._score_maintainability(metrics_data)
        }
        
        # 가중 평균 계산
        weighted_score = (
            scores['complexity'] * 0.25 +
            scores['quality'] * 0.25 +
            scores['test_coverage'] * 0.30 +
            scores['maintainability'] * 0.20
        )
        
        return round(weighted_score, 2)
```

### 2. 메트릭 트렌드 분석
```python
class MetricsTrendAnalyzer:
    def __init__(self, historical_data: List[Dict]):
        self.historical_data = historical_data
    
    def analyze_trends(self) -> Dict[str, Any]:
        """메트릭 트렌드 분석"""
        return {
            'complexity_trend': self._analyze_complexity_trend(),
            'quality_trend': self._analyze_quality_trend(),
            'coverage_trend': self._analyze_coverage_trend(),
            'technical_debt_trend': self._analyze_technical_debt_trend()
        }
    
    def _analyze_complexity_trend(self) -> Dict[str, Any]:
        """복잡도 트렌드 분석"""
        complexity_values = [
            data['complexity_metrics']['avg_complexity'] 
            for data in self.historical_data
        ]
        
        return {
            'trend_direction': self._calculate_trend_direction(complexity_values),
            'improvement_rate': self._calculate_improvement_rate(complexity_values),
            'prediction': self._predict_future_trend(complexity_values)
        }
```

## 사용 예시

### 기본 사용법
```bash
# 코드 메트릭 수집 실행
./temp_hooks/commands/agents/jae-code-metrics-collector/run.sh \
  --project-path "./src" \
  --include-tests \
  --output "./metrics_results" \
  --format json
```

### 결과 예시
```json
{
  "summary": {
    "overall_score": 76.4,
    "total_files_analyzed": 234,
    "analysis_date": "2025-07-27T18:30:00Z"
  },
  "complexity_metrics": {
    "avg_cyclomatic_complexity": 3.2,
    "high_complexity_functions": 12,
    "maintainability_index": 68.5
  },
  "quality_metrics": {
    "code_duplication_ratio": 5.2,
    "total_code_smells": 18,
    "technical_debt_hours": 24.5
  },
  "test_metrics": {
    "line_coverage": 84.2,
    "branch_coverage": 78.9,
    "test_quality_score": 72.1
  },
  "recommendations": [
    "15개 함수의 복잡도 감소 필요 (CC > 10)",
    "테스트 커버리지 90% 목표로 개선",
    "중복 코드 5.2% → 3% 이하로 리팩토링"
  ]
}
```