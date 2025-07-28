---
title: 사용자 정의 에이전트 개발
chapter: 7
author: VELOCITY-X Team
date: 2025-07-27
reading_time: 25분
---

# 사용자 정의 에이전트 개발

> *"에이전틱 워크플로우의 진정한 힘은 보유한 에이전트가 아니라 고유한 도전 과제를 해결하기 위해 생성할 수 있는 에이전트에 있다."* - Martin Fowler (각색)

## 개요

VELOCITY-X의 내장 에이전트들이 강력한 기능을 제공하지만, 진정한 마법은 특정 도메인, 도구, 워크플로우 요구사항에 맞춘 사용자 정의 에이전트를 생성할 때 일어납니다. 이 장에서는 VELOCITY-X 생태계와 원활하게 통합되는 사용자 정의 에이전트를 개발, 테스트, 배포하는 포괄적인 가이드를 제공합니다.

이 장을 마치면 다음을 이해하게 됩니다:
- VELOCITY-X 에이전트 아키텍처와 개발 패턴
- 처음부터 사용자 정의 에이전트를 설계하고 구현하는 방법
- 에이전트 통합 및 상호 운용성을 위한 모범 사례
- 에이전트 검증 및 신뢰성을 위한 테스트 전략
- 프로덕션 사용을 위한 배포 및 유지보수 패턴

## 1. 에이전트 아키텍처 기초

### VELOCITY-X 에이전트 구조

모든 VELOCITY-X 에이전트는 일관된 아키텍처 패턴을 따릅니다:

```python
# agent_base.py
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from enum import Enum

class AgentCapability(Enum):
    """표준 에이전트 기능"""
    ANALYSIS = "analysis"
    TRANSFORMATION = "transformation"
    VALIDATION = "validation"
    GENERATION = "generation"
    MONITORING = "monitoring"

@dataclass
class AgentMetadata:
    """에이전트 메타데이터 및 구성"""
    name: str
    version: str
    description: str
    capabilities: List[AgentCapability]
    dependencies: List[str]
    tools_required: List[str]
    min_jae_version: str

class VELOCITY-XAgent(ABC):
    """모든 VELOCITY-X 에이전트의 기본 클래스"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.metadata = self._load_metadata()
        self.tools = self._initialize_tools()
        self.context = AgentContext()
        self.metrics = AgentMetrics()
    
    @abstractmethod
    def _load_metadata(self) -> AgentMetadata:
        """에이전트 메타데이터 로드"""
        pass
    
    @abstractmethod
    def execute(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """주요 에이전트 실행 메소드"""
        pass
    
    @abstractmethod
    def validate_input(self, input_data: Any) -> bool:
        """입력 데이터 검증"""
        pass
    
    def _initialize_tools(self) -> Dict[str, Any]:
        """필요한 도구 초기화"""
        tools = {}
        for tool_name in self.metadata.tools_required:
            tool = ToolFactory.create_tool(tool_name, self.config)
            tools[tool_name] = tool
        return tools
    
    def handoff_to(self, next_agent: str, data: Any, context: Dict = None) -> HandoffResult:
        """다른 에이전트에게 작업 인계"""
        handoff = AgentHandoff(
            from_agent=self.metadata.name,
            to_agent=next_agent,
            data=data,
            context=context or {},
            timestamp=datetime.utcnow()
        )
        
        return HandoffManager.execute_handoff(handoff)
    
    def log_execution(self, input_data: Any, output_data: Any, 
                     execution_time: float, success: bool):
        """모니터링 및 디버깅을 위한 에이전트 실행 로그"""
        execution_log = ExecutionLog(
            agent_name=self.metadata.name,
            input_hash=self._hash_input(input_data),
            output_hash=self._hash_output(output_data),
            execution_time=execution_time,
            success=success,
            timestamp=datetime.utcnow()
        )
        
        self.metrics.record_execution(execution_log)
```

### 에이전트 통신 프로토콜

VELOCITY-X 에이전트는 표준화된 프로토콜을 통해 통신합니다:

```python
# agent_communication.py
class AgentMessage:
    """에이전트 통신을 위한 표준 메시지 형식"""
    
    def __init__(self, sender: str, receiver: str, message_type: str, 
                 payload: Any, correlation_id: str = None):
        self.sender = sender
        self.receiver = receiver
        self.message_type = message_type
        self.payload = payload
        self.correlation_id = correlation_id or str(uuid.uuid4())
        self.timestamp = datetime.utcnow()
        self.headers = {}
    
    def add_header(self, key: str, value: Any):
        """메시지에 사용자 정의 헤더 추가"""
        self.headers[key] = value
    
    def serialize(self) -> Dict[str, Any]:
        """전송을 위한 메시지 직렬화"""
        return {
            "sender": self.sender,
            "receiver": self.receiver,
            "message_type": self.message_type,
            "payload": self.payload,
            "correlation_id": self.correlation_id,
            "timestamp": self.timestamp.isoformat(),
            "headers": self.headers
        }

class AgentCommunicationBus:
    """에이전트 상호작용을 위한 중앙 통신 버스"""
    
    def __init__(self):
        self.subscribers = {}
        self.message_queue = Queue()
        self.message_history = MessageHistory()
    
    def register_agent(self, agent_name: str, agent_instance: VELOCITY-XAgent):
        """통신 버스에 에이전트 등록"""
        self.subscribers[agent_name] = agent_instance
    
    def send_message(self, message: AgentMessage):
        """대상 에이전트에게 메시지 전송"""
        if message.receiver in self.subscribers:
            self.message_queue.put(message)
            self.message_history.record(message)
        else:
            raise AgentNotFoundError(f"에이전트 {message.receiver}를 찾을 수 없습니다")
    
    def broadcast_message(self, sender: str, message_type: str, payload: Any):
        """등록된 모든 에이전트에게 메시지 브로드캐스트"""
        for agent_name in self.subscribers:
            if agent_name != sender:
                message = AgentMessage(sender, agent_name, message_type, payload)
                self.send_message(message)
```

