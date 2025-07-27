---
title: 워크플로우 디자인 패턴
chapter: 8
author: JAE Team
date: 2025-07-27
reading_time: 28분
---

# 워크플로우 디자인 패턴

> *"패턴은 맥락 속의 문제에 대한 해결책이다. 복잡한 협력 과제를 해결하기 위해 올바른 패턴을 적용할 때 훌륭한 워크플로우가 나타난다."* - Christopher Alexander (각색)

## 개요

워크플로우 디자인 패턴은 에이전틱 개발에서 자주 발생하는 문제들에 대한 검증된 해결책을 제공합니다. 이 장에서는 여러 에이전트를 조율하고, 복잡한 데이터 흐름을 처리하며, 오류를 우아하게 관리하고, 엔터프라이즈 환경에서 워크플로우를 확장하는 정교한 패턴들을 탐구합니다.

이 장을 마치면 다음을 이해하게 됩니다:
- 핵심 워크플로우 패턴과 적용 시기
- 복잡한 시나리오를 위한 고급 협력 메커니즘
- 오류 처리 및 복원력 패턴
- 대규모 워크플로우를 위한 성능 최적화 패턴
- 일반적인 사용 사례를 위한 도메인별 워크플로우 패턴

## 1. 기본 워크플로우 패턴

### 순차 처리 패턴

에이전트가 미리 정해진 순서로 실행되는 가장 기본적인 패턴입니다:

```python
# sequential_pattern.py
class SequentialWorkflow:
    """순차 처리 패턴 구현"""
    
    def __init__(self, name: str):
        self.name = name
        self.stages = []
        self.context = WorkflowContext()
        self.error_handler = ErrorHandler()
    
    def add_stage(self, agent: JAEAgent, input_transform: Optional[callable] = None):
        """순차 워크플로우에 단계 추가"""
        stage = WorkflowStage(
            agent=agent,
            input_transform=input_transform,
            stage_id=len(self.stages)
        )
        self.stages.append(stage)
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """순차 워크플로우 실행"""
        result = WorkflowResult(self.name)
        current_data = initial_input
        
        for i, stage in enumerate(self.stages):
            try:
                # 필요시 입력 변환
                if stage.input_transform:
                    stage_input = stage.input_transform(current_data, self.context)
                else:
                    stage_input = current_data
                
                # 단계 실행
                stage_result = stage.agent.execute(stage_input, self.context.to_dict())
                
                # 컨텍스트 업데이트 및 다음 단계 준비
                self.context.add_stage_result(i, stage_result)
                current_data = stage_result
                
                result.add_stage_result(i, stage_result)
                
            except Exception as e:
                error_result = self.error_handler.handle_stage_error(
                    stage, e, self.context
                )
                
                if error_result.should_continue:
                    current_data = error_result.recovery_data
                    result.add_error_recovery(i, error_result)
                else:
                    result.mark_failed(i, str(e))
                    break
        
        return result

# 예시: 코드 품질 파이프라인
class CodeQualityPipeline(SequentialWorkflow):
    """코드 품질 개선을 위한 순차 파이프라인"""
    
    def __init__(self):
        super().__init__("code-quality-pipeline")
        
        # 순서대로 단계 추가
        self.add_stage(
            PolishSpecialistAgent({}),
            self._prepare_polish_input
        )
        
        self.add_stage(
            CodeReviewerAgent({}),
            self._prepare_review_input
        )
        
        self.add_stage(
            TestEngineerAgent({}),
            self._prepare_test_input
        )
        
        self.add_stage(
            SecurityGuardianAgent({}),
            self._prepare_security_input
        )
    
    def _prepare_polish_input(self, data: Any, context: WorkflowContext) -> Any:
        """Polish Specialist를 위한 입력 변환"""
        return {
            "source_code": data,
            "quality_standards": context.get("quality_standards"),
            "performance_targets": context.get("performance_targets")
        }
    
    def _prepare_review_input(self, data: Any, context: WorkflowContext) -> Any:
        """Code Reviewer를 위한 입력 변환"""
        polish_result = context.get_stage_result(0)
        return {
            "original_code": context.get("initial_input"),
            "polished_code": data,
            "polish_improvements": polish_result.get("improvements", [])
        }
```

### 병렬 처리 패턴

작업이 독립적일 때 여러 에이전트를 동시에 실행합니다:

```python
# parallel_pattern.py
import asyncio
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict, List, Tuple

class ParallelWorkflow:
    """병렬 처리 패턴 구현"""
    
    def __init__(self, name: str, max_workers: int = 4):
        self.name = name
        self.parallel_stages = []
        self.aggregation_stage = None
        self.max_workers = max_workers
        self.execution_strategy = ParallelExecutionStrategy.THREAD_POOL
    
    def add_parallel_stage(self, agent: JAEAgent, input_transform: Optional[callable] = None):
        """병렬로 실행할 에이전트 추가"""
        stage = ParallelStage(
            agent=agent,
            input_transform=input_transform,
            stage_id=len(self.parallel_stages)
        )
        self.parallel_stages.append(stage)
    
    def set_aggregation_stage(self, aggregator_agent: JAEAgent):
        """병렬 결과를 집계할 에이전트 설정"""
        self.aggregation_stage = aggregator_agent
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """병렬 워크플로우 실행"""
        if self.execution_strategy == ParallelExecutionStrategy.THREAD_POOL:
            return self._execute_with_threads(initial_input)
        elif self.execution_strategy == ParallelExecutionStrategy.ASYNC:
            return asyncio.run(self._execute_async(initial_input))
        else:
            return self._execute_with_multiprocessing(initial_input)
    
    def _execute_with_threads(self, initial_input: Any) -> WorkflowResult:
        """스레드 풀을 사용한 실행"""
        result = WorkflowResult(self.name)
        
        def execute_stage(stage: ParallelStage) -> Tuple[int, Any]:
            try:
                # 이 단계를 위한 입력 변환
                if stage.input_transform:
                    stage_input = stage.input_transform(initial_input)
                else:
                    stage_input = initial_input
                
                # 단계 실행
                stage_result = stage.agent.execute(stage_input)
                return stage.stage_id, stage_result
                
            except Exception as e:
                return stage.stage_id, StageError(str(e))
        
        # 모든 병렬 단계 실행
        with ThreadPoolExecutor(max_workers=self.max_workers) as executor:
            future_to_stage = {
                executor.submit(execute_stage, stage): stage 
                for stage in self.parallel_stages
            }
            
            parallel_results = {}
            for future in as_completed(future_to_stage):
                stage_id, stage_result = future.result()
                parallel_results[stage_id] = stage_result
                result.add_parallel_result(stage_id, stage_result)
        
        # 집계자가 구성된 경우 결과 집계
        if self.aggregation_stage:
            try:
                aggregated_result = self.aggregation_stage.execute(parallel_results)
                result.set_final_result(aggregated_result)
            except Exception as e:
                result.mark_failed("aggregation", str(e))
        
        return result
    
    async def _execute_async(self, initial_input: Any) -> WorkflowResult:
        """I/O 바운드 작업을 위한 asyncio 사용 실행"""
        result = WorkflowResult(self.name)
        
        async def execute_stage_async(stage: ParallelStage) -> Tuple[int, Any]:
            try:
                # 입력 변환
                if stage.input_transform:
                    stage_input = stage.input_transform(initial_input)
                else:
                    stage_input = initial_input
                
                # 단계 실행 (에이전트가 비동기가 아니면 executor로 래핑)
                if hasattr(stage.agent, 'execute_async'):
                    stage_result = await stage.agent.execute_async(stage_input)
                else:
                    loop = asyncio.get_event_loop()
                    stage_result = await loop.run_in_executor(
                        None, stage.agent.execute, stage_input
                    )
                
                return stage.stage_id, stage_result
                
            except Exception as e:
                return stage.stage_id, StageError(str(e))
        
        # 모든 단계를 동시에 실행
        tasks = [execute_stage_async(stage) for stage in self.parallel_stages]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # 결과 처리
        parallel_results = {}
        for stage_id, stage_result in results:
            parallel_results[stage_id] = stage_result
            result.add_parallel_result(stage_id, stage_result)
        
        # 구성된 경우 집계
        if self.aggregation_stage:
            aggregated_result = await self._execute_aggregation_async(parallel_results)
            result.set_final_result(aggregated_result)
        
        return result

# 예시: 다중 관점 분석 워크플로우
class MultiAspectAnalysisWorkflow(ParallelWorkflow):
    """여러 관점에서 코드를 병렬로 분석"""
    
    def __init__(self):
        super().__init__("multi-aspect-analysis", max_workers=6)
        
        # 병렬 분석 에이전트 추가
        self.add_parallel_stage(
            SecurityAnalyzerAgent({}),
            self._prepare_security_input
        )
        
        self.add_parallel_stage(
            PerformanceAnalyzerAgent({}),
            self._prepare_performance_input
        )
        
        self.add_parallel_stage(
            AccessibilityAnalyzerAgent({}),
            self._prepare_accessibility_input
        )
        
        self.add_parallel_stage(
            SEOAnalyzerAgent({}),
            self._prepare_seo_input
        )
        
        self.add_parallel_stage(
            ComplianceAnalyzerAgent({}),
            self._prepare_compliance_input
        )
        
        # 집계자 설정
        self.set_aggregation_stage(
            AnalysisAggregatorAgent({})
        )
    
    def _prepare_security_input(self, data: Any) -> Any:
        """보안 분석을 위한 입력 준비"""
        return {
            "code": data,
            "analysis_type": "security",
            "depth": "comprehensive"
        }
    
    def _prepare_performance_input(self, data: Any) -> Any:
        """성능 분석을 위한 입력 준비"""
        return {
            "code": data,
            "analysis_type": "performance",
            "include_benchmarks": True
        }
```

### 조건 분기 패턴

런타임 조건에 따라 워크플로우 실행 경로를 라우팅합니다:

```python
# conditional_pattern.py
class ConditionalWorkflow:
    """조건 분기 패턴 구현"""
    
    def __init__(self, name: str):
        self.name = name
        self.condition_evaluator = None
        self.branches = {}
        self.default_branch = None
        self.merge_stage = None
    
    def set_condition_evaluator(self, evaluator_agent: JAEAgent):
        """조건을 평가할 에이전트 설정"""
        self.condition_evaluator = evaluator_agent
    
    def add_branch(self, condition: str, workflow: WorkflowPattern):
        """조건부 분기 추가"""
        self.branches[condition] = workflow
    
    def set_default_branch(self, workflow: WorkflowPattern):
        """조건이 일치하지 않을 때의 기본 분기 설정"""
        self.default_branch = workflow
    
    def set_merge_stage(self, merger_agent: JAEAgent):
        """분기 결과를 병합할 에이전트 설정"""
        self.merge_stage = merger_agent
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """조건부 워크플로우 실행"""
        result = WorkflowResult(self.name)
        
        # 조건 평가
        if not self.condition_evaluator:
            raise WorkflowError("조건 평가자가 구성되지 않았습니다")
        
        try:
            condition_result = self.condition_evaluator.execute(initial_input)
            selected_branch = condition_result.get("selected_branch")
            
            # 선택된 분기 실행
            if selected_branch in self.branches:
                branch_workflow = self.branches[selected_branch]
                branch_result = branch_workflow.execute(initial_input)
                result.add_branch_result(selected_branch, branch_result)
            elif self.default_branch:
                branch_result = self.default_branch.execute(initial_input)
                result.add_branch_result("default", branch_result)
            else:
                raise WorkflowError(f"조건에 대한 분기를 찾을 수 없습니다: {selected_branch}")
            
            # 구성된 경우 결과 병합
            if self.merge_stage:
                merge_input = {
                    "condition": selected_branch,
                    "branch_result": branch_result,
                    "original_input": initial_input
                }
                merged_result = self.merge_stage.execute(merge_input)
                result.set_final_result(merged_result)
            
        except Exception as e:
            result.mark_failed("condition_evaluation", str(e))
        
        return result

class ChangeTypeEvaluatorAgent(JAEAgent):
    """코드 변경 유형을 평가하는 에이전트"""
    
    def execute(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """변경 유형을 평가하고 적절한 워크플로우 선택"""
        changeset = input_data.get("changeset", {})
        
        # 변경 특성 분석
        files_changed = len(changeset.get("files", []))
        lines_added = changeset.get("lines_added", 0)
        lines_removed = changeset.get("lines_removed", 0)
        affects_tests = any("test" in f.get("path", "") for f in changeset.get("files", []))
        affects_config = any("config" in f.get("path", "") for f in changeset.get("files", []))
        
        # 결정 로직
        if files_changed == 1 and lines_added + lines_removed < 10:
            selected_branch = "hotfix"
        elif affects_config and not affects_tests:
            selected_branch = "configuration"
        elif files_changed > 20 or lines_added + lines_removed > 1000:
            selected_branch = "major_change"
        elif affects_tests:
            selected_branch = "test_change"
        else:
            selected_branch = "standard"
        
        return {
            "selected_branch": selected_branch,
            "change_characteristics": {
                "files_changed": files_changed,
                "lines_changed": lines_added + lines_removed,
                "affects_tests": affects_tests,
                "affects_config": affects_config
            }
        }

# 예시: 적응형 코드 리뷰 워크플로우
class AdaptiveCodeReviewWorkflow(ConditionalWorkflow):
    """변경 특성에 따라 적응하는 워크플로우"""
    
    def __init__(self):
        super().__init__("adaptive-code-review")
        
        # 조건 평가자 설정
        self.set_condition_evaluator(ChangeTypeEvaluatorAgent({}))
        
        # 다양한 변경 유형에 대한 분기 정의
        self.add_branch("hotfix", self._create_hotfix_workflow())
        self.add_branch("configuration", self._create_config_workflow())
        self.add_branch("major_change", self._create_major_change_workflow())
        self.add_branch("test_change", self._create_test_workflow())
        self.add_branch("standard", self._create_standard_workflow())
        
        # 기본 분기 설정
        self.set_default_branch(self._create_standard_workflow())
        
        # 병합 단계 설정
        self.set_merge_stage(ReviewResultMergerAgent({}))
    
    def _create_hotfix_workflow(self) -> SequentialWorkflow:
        """중요한 핫픽스를 위한 빠른 워크플로우"""
        workflow = SequentialWorkflow("hotfix-review")
        workflow.add_stage(SecurityQuickScanAgent({}))
        workflow.add_stage(CriticalIssueDetectorAgent({}))
        return workflow
    
    def _create_major_change_workflow(self) -> SequentialWorkflow:
        """주요 변경사항을 위한 포괄적 워크플로우"""
        workflow = SequentialWorkflow("major-change-review")
        workflow.add_stage(ArchitecturalAnalyzerAgent({}))
        workflow.add_stage(PolishSpecialistAgent({}))
        workflow.add_stage(SecurityGuardianAgent({}))
        workflow.add_stage(PerformanceAnalyzerAgent({}))
        workflow.add_stage(TestEngineerAgent({}))
        return workflow
```

## 2. 고급 협력 패턴

### 분산-수집 패턴

여러 에이전트에 작업을 분산하고 결과를 수집합니다:

```python
# scatter_gather_pattern.py
class ScatterGatherWorkflow:
    """작업 분산 및 수집을 위한 분산-수집 패턴"""
    
    def __init__(self, name: str):
        self.name = name
        self.scatter_agent = None
        self.worker_agents = []
        self.gather_agent = None
        self.load_balancer = LoadBalancer()
    
    def set_scatter_agent(self, agent: JAEAgent):
        """작업을 분산할 에이전트 설정"""
        self.scatter_agent = agent
    
    def add_worker_agent(self, agent: JAEAgent, capacity: int = 1):
        """지정된 용량의 워커 에이전트 추가"""
        worker = WorkerAgent(agent, capacity)
        self.worker_agents.append(worker)
    
    def set_gather_agent(self, agent: JAEAgent):
        """결과를 수집하고 처리할 에이전트 설정"""
        self.gather_agent = agent
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """분산-수집 워크플로우 실행"""
        result = WorkflowResult(self.name)
        
        # 분산 단계: 작업 분산
        if not self.scatter_agent:
            raise WorkflowError("분산 에이전트가 구성되지 않았습니다")
        
        scatter_result = self.scatter_agent.execute(initial_input)
        work_items = scatter_result.get("work_items", [])
        
        # 사용 가능한 워커에 작업 항목 처리
        processed_items = self._process_work_items(work_items)
        result.add_scatter_gather_results(processed_items)
        
        # 수집 단계: 결과 수집 및 처리
        if self.gather_agent:
            gather_input = {
                "original_input": initial_input,
                "processed_items": processed_items,
                "metadata": scatter_result.get("metadata", {})
            }
            
            gathered_result = self.gather_agent.execute(gather_input)
            result.set_final_result(gathered_result)
        
        return result
    
    def _process_work_items(self, work_items: List[Any]) -> List[Any]:
        """사용 가능한 워커 에이전트를 사용하여 작업 항목 처리"""
        processed_items = []
        
        # 용량에 따라 워커에 작업 항목 분산
        work_distribution = self.load_balancer.distribute_work(
            work_items, self.worker_agents
        )
        
        # 병렬로 작업 실행
        with ThreadPoolExecutor() as executor:
            futures = []
            
            for worker, assigned_items in work_distribution.items():
                future = executor.submit(
                    self._execute_worker_batch,
                    worker,
                    assigned_items
                )
                futures.append(future)
            
            # 결과 수집
            for future in as_completed(futures):
                batch_results = future.result()
                processed_items.extend(batch_results)
        
        return processed_items
    
    def _execute_worker_batch(self, worker: WorkerAgent, 
                            work_items: List[Any]) -> List[Any]:
        """워커에서 작업 항목 배치 실행"""
        batch_results = []
        
        for work_item in work_items:
            try:
                result = worker.agent.execute(work_item)
                batch_results.append(result)
            except Exception as e:
                batch_results.append(WorkerError(str(e)))
        
        return batch_results

# 예시: 대규모 코드베이스 분석
class LargeCodebaseAnalysisWorkflow(ScatterGatherWorkflow):
    """워커에 파일을 분산하여 대규모 코드베이스 분석"""
    
    def __init__(self):
        super().__init__("large-codebase-analysis")
        
        # 코드베이스를 분할할 분산 에이전트 설정
        self.set_scatter_agent(CodebasePartitionerAgent({}))
        
        # 여러 분석 워커 추가
        for i in range(4):
            self.add_worker_agent(
                FileAnalyzerAgent({"worker_id": i}),
                capacity=10  # 각 워커는 10개 파일 처리 가능
            )
        
        # 결과를 집계할 수집 에이전트 설정
        self.set_gather_agent(AnalysisAggregatorAgent({}))

class CodebasePartitionerAgent(JAEAgent):
    """코드베이스를 분석 가능한 청크로 분할하는 에이전트"""
    
    def execute(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """코드베이스를 작업 항목으로 분할"""
        codebase_path = input_data.get("codebase_path")
        file_patterns = input_data.get("file_patterns", ["*.py", "*.js", "*.java"])
        
        # 파일 발견
        all_files = self._discover_files(codebase_path, file_patterns)
        
        # 파일을 청크로 분할
        chunk_size = input_data.get("chunk_size", 50)
        work_items = []
        
        for i in range(0, len(all_files), chunk_size):
            chunk = all_files[i:i + chunk_size]
            work_items.append({
                "files": chunk,
                "chunk_id": i // chunk_size,
                "analysis_config": input_data.get("analysis_config", {})
            })
        
        return {
            "work_items": work_items,
            "metadata": {
                "total_files": len(all_files),
                "total_chunks": len(work_items),
                "chunk_size": chunk_size
            }
        }
```

### 이벤트 기반 코레오그래피 패턴

직접적인 오케스트레이션보다는 이벤트를 통해 에이전트를 조율합니다:

```python
# event_driven_pattern.py
class EventDrivenWorkflow:
    """이벤트 기반 코레오그래피 패턴"""
    
    def __init__(self, name: str):
        self.name = name
        self.event_bus = EventBus()
        self.participating_agents = {}
        self.event_history = EventHistory()
        self.completion_conditions = []
    
    def register_agent(self, agent: JAEAgent, event_subscriptions: List[str]):
        """이벤트 구독과 함께 에이전트 등록"""
        agent_wrapper = EventDrivenAgentWrapper(agent, self.event_bus)
        
        for event_type in event_subscriptions:
            self.event_bus.subscribe(event_type, agent_wrapper.handle_event)
        
        self.participating_agents[agent.metadata.name] = agent_wrapper
    
    def add_completion_condition(self, condition: CompletionCondition):
        """워크플로우 완료를 결정하는 조건 추가"""
        self.completion_conditions.append(condition)
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """이벤트 기반 워크플로우 실행"""
        result = WorkflowResult(self.name)
        
        # 워크플로우를 시작하기 위한 초기 이벤트 게시
        initial_event = Event(
            type="workflow_started",
            data=initial_input,
            source="workflow_engine"
        )
        
        self.event_bus.publish(initial_event)
        self.event_history.record(initial_event)
        
        # 완료 조건이 충족될 때까지 이벤트 모니터링
        while not self._is_complete():
            event = self.event_bus.get_next_event(timeout=30)
            
            if event:
                self.event_history.record(event)
                result.add_event(event)
                
                # 오류 이벤트 확인
                if event.type.endswith("_error"):
                    error_handler = self._get_error_handler(event.type)
                    if error_handler:
                        recovery_event = error_handler.handle_error(event)
                        if recovery_event:
                            self.event_bus.publish(recovery_event)
            else:
                # 타임아웃 - 워크플로우가 멈췄는지 확인
                if self._is_stuck():
                    result.mark_failed("timeout", "워크플로우가 멈춘 것 같습니다")
                    break
        
        # 최종 결과 생성
        final_result = self._generate_final_result()
        result.set_final_result(final_result)
        
        return result
    
    def _is_complete(self) -> bool:
        """워크플로우 완료 조건이 충족되었는지 확인"""
        return any(condition.is_met(self.event_history) 
                  for condition in self.completion_conditions)
    
    def _is_stuck(self) -> bool:
        """워크플로우가 멈췄는지 확인"""
        recent_events = self.event_history.get_recent_events(minutes=5)
        return len(recent_events) == 0

class EventDrivenAgentWrapper:
    """에이전트를 이벤트 기반으로 만드는 래퍼"""
    
    def __init__(self, agent: JAEAgent, event_bus: EventBus):
        self.agent = agent
        self.event_bus = event_bus
        self.event_handlers = {}
        self._configure_event_handlers()
    
    def _configure_event_handlers(self):
        """에이전트 기능에 따른 이벤트 핸들러 구성"""
        agent_name = self.agent.metadata.name
        
        # 표준 이벤트 핸들러
        self.event_handlers.update({
            f"{agent_name}_requested": self._handle_execution_request,
            f"{agent_name}_retry": self._handle_retry_request,
            "workflow_paused": self._handle_pause,
            "workflow_resumed": self._handle_resume
        })
        
        # 에이전트별 핸들러
        if hasattr(self.agent, 'get_event_handlers'):
            custom_handlers = self.agent.get_event_handlers()
            self.event_handlers.update(custom_handlers)
    
    def handle_event(self, event: Event):
        """들어오는 이벤트 처리"""
        event_type = event.type
        
        if event_type in self.event_handlers:
            try:
                handler = self.event_handlers[event_type]
                handler(event)
            except Exception as e:
                error_event = Event(
                    type=f"{self.agent.metadata.name}_error",
                    data={"error": str(e), "original_event": event},
                    source=self.agent.metadata.name
                )
                self.event_bus.publish(error_event)
    
    def _handle_execution_request(self, event: Event):
        """실행 요청 이벤트 처리"""
        try:
            result = self.agent.execute(event.data)
            
            # 완료 이벤트 게시
            completion_event = Event(
                type=f"{self.agent.metadata.name}_completed",
                data=result,
                source=self.agent.metadata.name
            )
            self.event_bus.publish(completion_event)
            
        except Exception as e:
            error_event = Event(
                type=f"{self.agent.metadata.name}_failed",
                data={"error": str(e), "input": event.data},
                source=self.agent.metadata.name
            )
            self.event_bus.publish(error_event)

# 예시: CI/CD 파이프라인 워크플로우
class CICDPipelineWorkflow(EventDrivenWorkflow):
    """이벤트 기반 CI/CD 파이프라인"""
    
    def __init__(self):
        super().__init__("cicd-pipeline")
        
        # 이벤트 구독과 함께 에이전트 등록
        self.register_agent(
            SourceControlAgent({}),
            ["workflow_started", "code_pushed"]
        )
        
        self.register_agent(
            BuildAgent({}),
            ["source_control_completed", "build_retry"]
        )
        
        self.register_agent(
            TestAgent({}),
            ["build_completed"]
        )
        
        self.register_agent(
            QualityGateAgent({}),
            ["test_completed"]
        )
        
        self.register_agent(
            DeploymentAgent({}),
            ["quality_gate_passed"]
        )
        
        # 완료 조건 추가
        self.add_completion_condition(
            EventBasedCompletion(["deployment_completed", "deployment_failed"])
        )
```

## 3. 오류 처리 및 복원력 패턴

### 회로 차단기 패턴

에이전트 워크플로우에서 연쇄적 실패를 방지합니다:

```python
# circuit_breaker_pattern.py
from enum import Enum
import time
from threading import Lock

class CircuitState(Enum):
    CLOSED = "closed"      # 정상 동작
    OPEN = "open"          # 빠른 실패
    HALF_OPEN = "half_open"  # 복구 테스트

class CircuitBreaker:
    """에이전트 보호를 위한 회로 차단기"""
    
    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
        self.lock = Lock()
    
    def call(self, func, *args, **kwargs):
        """회로 차단기 보호로 함수 실행"""
        with self.lock:
            if self.state == CircuitState.OPEN:
                if self._should_attempt_reset():
                    self.state = CircuitState.HALF_OPEN
                else:
                    raise CircuitBreakerOpenError("회로 차단기가 열려 있습니다")
            
            try:
                result = func(*args, **kwargs)
                self._on_success()
                return result
                
            except Exception as e:
                self._on_failure()
                raise e
    
    def _should_attempt_reset(self) -> bool:
        """재설정을 시도할 충분한 시간이 지났는지 확인"""
        if not self.last_failure_time:
            return True
        
        time_since_failure = time.time() - self.last_failure_time
        return time_since_failure >= self.recovery_timeout
    
    def _on_success(self):
        """성공적인 실행 처리"""
        self.failure_count = 0
        self.state = CircuitState.CLOSED
    
    def _on_failure(self):
        """실패한 실행 처리"""
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

class ResilientAgent(JAEAgent):
    """내장된 복원력 패턴을 가진 에이전트"""
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.circuit_breaker = CircuitBreaker(
            failure_threshold=config.get("failure_threshold", 5),
            recovery_timeout=config.get("recovery_timeout", 60)
        )
        self.retry_policy = RetryPolicy(
            max_retries=config.get("max_retries", 3),
            backoff_strategy=config.get("backoff_strategy", "exponential")
        )
        self.bulkhead = Bulkhead(
            max_concurrent_executions=config.get("max_concurrent", 10)
        )
    
    def execute(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """복원력 패턴으로 실행"""
        
        # 벌크헤드 패턴 - 동시 실행 제한
        with self.bulkhead:
            # 회로 차단기 패턴 - 연쇄적 실패 방지
            return self.circuit_breaker.call(
                self._execute_with_retry,
                input_data,
                context
            )
    
    def _execute_with_retry(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """재시도 정책으로 실행"""
        last_exception = None
        
        for attempt in range(self.retry_policy.max_retries + 1):
            try:
                return self._do_execute(input_data, context)
                
            except RetryableException as e:
                last_exception = e
                if attempt < self.retry_policy.max_retries:
                    delay = self.retry_policy.calculate_delay(attempt)
                    time.sleep(delay)
                    continue
                else:
                    break
                    
            except NonRetryableException as e:
                raise e
        
        raise MaxRetriesExceededError(f"{self.retry_policy.max_retries}회 재시도 후 실패", last_exception)
```