## 2. 사용자 정의 에이전트 개발 프로세스

### 1단계: 에이전트 설계 및 계획

코딩하기 전에 에이전트를 신중하게 설계하세요:

```python
# agent_design_template.py
"""
에이전트 설계 템플릿

1. 에이전트 목적 및 범위
   - 이 에이전트가 해결하는 특정 문제는 무엇인가?
   - 입력/출력 요구사항은 무엇인가?
   - 어떤 도메인 전문성을 제공하는가?

2. 기능 정의
   - 이 에이전트가 수행할 수 있는 작업은 무엇인가?
   - 필요한 도구와 리소스는 무엇인가?
   - 다른 에이전트와 어떻게 통합되는가?

3. 인터페이스 설계
   - 에이전트의 공개 API는 무엇인가?
   - 어떤 구성 옵션이 필요한가?
   - 오류와 엣지 케이스를 어떻게 처리하는가?

4. 통합 지점
   - 어떤 에이전트와 협업할 것인가?
   - 어떤 인계 메커니즘이 필요한가?
   - 워크플로우에 어떻게 참여할 것인가?
"""

class AgentDesignSpec:
    """에이전트 설계를 위한 공식 명세서"""
    
    def __init__(self):
        self.purpose = ""
        self.scope = ""
        self.inputs = []
        self.outputs = []
        self.capabilities = []
        self.tools_required = []
        self.dependencies = []
        self.integration_points = []
        self.error_handling = []
        self.performance_requirements = {}
    
    def validate_design(self) -> DesignValidationResult:
        """완전성과 일관성을 위한 에이전트 설계 검증"""
        issues = []
        
        if not self.purpose:
            issues.append("에이전트 목적이 정의되지 않음")
        
        if not self.capabilities:
            issues.append("정의된 기능이 없음")
        
        if not self.inputs or not self.outputs:
            issues.append("입력/출력 명세 누락")
        
        # 순환 의존성 확인
        if self._has_circular_dependencies():
            issues.append("순환 의존성 감지")
        
        return DesignValidationResult(
            is_valid=len(issues) == 0,
            issues=issues
        )
```

### 2단계: 구현 프레임워크

일관된 구현을 위해 VELOCITY-X의 에이전트 프레임워크를 사용하세요:

```python
# custom_agent_example.py
class APIContractValidatorAgent(VELOCITY-XAgent):
    """
    마이크로서비스 아키텍처에서 API 계약을 검증하고 
    하위 호환성을 보장하는 사용자 정의 에이전트.
    """
    
    def _load_metadata(self) -> AgentMetadata:
        return AgentMetadata(
            name="api-contract-validator",
            version="1.0.0",
            description="하위 호환성을 위한 API 계약 검증",
            capabilities=[
                AgentCapability.ANALYSIS,
                AgentCapability.VALIDATION
            ],
            dependencies=["openapi-spec-validator", "json-schema"],
            tools_required=["Read", "Grep", "WebFetch"],
            min_jae_version="1.0.0"
        )
    
    def validate_input(self, input_data: Any) -> bool:
        """입력에 필요한 API 명세 데이터가 포함되어 있는지 검증"""
        required_fields = ["current_spec", "previous_spec", "service_name"]
        
        if not isinstance(input_data, dict):
            return False
        
        return all(field in input_data for field in required_fields)
    
    def execute(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """API 계약 검증 실행"""
        if not self.validate_input(input_data):
            raise ValueError("API 계약 검증을 위한 잘못된 입력 데이터")
        
        start_time = time.time()
        
        try:
            # 명세 추출
            current_spec = input_data["current_spec"]
            previous_spec = input_data["previous_spec"]
            service_name = input_data["service_name"]
            
            # 검증 수행
            validation_result = self._validate_contract_compatibility(
                current_spec, previous_spec, service_name
            )
            
            # 리포트 생성
            report = self._generate_validation_report(validation_result)
            
            # 성공적인 실행 로그
            execution_time = time.time() - start_time
            self.log_execution(input_data, report, execution_time, True)
            
            return report
            
        except Exception as e:
            execution_time = time.time() - start_time
            self.log_execution(input_data, None, execution_time, False)
            raise AgentExecutionError(f"API 계약 검증 실패: {str(e)}")
    
    def _validate_contract_compatibility(self, current_spec: Dict, 
                                       previous_spec: Dict, 
                                       service_name: str) -> ValidationResult:
        """API 호환성을 위한 핵심 검증 로직"""
        validation_result = ValidationResult(service_name)
        
        # 중단 변경사항 확인
        breaking_changes = self._detect_breaking_changes(current_spec, previous_spec)
        validation_result.add_breaking_changes(breaking_changes)
        
        # 사용 중단 기능 확인
        deprecations = self._detect_deprecations(current_spec, previous_spec)
        validation_result.add_deprecations(deprecations)
        
        # 스키마 진화 검증
        schema_issues = self._validate_schema_evolution(current_spec, previous_spec)
        validation_result.add_schema_issues(schema_issues)
        
        # API 버전 관리 컴플라이언스 확인
        versioning_issues = self._validate_versioning_strategy(current_spec)
        validation_result.add_versioning_issues(versioning_issues)
        
        return validation_result
    
    def _detect_breaking_changes(self, current: Dict, previous: Dict) -> List[BreakingChange]:
        """API 버전 간 중단 변경사항 감지"""
        breaking_changes = []
        
        # 제거된 엔드포인트 확인
        current_paths = set(current.get("paths", {}).keys())
        previous_paths = set(previous.get("paths", {}).keys())
        removed_paths = previous_paths - current_paths
        
        for path in removed_paths:
            breaking_changes.append(BreakingChange(
                type="endpoint_removal",
                path=path,
                severity="critical",
                description=f"엔드포인트 {path}가 제거되었습니다",
                recommendation="제거 대신 사용 중단하거나 호환성을 유지하세요"
            ))
        
        # 매개변수 변경사항 확인
        for path in current_paths.intersection(previous_paths):
            path_changes = self._analyze_path_changes(
                current["paths"][path], 
                previous["paths"][path]
            )
            breaking_changes.extend(path_changes)
        
        return breaking_changes
    
    def _generate_validation_report(self, validation_result: ValidationResult) -> Dict[str, Any]:
        """포괄적인 검증 리포트 생성"""
        return {
            "service_name": validation_result.service_name,
            "validation_timestamp": datetime.utcnow().isoformat(),
            "compatibility_status": validation_result.get_compatibility_status(),
            "breaking_changes": [change.to_dict() for change in validation_result.breaking_changes],
            "deprecations": [dep.to_dict() for dep in validation_result.deprecations],
            "schema_issues": [issue.to_dict() for issue in validation_result.schema_issues],
            "recommendations": validation_result.get_recommendations(),
            "compliance_score": validation_result.calculate_compliance_score()
        }
```

### 3단계: 고급 에이전트 기능

사용자 정의 에이전트에 정교한 기능을 추가하세요:

```python
# advanced_agent_features.py
class AdvancedCustomAgent(VELOCITY-XAgent):
    """고급 에이전트 기능의 예제"""
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.ml_model = self._load_ml_model()
        self.cache = self._initialize_cache()
        self.learning_system = LearningSystem()
    
    def execute_with_learning(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """머신러닝 향상과 함께 실행"""
        
        # ML을 사용하여 실행 전략 예측
        execution_strategy = self.ml_model.predict_strategy(input_data)
        
        # 예측된 전략으로 실행
        result = self._execute_with_strategy(input_data, execution_strategy)
        
        # 실행 결과로부터 학습
        self.learning_system.learn_from_execution(
            input_data, execution_strategy, result
        )
        
        return result
    
    def execute_with_caching(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """지능적인 캐싱과 함께 실행"""
        
        # 캐시 키 생성
        cache_key = self._generate_cache_key(input_data, context)
        
        # 캐시 확인
        cached_result = self.cache.get(cache_key)
        if cached_result and self._is_cache_valid(cached_result):
            self.metrics.record_cache_hit()
            return cached_result.data
        
        # 실행 및 결과 캐시
        result = self.execute(input_data, context)
        
        cache_entry = CacheEntry(
            key=cache_key,
            data=result,
            timestamp=datetime.utcnow(),
            ttl=self._calculate_ttl(input_data)
        )
        
        self.cache.put(cache_key, cache_entry)
        self.metrics.record_cache_miss()
        
        return result
    
    def execute_with_retry(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """자동 재시도 로직과 함께 실행"""
        
        max_retries = self.config.get("max_retries", 3)
        retry_delay = self.config.get("retry_delay", 1.0)
        
        for attempt in range(max_retries + 1):
            try:
                return self.execute(input_data, context)
            
            except RetryableError as e:
                if attempt < max_retries:
                    self.metrics.record_retry(attempt + 1)
                    time.sleep(retry_delay * (2 ** attempt))  # 지수 백오프
                    continue
                else:
                    raise MaxRetriesExceededError(f"{max_retries}번 재시도 후 실패: {str(e)}")
            
            except NonRetryableError as e:
                raise e
    
    def _load_ml_model(self):
        """에이전트 향상을 위한 머신러닝 모델 로드"""
        model_path = self.config.get("ml_model_path")
        if model_path:
            return MLModelLoader.load(model_path)
        return None
    
    def _initialize_cache(self):
        """캐싱 시스템 초기화"""
        cache_config = self.config.get("cache", {})
        cache_type = cache_config.get("type", "memory")
        
        if cache_type == "redis":
            return RedisCache(cache_config)
        elif cache_type == "memory":
            return MemoryCache(cache_config)
        else:
            return NoOpCache()
```

## 3. 에이전트 통합 패턴

### 워크플로우 통합

사용자 정의 에이전트를 VELOCITY-X 워크플로우에 통합:

```python
# workflow_integration.py
class WorkflowIntegration:
    """워크플로우에서 사용자 정의 에이전트를 위한 통합 패턴"""
    
    @staticmethod
    def create_sequential_workflow(agents: List[VELOCITY-XAgent]) -> SequentialWorkflow:
        """사용자 정의 에이전트로 순차 워크플로우 생성"""
        workflow = SequentialWorkflow()
        
        for i, agent in enumerate(agents):
            if i == 0:
                # 첫 번째 에이전트는 원시 입력 수신
                workflow.add_stage(WorkflowStage(
                    agent=agent,
                    input_source="workflow_input"
                ))
            else:
                # 후속 에이전트는 이전 에이전트의 출력 수신
                workflow.add_stage(WorkflowStage(
                    agent=agent,
                    input_source=f"stage_{i-1}_output"
                ))
        
        return workflow
    
    @staticmethod
    def create_parallel_workflow(agents: List[VELOCITY-XAgent], 
                               aggregator: AggregatorAgent) -> ParallelWorkflow:
        """결과 집계와 함께 병렬 워크플로우 생성"""
        workflow = ParallelWorkflow()
        
        # 병렬 에이전트 추가
        for agent in agents:
            workflow.add_parallel_stage(WorkflowStage(
                agent=agent,
                input_source="workflow_input"
            ))
        
        # 집계 단계 추가
        workflow.add_aggregation_stage(WorkflowStage(
            agent=aggregator,
            input_source="parallel_outputs"
        ))
        
        return workflow
    
    @staticmethod
    def create_conditional_workflow(condition_agent: VELOCITY-XAgent, 
                                  branch_agents: Dict[str, VELOCITY-XAgent]) -> ConditionalWorkflow:
        """분기 로직을 가진 조건부 워크플로우 생성"""
        workflow = ConditionalWorkflow()
        
        # 조건 평가 단계 추가
        workflow.add_condition_stage(WorkflowStage(
            agent=condition_agent,
            input_source="workflow_input"
        ))
        
        # 조건부 분기 추가
        for condition, agent in branch_agents.items():
            workflow.add_branch(condition, WorkflowStage(
                agent=agent,
                input_source="workflow_input"
            ))
        
        return workflow

# 예제: API 검증 워크플로우
class APIValidationWorkflow:
    """API 검증 프로세스를 위한 사용자 정의 워크플로우"""
    
    def __init__(self):
        self.contract_validator = APIContractValidatorAgent({})
        self.security_analyzer = SecurityAnalyzerAgent({})
        self.performance_tester = PerformanceTesterAgent({})
        self.report_generator = ReportGeneratorAgent({})
    
    def create_workflow(self) -> SequentialWorkflow:
        """포괄적인 API 검증 워크플로우 생성"""
        
        # 순차 워크플로우 생성
        workflow = WorkflowIntegration.create_sequential_workflow([
            self.contract_validator,
            self.security_analyzer,
            self.performance_tester,
            self.report_generator
        ])
        
        # 워크플로우 수준 구성 추가
        workflow.configure({
            "fail_fast": True,  # 첫 번째 중요한 이슈에서 중단
            "parallel_security_and_performance": True,  # 이것들을 병렬로 실행
            "generate_detailed_reports": True
        })
        
        return workflow
```

### 이벤트 기반 통합

반응형 에이전트를 위한 이벤트 기반 통합 생성:

```python
# event_driven_integration.py
class EventDrivenAgent(VELOCITY-XAgent):
    """이벤트 기반 에이전트를 위한 기본 클래스"""
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.event_handlers = {}
        self.event_bus = EventBus()
        self._register_event_handlers()
    
    def _register_event_handlers(self):
        """이 에이전트를 위한 이벤트 핸들러 등록"""
        pass  # 서브클래스에서 재정의
    
    def register_event_handler(self, event_type: str, handler: callable):
        """특정 이벤트 타입에 대한 핸들러 등록"""
        if event_type not in self.event_handlers:
            self.event_handlers[event_type] = []
        self.event_handlers[event_type].append(handler)
    
    def handle_event(self, event: Event):
        """들어오는 이벤트 처리"""
        event_type = event.type
        
        if event_type in self.event_handlers:
            for handler in self.event_handlers[event_type]:
                try:
                    handler(event)
                except Exception as e:
                    self.log_error(f"이벤트 {event_type} 처리 오류: {str(e)}")

class CodeChangeMonitorAgent(EventDrivenAgent):
    """코드 변경사항을 모니터링하고 분석을 트리거하는 에이전트"""
    
    def _register_event_handlers(self):
        """코드 변경 이벤트에 대한 핸들러 등록"""
        self.register_event_handler("file_changed", self._handle_file_change)
        self.register_event_handler("pull_request_opened", self._handle_pr_opened)
        self.register_event_handler("commit_pushed", self._handle_commit_pushed)
    
    def _handle_file_change(self, event: Event):
        """파일 변경 이벤트 처리"""
        file_path = event.data["file_path"]
        change_type = event.data["change_type"]
        
        # 이 변경사항이 즉시 분석이 필요한지 결정
        if self._requires_immediate_analysis(file_path, change_type):
            # 품질 트리오 워크플로우 트리거
            self._trigger_quality_analysis(event.data)
    
    def _handle_pr_opened(self, event: Event):
        """풀 리퀘스트 열림 이벤트 처리"""
        pr_data = event.data
        
        # 포괄적인 리뷰 스케줄
        self._schedule_comprehensive_review(pr_data)
    
    def _trigger_quality_analysis(self, change_data: Dict):
        """품질 분석 워크플로우 트리거"""
        analysis_event = Event(
            type="quality_analysis_requested",
            data=change_data,
            source=self.metadata.name
        )
        
        self.event_bus.publish(analysis_event)
```

## 4. 사용자 정의 에이전트 테스트

### 유닛 테스트 프레임워크

사용자 정의 에이전트를 위한 포괄적인 테스트 프레임워크:

```python
# agent_testing_framework.py
import unittest
from unittest.mock import Mock, patch
import pytest

class AgentTestCase(unittest.TestCase):
    """에이전트 테스트를 위한 기본 테스트 케이스"""
    
    def setUp(self):
        """테스트 환경 설정"""
        self.agent_config = self._get_test_config()
        self.agent = self._create_agent_instance()
        self.mock_tools = self._setup_mock_tools()
    
    def _get_test_config(self) -> Dict[str, Any]:
        """에이전트를 위한 테스트 구성 가져오기"""
        return {
            "test_mode": True,
            "cache_enabled": False,
            "ml_model_path": None  # 테스트에서 ML 비활성화
        }
    
    def _create_agent_instance(self):
        """테스트를 위한 에이전트 인스턴스 생성"""
        raise NotImplementedError("서브클래스는 이 메소드를 구현해야 합니다")
    
    def _setup_mock_tools(self) -> Dict[str, Mock]:
        """테스트를 위한 목 도구 설정"""
        mock_tools = {}
        for tool_name in self.agent.metadata.tools_required:
            mock_tools[tool_name] = Mock()
        return mock_tools
    
    def test_agent_metadata(self):
        """에이전트 메타데이터가 적절히 구성되었는지 테스트"""
        metadata = self.agent.metadata
        
        self.assertIsInstance(metadata.name, str)
        self.assertIsInstance(metadata.version, str)
        self.assertIsInstance(metadata.description, str)
        self.assertTrue(len(metadata.capabilities) > 0)
    
    def test_input_validation(self):
        """입력 검증 로직 테스트"""
        # 유효한 입력 테스트
        valid_input = self._get_valid_test_input()
        self.assertTrue(self.agent.validate_input(valid_input))
        
        # 무효한 입력 테스트
        invalid_inputs = self._get_invalid_test_inputs()
        for invalid_input in invalid_inputs:
            self.assertFalse(self.agent.validate_input(invalid_input))
    
    def test_successful_execution(self):
        """성공적인 에이전트 실행 테스트"""
        input_data = self._get_valid_test_input()
        
        with patch.object(self.agent, 'tools', self.mock_tools):
            result = self.agent.execute(input_data)
        
        self.assertIsNotNone(result)
        self._validate_output_format(result)
    
    def test_error_handling(self):
        """에이전트 오류 처리 테스트"""
        # 무효한 입력으로 테스트
        with self.assertRaises(ValueError):
            self.agent.execute(self._get_invalid_test_inputs()[0])
        
        # 도구 실패로 테스트
        self.mock_tools["Read"].side_effect = Exception("도구 실패")
        
        with patch.object(self.agent, 'tools', self.mock_tools):
            with self.assertRaises(AgentExecutionError):
                self.agent.execute(self._get_valid_test_input())

class APIContractValidatorAgentTest(AgentTestCase):
    """API Contract Validator Agent를 위한 테스트 케이스"""
    
    def _create_agent_instance(self):
        return APIContractValidatorAgent(self.agent_config)
    
    def _get_valid_test_input(self):
        return {
            "current_spec": {
                "openapi": "3.0.0",
                "paths": {
                    "/users": {"get": {"responses": {"200": {"description": "OK"}}}}
                }
            },
            "previous_spec": {
                "openapi": "3.0.0",
                "paths": {
                    "/users": {"get": {"responses": {"200": {"description": "OK"}}}}
                }
            },
            "service_name": "user-service"
        }
    
    def _get_invalid_test_inputs(self):
        return [
            {},  # 빈 입력
            {"current_spec": {}},  # 필드 누락
            "invalid_type",  # 잘못된 타입
        ]
    
    def _validate_output_format(self, result):
        """API 검증의 출력 형식 검증"""
        self.assertIn("service_name", result)
        self.assertIn("compatibility_status", result)
        self.assertIn("breaking_changes", result)
        self.assertIn("recommendations", result)
    
    def test_breaking_change_detection(self):
        """중단 변경사항 감지 테스트"""
        input_data = {
            "current_spec": {
                "openapi": "3.0.0",
                "paths": {
                    "/users": {"get": {"responses": {"200": {"description": "OK"}}}}
                }
            },
            "previous_spec": {
                "openapi": "3.0.0",
                "paths": {
                    "/users": {"get": {"responses": {"200": {"description": "OK"}}}},
                    "/admin": {"get": {"responses": {"200": {"description": "OK"}}}}
                }
            },
            "service_name": "user-service"
        }
        
        with patch.object(self.agent, 'tools', self.mock_tools):
            result = self.agent.execute(input_data)
        
        # /admin 엔드포인트 제거를 감지해야 함
        self.assertTrue(len(result["breaking_changes"]) > 0)
```

### 통합 테스트

다른 컴포넌트와의 에이전트 통합 테스트:

```python
# integration_testing.py
class AgentIntegrationTest(unittest.TestCase):
    """에이전트 워크플로우를 위한 통합 테스트"""
    
    def setUp(self):
        """통합 테스트 환경 설정"""
        self.test_environment = TestEnvironment()
        self.agent_registry = AgentRegistry()
        self.workflow_engine = WorkflowEngine()
    
    def test_agent_handoff(self):
        """에이전트 간 인계 테스트"""
        # 에이전트 설정
        source_agent = APIContractValidatorAgent({})
        target_agent = SecurityAnalyzerAgent({})
        
        # 에이전트 등록
        self.agent_registry.register(source_agent)
        self.agent_registry.register(target_agent)
        
        # 인계 테스트
        test_data = {"validation_result": "sample_data"}
        handoff_result = source_agent.handoff_to(
            target_agent.metadata.name, 
            test_data
        )
        
        self.assertTrue(handoff_result.success)
        self.assertEqual(handoff_result.target_agent, target_agent.metadata.name)
    
    def test_workflow_execution(self):
        """완전한 워크플로우 실행 테스트"""
        # 테스트 워크플로우 생성
        workflow = APIValidationWorkflow().create_workflow()
        
        # 테스트 데이터로 워크플로우 실행
        test_input = self._get_workflow_test_input()
        result = self.workflow_engine.execute(workflow, test_input)
        
        # 워크플로우 완료 검증
        self.assertTrue(result.success)
        self.assertIsNotNone(result.final_output)
    
    def test_event_driven_integration(self):
        """이벤트 기반 에이전트 통합 테스트"""
        # 이벤트 기반 에이전트 설정
        monitor_agent = CodeChangeMonitorAgent({})
        analysis_agent = QualityAnalysisAgent({})
        
        # 이벤트 버스 설정
        event_bus = EventBus()
        event_bus.register_agent(monitor_agent)
        event_bus.register_agent(analysis_agent)
        
        # 테스트 이벤트 트리거
        test_event = Event(
            type="file_changed",
            data={"file_path": "test.py", "change_type": "modified"}
        )
        
        event_bus.publish(test_event)
        
        # 이벤트 처리 검증
        # (실제 구현에서는 더 정교한 이벤트 추적이 필요함)
```

### 성능 테스트

에이전트 성능 및 확장성 테스트:

```python
# performance_testing.py
import time
import concurrent.futures
from typing import List

class AgentPerformanceTest:
    """에이전트를 위한 성능 테스트 프레임워크"""
    
    def __init__(self, agent_class, config: Dict[str, Any]):
        self.agent_class = agent_class
        self.config = config
    
    def test_execution_time(self, test_inputs: List[Any], 
                          expected_max_time: float) -> PerformanceResult:
        """에이전트 실행 시간 테스트"""
        agent = self.agent_class(self.config)
        execution_times = []
        
        for test_input in test_inputs:
            start_time = time.time()
            result = agent.execute(test_input)
            execution_time = time.time() - start_time
            execution_times.append(execution_time)
        
        avg_time = sum(execution_times) / len(execution_times)
        max_time = max(execution_times)
        
        return PerformanceResult(
            average_time=avg_time,
            max_time=max_time,
            meets_requirements=max_time <= expected_max_time,
            execution_times=execution_times
        )
    
    def test_memory_usage(self, test_input: Any) -> MemoryUsageResult:
        """에이전트 메모리 사용량 테스트"""
        import psutil
        import os
        
        process = psutil.Process(os.getpid())
        initial_memory = process.memory_info().rss
        
        agent = self.agent_class(self.config)
        result = agent.execute(test_input)
        
        final_memory = process.memory_info().rss
        memory_used = final_memory - initial_memory
        
        return MemoryUsageResult(
            initial_memory=initial_memory,
            final_memory=final_memory,
            memory_used=memory_used
        )
    
    def test_concurrent_execution(self, test_inputs: List[Any], 
                                max_workers: int = 10) -> ConcurrencyResult:
        """동시 로드 하에서 에이전트 성능 테스트"""
        
        def execute_agent(test_input):
            agent = self.agent_class(self.config)
            start_time = time.time()
            result = agent.execute(test_input)
            execution_time = time.time() - start_time
            return execution_time, result
        
        start_time = time.time()
        
        with concurrent.futures.ThreadPoolExecutor(max_workers=max_workers) as executor:
            futures = [executor.submit(execute_agent, test_input) 
                      for test_input in test_inputs]
            results = [future.result() for future in futures]
        
        total_time = time.time() - start_time
        execution_times = [result[0] for result in results]
        
        return ConcurrencyResult(
            total_time=total_time,
            average_execution_time=sum(execution_times) / len(execution_times),
            throughput=len(test_inputs) / total_time,
            all_successful=all(result[1] is not None for result in results)
        )
```

## 5. 배포 및 프로덕션 고려사항

### 배포 전략

사용자 정의 에이전트를 안전하고 효율적으로 배포:

```python
# deployment_strategies.py
class AgentDeploymentManager:
    """사용자 정의 에이전트 배포 관리"""
    
    def __init__(self, environment: str):
        self.environment = environment
        self.deployment_config = self._load_deployment_config()
        self.health_checker = AgentHealthChecker()
        self.rollback_manager = RollbackManager()
    
    def deploy_agent(self, agent_package: AgentPackage) -> DeploymentResult:
        """안전 검사와 함께 에이전트 배포"""
        
        # 에이전트 패키지 검증
        validation_result = self._validate_agent_package(agent_package)
        if not validation_result.is_valid:
            return DeploymentResult(
                success=False,
                errors=validation_result.errors
            )
        
        # 배포 계획 생성
        deployment_plan = self._create_deployment_plan(agent_package)
        
        try:
            # 배포 실행
            return self._execute_deployment(deployment_plan)
        
        except DeploymentError as e:
            # 실패 시 자동 롤백
            self.rollback_manager.rollback_deployment(deployment_plan)
            raise e
    
    def blue_green_deploy(self, agent_package: AgentPackage) -> DeploymentResult:
        """블루-그린 전략을 사용한 배포"""
        
        # 그린 환경에 배포
        green_deployment = self._deploy_to_environment(agent_package, "green")
        
        if green_deployment.success:
            # 그린에서 헬스 체크 실행
            health_check = self.health_checker.check_agent_health(
                agent_package.metadata.name, "green"
            )
            
            if health_check.is_healthy:
                # 그린으로 트래픽 전환
                self._switch_traffic("green")
                
                # 블루를 대기 상태로 표시
                self._mark_environment_standby("blue")
                
                return DeploymentResult(success=True)
            else:
                # 그린 배포 롤백
                self._destroy_environment("green")
                return DeploymentResult(
                    success=False,
                    errors=["그린 환경에서 헬스 체크 실패"]
                )
        
        return green_deployment
    
    def canary_deploy(self, agent_package: AgentPackage, 
                     traffic_percentage: int = 10) -> DeploymentResult:
        """카나리 전략을 사용한 배포"""
        
        # 카나리 버전 배포
        canary_deployment = self._deploy_canary(agent_package)
        
        if canary_deployment.success:
            # 카나리로 소량 트래픽 라우팅
            self._route_traffic_to_canary(traffic_percentage)
            
            # 카나리 성능 모니터링
            canary_metrics = self._monitor_canary_metrics(duration_minutes=30)
            
            if canary_metrics.are_acceptable():
                # 점진적으로 트래픽 증가
                self._gradual_traffic_increase(agent_package)
                return DeploymentResult(success=True)
            else:
                # 카나리 롤백
                self._rollback_canary()
                return DeploymentResult(
                    success=False,
                    errors=["카나리 메트릭이 허용 불가능"]
                )
        
        return canary_deployment
```

### 모니터링 및 관찰성

프로덕션 에이전트를 위한 포괄적인 모니터링 구현:

```python
# agent_monitoring.py
class AgentMonitoringSystem:
    """프로덕션 에이전트를 위한 포괄적인 모니터링 시스템"""
    
    def __init__(self):
        self.metrics_collector = MetricsCollector()
        self.log_aggregator = LogAggregator()
        self.alert_manager = AlertManager()
        self.dashboard = MonitoringDashboard()
    
    def setup_agent_monitoring(self, agent: VELOCITY-XAgent) -> MonitoringSetup:
        """에이전트를 위한 모니터링 설정"""
        
        setup = MonitoringSetup(agent.metadata.name)
        
        # 메트릭 수집 설정
        setup.add_metric("execution_time", MetricType.HISTOGRAM)
        setup.add_metric("success_rate", MetricType.GAUGE)
        setup.add_metric("error_rate", MetricType.COUNTER)
        setup.add_metric("memory_usage", MetricType.GAUGE)
        setup.add_metric("cache_hit_rate", MetricType.GAUGE)
        
        # 로그 집계 설정
        setup.configure_logging(
            log_level="INFO",
            structured_logging=True,
            correlation_tracking=True
        )
        
        # 알림 설정
        setup.add_alert(Alert(
            name="high_error_rate",
            condition="error_rate > 0.05",
            severity="warning",
            notification_channels=["slack", "email"]
        ))
        
        setup.add_alert(Alert(
            name="execution_time_degradation",
            condition="execution_time.p95 > baseline * 1.5",
            severity="critical",
            notification_channels=["pagerduty", "slack"]
        ))
        
        return setup
    
    def create_monitoring_dashboard(self, agents: List[VELOCITY-XAgent]) -> Dashboard:
        """에이전트를 위한 모니터링 대시보드 생성"""
        
        dashboard = Dashboard("VELOCITY-X 에이전트 모니터링")
        
        # 개요 패널
        overview_panel = Panel("개요")
        overview_panel.add_widget(MetricWidget(
            title="활성 에이전트",
            metric="active_agents_count",
            visualization="single_stat"
        ))
        overview_panel.add_widget(MetricWidget(
            title="총 실행 횟수",
            metric="total_executions",
            visualization="single_stat"
        ))
        dashboard.add_panel(overview_panel)
        
        # 성능 패널
        performance_panel = Panel("성능")
        performance_panel.add_widget(MetricWidget(
            title="실행 시간",
            metric="execution_time",
            visualization="time_series",
            aggregation="percentile(95)"
        ))
        performance_panel.add_widget(MetricWidget(
            title="성공률",
            metric="success_rate",
            visualization="gauge"
        ))
        dashboard.add_panel(performance_panel)
        
        # 에이전트별 패널
        for agent in agents:
            agent_panel = Panel(f"에이전트: {agent.metadata.name}")
            
            agent_panel.add_widget(MetricWidget(
                title="실행 횟수",
                metric=f"{agent.metadata.name}.executions",
                visualization="time_series"
            ))
            
            agent_panel.add_widget(MetricWidget(
                title="오류율",
                metric=f"{agent.metadata.name}.error_rate",
                visualization="time_series"
            ))
            
            dashboard.add_panel(agent_panel)
        
        return dashboard
```

### 유지보수 및 업데이트

프로덕션 에이전트를 위한 유지보수 절차 수립:

```python
# agent_maintenance.py
class AgentMaintenanceManager:
    """프로덕션 에이전트의 유지보수 및 업데이트 관리"""
    
    def __init__(self):
        self.version_manager = VersionManager()
        self.backup_manager = BackupManager()
        self.health_checker = HealthChecker()
        self.scheduler = MaintenanceScheduler()
    
    def schedule_maintenance(self, agent_name: str, 
                           maintenance_type: str, 
                           schedule: str) -> MaintenanceJob:
        """에이전트를 위한 정기 유지보수 스케줄"""
        
        maintenance_job = MaintenanceJob(
            agent_name=agent_name,
            maintenance_type=maintenance_type,
            schedule=schedule
        )
        
        if maintenance_type == "health_check":
            maintenance_job.add_task(
                HealthCheckTask(comprehensive=True)
            )
        
        elif maintenance_type == "cache_cleanup":
            maintenance_job.add_task(
                CacheCleanupTask(cleanup_expired=True)
            )
        
        elif maintenance_type == "log_rotation":
            maintenance_job.add_task(
                LogRotationTask(keep_days=30)
            )
        
        elif maintenance_type == "performance_analysis":
            maintenance_job.add_task(
                PerformanceAnalysisTask(generate_report=True)
            )
        
        self.scheduler.schedule_job(maintenance_job)
        return maintenance_job
    
    def update_agent(self, agent_name: str, new_version: str, 
                    update_strategy: str = "rolling") -> UpdateResult:
        """에이전트를 새 버전으로 업데이트"""
        
        # 업데이트 전 백업 생성
        backup_result = self.backup_manager.create_backup(agent_name)
        if not backup_result.success:
            return UpdateResult(
                success=False,
                error="업데이트 전 백업 생성 실패"
            )
        
        try:
            if update_strategy == "rolling":
                return self._rolling_update(agent_name, new_version)
            elif update_strategy == "blue_green":
                return self._blue_green_update(agent_name, new_version)
            elif update_strategy == "immediate":
                return self._immediate_update(agent_name, new_version)
        
        except UpdateError as e:
            # 실패 시 백업에서 복원
            self.backup_manager.restore_backup(agent_name, backup_result.backup_id)
            return UpdateResult(
                success=False,
                error=f"업데이트 실패: {str(e)}. 백업에서 복원됨."
            )
    
    def _rolling_update(self, agent_name: str, new_version: str) -> UpdateResult:
        """에이전트 인스턴스의 롤링 업데이트 수행"""
        
        agent_instances = self._get_agent_instances(agent_name)
        
        for instance in agent_instances:
            # 한 번에 하나의 인스턴스 업데이트
            update_result = self._update_single_instance(instance, new_version)
            
            if not update_result.success:
                return UpdateResult(
                    success=False,
                    error=f"인스턴스 {instance.id} 업데이트 실패"
                )
            
            # 계속하기 전에 인스턴스가 건강한지 대기
            health_check = self.health_checker.wait_for_healthy(
                instance, timeout_seconds=300
            )
            
            if not health_check.is_healthy:
                return UpdateResult(
                    success=False,
                    error=f"업데이트 후 인스턴스 {instance.id} 헬스 체크 실패"
                )
        
        return UpdateResult(success=True)
```

## 6. 요약

사용자 정의 에이전트 개발은 특정 요구사항을 충족하기 위해 VELOCITY-X의 기능을 확장할 수 있게 해주는 강력한 기능입니다. 신중한 설계, 견고한 구현, 포괄적인 테스트, 적절한 배포 관행을 통해 VELOCITY-X 생태계와 원활하게 통합되는 에이전트를 생성할 수 있습니다.

### 주요 포인트

✅ **구조화된 개발**: 일관성과 상호 운용성을 위해 VELOCITY-X의 에이전트 아키텍처 패턴 따르기

✅ **포괄적인 테스트**: 신뢰성을 위한 유닛, 통합, 성능 테스트 구현

✅ **안전한 배포**: 안전한 프로덕션 릴리스를 위한 블루-그린, 카나리 같은 배포 전략 사용

✅ **프로덕션 모니터링**: 프로덕션 에이전트를 위한 포괄적인 모니터링 및 알림 구현

✅ **유지보수 계획**: 장기적인 신뢰성을 위한 정기 유지보수 절차 수립

### 개발 체크리스트

- [ ] 에이전트 아키텍처 설계 및 기능 정의
- [ ] VELOCITY-X 패턴을 따라 핵심 에이전트 기능 구현
- [ ] 고급 기능 추가 (캐싱, 재시도 로직, ML 향상)
- [ ] 포괄적인 테스트 스위트 생성
- [ ] 에이전트 배포를 위한 CI/CD 파이프라인 설정
- [ ] 모니터링 및 알림 구현
- [ ] 에이전트 API 및 사용 패턴 문서화
- [ ] 유지보수 및 업데이트 절차 계획

## 연습 문제

1. **에이전트 설계**: 도메인의 특정 요구사항을 위한 사용자 정의 에이전트 설계 (예: 데이터베이스 마이그레이션 검증기, 인프라 컴플라이언스 체커)

2. **구현**: VELOCITY-X 패턴을 따라 설계한 에이전트의 기본 버전 구현

3. **테스트**: 유닛, 통합, 성능 테스트를 포함한 에이전트의 포괄적인 테스트 스위트 생성

4. **통합**: 기존 VELOCITY-X 워크플로우와 에이전트 통합

5. **배포**: 적절한 모니터링과 함께 에이전트를 위한 배포 파이프라인 설정

## 추가 자료

- [워크플로우 설계 패턴](08-workflow-design-patterns.md)
- [엔터프라이즈 구현](09-enterprise-implementation.md)
- [팀 협업 전략](10-team-collaboration.md)
- [VELOCITY-X 에이전트 API 레퍼런스](appendix-api-reference.md)

---

*다음 장: [워크플로우 설계 패턴](08-workflow-design-patterns.md) - 정교한 에이전트 워크플로우 설계를 위한 고급 패턴 학습*