### 보상 트랜잭션 패턴

다중 에이전트 워크플로우에서 롤백 시나리오를 처리합니다:

```python
# compensation_pattern.py
class CompensatingAction:
    """롤백을 위한 보상 액션을 나타냄"""
    
    def __init__(self, action: callable, data: Any, description: str):
        self.action = action
        self.data = data
        self.description = description
        self.executed = False
    
    def execute(self) -> bool:
        """보상 액션 실행"""
        try:
            self.action(self.data)
            self.executed = True
            return True
        except Exception as e:
            print(f"보상 실패: {self.description} - {str(e)}")
            return False

class CompensatingTransactionWorkflow:
    """보상 트랜잭션 지원이 있는 워크플로우"""
    
    def __init__(self, name: str):
        self.name = name
        self.stages = []
        self.compensating_actions = []
        self.execution_context = {}
    
    def add_stage(self, agent: JAEAgent, compensating_action: Optional[callable] = None):
        """선택적 보상 액션과 함께 단계 추가"""
        stage = CompensatingStage(
            agent=agent,
            compensating_action=compensating_action,
            stage_id=len(self.stages)
        )
        self.stages.append(stage)
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """보상 지원으로 워크플로우 실행"""
        result = WorkflowResult(self.name)
        current_data = initial_input
        executed_stages = []
        
        try:
            for stage in self.stages:
                # 단계 실행
                stage_result = stage.agent.execute(current_data, self.execution_context)
                executed_stages.append(stage)
                
                # 제공된 경우 보상 액션 기록
                if stage.compensating_action:
                    compensation = CompensatingAction(
                        action=stage.compensating_action,
                        data={
                            "stage_input": current_data,
                            "stage_result": stage_result,
                            "context": self.execution_context.copy()
                        },
                        description=f"단계 {stage.stage_id} 보상"
                    )
                    self.compensating_actions.append(compensation)
                
                # 다음 단계를 위한 컨텍스트 및 데이터 업데이트
                self.execution_context[f"stage_{stage.stage_id}_result"] = stage_result
                current_data = stage_result
                result.add_stage_result(stage.stage_id, stage_result)
            
            result.set_final_result(current_data)
            
        except Exception as e:
            # 역순으로 보상 액션 실행
            result.mark_failed(len(executed_stages), str(e))
            compensation_result = self._execute_compensations()
            result.add_compensation_result(compensation_result)
        
        return result
    
    def _execute_compensations(self) -> CompensationResult:
        """모든 보상 액션을 역순으로 실행"""
        compensation_result = CompensationResult()
        
        # 역순으로 보상 실행
        for compensation in reversed(self.compensating_actions):
            success = compensation.execute()
            compensation_result.add_result(compensation.description, success)
            
            if not success:
                compensation_result.mark_partial_failure()
        
        return compensation_result

# 예시: 데이터베이스 마이그레이션 워크플로우
class DatabaseMigrationWorkflow(CompensatingTransactionWorkflow):
    """롤백 지원이 있는 데이터베이스 마이그레이션"""
    
    def __init__(self):
        super().__init__("database-migration")
        
        # 보상 액션과 함께 단계 추가
        self.add_stage(
            BackupDatabaseAgent({}),
            self._cleanup_backup
        )
        
        self.add_stage(
            SchemaMigrationAgent({}),
            self._rollback_schema_changes
        )
        
        self.add_stage(
            DataMigrationAgent({}),
            self._rollback_data_changes
        )
        
        self.add_stage(
            ValidationAgent({}),
            None  # 검증에는 보상이 필요하지 않음
        )
        
        self.add_stage(
            CleanupAgent({}),
            None  # 정리는 이미 보상 액션임
        )
    
    def _cleanup_backup(self, data: Dict):
        """마이그레이션이 롤백되면 백업 제거"""
        backup_path = data.get("stage_result", {}).get("backup_path")
        if backup_path:
            # 백업 파일/데이터베이스 제거
            pass
    
    def _rollback_schema_changes(self, data: Dict):
        """스키마 변경 롤백"""
        backup_path = data.get("context", {}).get("stage_0_result", {}).get("backup_path")
        if backup_path:
            # 백업에서 스키마 복원
            pass
    
    def _rollback_data_changes(self, data: Dict):
        """데이터 변경 롤백"""
        backup_path = data.get("context", {}).get("stage_0_result", {}).get("backup_path")
        if backup_path:
            # 백업에서 데이터 복원
            pass
```

## 4. 성능 최적화 패턴

### 지연 평가 패턴

비용이 많이 드는 작업을 연기하여 워크플로우를 최적화합니다:

```python
# lazy_evaluation_pattern.py
class LazyEvaluationWorkflow:
    """지연 평가 최적화가 있는 워크플로우"""
    
    def __init__(self, name: str):
        self.name = name
        self.stages = []
        self.dependency_graph = DependencyGraph()
        self.evaluation_cache = {}
    
    def add_stage(self, agent: JAEAgent, dependencies: List[str] = None, 
                 lazy: bool = True):
        """의존성 및 지연 평가 구성으로 단계 추가"""
        stage = LazyStage(
            agent=agent,
            dependencies=dependencies or [],
            lazy=lazy,
            stage_id=len(self.stages)
        )
        self.stages.append(stage)
        self.dependency_graph.add_stage(stage)
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """지연 평가로 워크플로우 실행"""
        result = WorkflowResult(self.name)
        
        # 의존성에 따른 실행 순서 결정
        execution_order = self.dependency_graph.topological_sort()
        
        for stage_id in execution_order:
            stage = self.stages[stage_id]
            
            if stage.lazy:
                # 이 단계를 위한 지연 평가자 생성
                lazy_evaluator = LazyEvaluator(
                    stage=stage,
                    input_provider=lambda: self._get_stage_input(stage_id, initial_input),
                    cache=self.evaluation_cache
                )
                result.add_lazy_stage(stage_id, lazy_evaluator)
            else:
                # 즉시 실행
                stage_input = self._get_stage_input(stage_id, initial_input)
                stage_result = stage.agent.execute(stage_input)
                result.add_stage_result(stage_id, stage_result)
                self.evaluation_cache[stage_id] = stage_result
        
        return result
    
    def _get_stage_input(self, stage_id: int, initial_input: Any) -> Any:
        """의존성에 따른 특정 단계의 입력 가져오기"""
        stage = self.stages[stage_id]
        
        if not stage.dependencies:
            return initial_input
        
        # 의존성으로부터 결과 수집
        dependency_results = {}
        for dep_stage_id in stage.dependencies:
            if dep_stage_id in self.evaluation_cache:
                dependency_results[dep_stage_id] = self.evaluation_cache[dep_stage_id]
            else:
                # 의존성 강제 평가
                dep_result = self._force_evaluate_stage(dep_stage_id, initial_input)
                dependency_results[dep_stage_id] = dep_result
                self.evaluation_cache[dep_stage_id] = dep_result
        
        return {
            "initial_input": initial_input,
            "dependencies": dependency_results
        }

class LazyEvaluator:
    """지연된 단계 실행을 위한 지연 평가자"""
    
    def __init__(self, stage: LazyStage, input_provider: callable, cache: Dict):
        self.stage = stage
        self.input_provider = input_provider
        self.cache = cache
        self._result = None
        self._evaluated = False
    
    def evaluate(self):
        """지연 단계의 강제 평가"""
        if not self._evaluated:
            stage_input = self.input_provider()
            self._result = self.stage.agent.execute(stage_input)
            self.cache[self.stage.stage_id] = self._result
            self._evaluated = True
        return self._result
    
    @property
    def result(self):
        """결과 가져오기, 필요시 평가"""
        return self.evaluate()
    
    def is_evaluated(self) -> bool:
        """단계가 평가되었는지 확인"""
        return self._evaluated

# 예시: 조건부 분석 워크플로우
class ConditionalAnalysisWorkflow(LazyEvaluationWorkflow):
    """필요한 단계만 실행하는 분석 워크플로우"""
    
    def __init__(self):
        super().__init__("conditional-analysis")
        
        # 기본 분석 (항상 실행)
        self.add_stage(
            BasicAnalyzerAgent({}),
            dependencies=[],
            lazy=False
        )
        
        # 보안 분석 (지연 - 필요시에만)
        self.add_stage(
            SecurityAnalyzerAgent({}),
            dependencies=[0],  # 기본 분석에 의존
            lazy=True
        )
        
        # 성능 분석 (지연 - 필요시에만)
        self.add_stage(
            PerformanceAnalyzerAgent({}),
            dependencies=[0],
            lazy=True
        )
        
        # 상세 보안 스캔 (지연 - 보안 문제 발견시에만)
        self.add_stage(
            DetailedSecurityScanAgent({}),
            dependencies=[1],  # 보안 분석에 의존
            lazy=True
        )
        
        # 보고서 생성기 (모든 분석에 의존)
        self.add_stage(
            ConditionalReportAgent({}),
            dependencies=[0, 1, 2, 3],
            lazy=False
        )
```

### 스트리밍 및 증분 처리

대용량 데이터셋을 증분적으로 처리합니다:

```python
# streaming_pattern.py
from typing import Iterator, Generator
import asyncio

class StreamingWorkflow:
    """스트리밍/증분 처리에 최적화된 워크플로우"""
    
    def __init__(self, name: str, batch_size: int = 100):
        self.name = name
        self.batch_size = batch_size
        self.stream_processors = []
        self.result_accumulator = ResultAccumulator()
    
    def add_stream_processor(self, agent: JAEAgent, buffer_size: int = None):
        """에이전트를 스트림 프로세서로 추가"""
        processor = StreamProcessor(
            agent=agent,
            buffer_size=buffer_size or self.batch_size
        )
        self.stream_processors.append(processor)
    
    def execute_stream(self, data_stream: Iterator) -> StreamingResult:
        """스트리밍 데이터에서 워크플로우 실행"""
        result = StreamingResult(self.name)
        
        # 처리 파이프라인 생성
        pipeline = self._create_processing_pipeline(data_stream)
        
        # 배치로 스트림 처리
        batch_count = 0
        for batch_result in pipeline:
            result.add_batch_result(batch_count, batch_result)
            batch_count += 1
            
            # 구성된 경우 중간 결과 배출
            if batch_count % 10 == 0:  # 10배치마다
                intermediate_result = self.result_accumulator.get_intermediate_result()
                result.emit_intermediate(batch_count, intermediate_result)
        
        # 최종 결과 생성
        final_result = self.result_accumulator.get_final_result()
        result.set_final_result(final_result)
        
        return result
    
    def _create_processing_pipeline(self, data_stream: Iterator) -> Generator:
        """스트리밍 데이터를 위한 처리 파이프라인 생성"""
        
        # 데이터 스트림을 배치로 변환
        batch_stream = self._batch_stream(data_stream, self.batch_size)
        
        # 각 프로세서를 순서대로 적용
        current_stream = batch_stream
        for processor in self.stream_processors:
            current_stream = processor.process_stream(current_stream)
        
        return current_stream
    
    def _batch_stream(self, data_stream: Iterator, batch_size: int) -> Generator:
        """데이터 스트림을 배치로 변환"""
        batch = []
        
        for item in data_stream:
            batch.append(item)
            
            if len(batch) >= batch_size:
                yield batch
                batch = []
        
        # 나머지 항목 산출
        if batch:
            yield batch

class StreamProcessor:
    """스트리밍 데이터를 처리하는 에이전트 래퍼"""
    
    def __init__(self, agent: JAEAgent, buffer_size: int = 100):
        self.agent = agent
        self.buffer_size = buffer_size
        self.input_buffer = []
        self.output_buffer = []
    
    def process_stream(self, input_stream: Iterator) -> Generator:
        """에이전트를 통해 스트리밍 데이터 처리"""
        
        for batch in input_stream:
            # 버퍼에 배치 추가
            self.input_buffer.extend(batch)
            
            # 버퍼가 가득 찼을 때 처리
            while len(self.input_buffer) >= self.buffer_size:
                process_batch = self.input_buffer[:self.buffer_size]
                self.input_buffer = self.input_buffer[self.buffer_size:]
                
                # 에이전트를 통해 배치 처리
                batch_result = self.agent.execute({
                    "batch": process_batch,
                    "batch_size": len(process_batch)
                })
                
                self.output_buffer.append(batch_result)
                
                # 출력 버퍼가 준비되면 산출
                if len(self.output_buffer) >= 5:  # 처리된 배치 5개마다 산출
                    yield self.output_buffer
                    self.output_buffer = []
        
        # 나머지 항목 처리
        if self.input_buffer:
            final_result = self.agent.execute({
                "batch": self.input_buffer,
                "batch_size": len(self.input_buffer)
            })
            self.output_buffer.append(final_result)
        
        # 최종 출력 버퍼 산출
        if self.output_buffer:
            yield self.output_buffer

# 예시: 대용량 데이터셋 처리
class LargeDatasetProcessingWorkflow(StreamingWorkflow):
    """대용량 데이터셋을 증분적으로 처리"""
    
    def __init__(self):
        super().__init__("large-dataset-processing", batch_size=1000)
        
        # 순서대로 스트림 프로세서 추가
        self.add_stream_processor(
            DataCleaningAgent({}),
            buffer_size=500
        )
        
        self.add_stream_processor(
            DataValidationAgent({}),
            buffer_size=1000
        )
        
        self.add_stream_processor(
            DataTransformationAgent({}),
            buffer_size=750
        )
        
        self.add_stream_processor(
            DataAnalysisAgent({}),
            buffer_size=200
        )
    
    def process_csv_file(self, file_path: str) -> StreamingResult:
        """대용량 CSV 파일을 증분적으로 처리"""
        
        def csv_stream():
            import csv
            with open(file_path, 'r') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    yield row
        
        return self.execute_stream(csv_stream())
```

## 5. 요약

워크플로우 디자인 패턴은 정교하고 신뢰할 수 있으며 효율적인 에이전틱 워크플로우를 생성하는 강력한 도구를 제공합니다. 이러한 패턴을 적절히 이해하고 적용함으로써 성능과 신뢰성을 유지하면서 복잡한 시나리오를 처리하는 시스템을 구축할 수 있습니다.

### 주요 패턴 범주

✅ **기본 패턴**: 기본 협력을 위한 순차, 병렬, 조건부 워크플로우

✅ **고급 협력**: 복잡한 시나리오를 위한 분산-수집 및 이벤트 기반 패턴

✅ **복원력 패턴**: 오류 처리를 위한 회로 차단기 및 보상 트랜잭션

✅ **성능 패턴**: 최적화를 위한 지연 평가 및 스트리밍

✅ **도메인별 패턴**: 일반적인 사용 사례를 위한 전문화된 패턴

### 패턴 선택 가이드라인

1. **단순하게 시작**: 기본 패턴으로 시작하고 필요에 따라 복잡성 추가
2. **규모 고려**: 데이터와 팀 크기에 맞게 확장되는 패턴 선택
3. **실패 계획**: 항상 오류 처리 및 복원력 패턴 포함
4. **신중한 최적화**: 필요할 때만 성능 패턴 추가
5. **결정 문서화**: 특정 패턴을 선택한 이유 기록

## 연습 문제

1. **패턴 분석**: 조직의 기존 워크플로우를 분석하고 개선할 수 있는 패턴 식별
2. **패턴 구현**: 입력 특성에 따라 적응하는 조건부 워크플로우 구현
3. **오류 처리**: 기존 에이전트에 회로 차단기 및 재시도 패턴 추가
4. **성능 최적화**: 대용량 데이터셋 처리를 위한 스트리밍 워크플로우 설계
5. **사용자 정의 패턴**: 도메인의 특정 과제를 위한 새로운 워크플로우 패턴 생성

## 추가 읽기

- [엔터프라이즈 구현](09-enterprise-implementation.md)
- [팀 협업 전략](10-team-collaboration.md)
- [문제 해결 가이드](11-troubleshooting.md)
- [성능 최적화 쿡북](appendix-performance.md)

---

*다음 장: [엔터프라이즈 구현](09-enterprise-implementation.md) - 대규모 조직에서 JAE 워크플로우 확장*