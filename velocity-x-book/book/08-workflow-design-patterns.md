---
title: Workflow Design Patterns
chapter: 8
author: VELOCITY-X Team
date: 2025-07-27
reading_time: 28 minutes
---

# Workflow Design Patterns

> *"Patterns are solutions to problems in a context. Great workflows emerge when you apply the right patterns to solve complex coordination challenges."* - Christopher Alexander (adapted)

## Overview

Workflow design patterns provide proven solutions to common challenges in agentic development. This chapter explores sophisticated patterns for orchestrating multiple agents, handling complex data flows, managing errors gracefully, and scaling workflows for enterprise environments.

By the end of this chapter, you'll understand:
- Core workflow patterns and when to apply them
- Advanced coordination mechanisms for complex scenarios
- Error handling and resilience patterns
- Performance optimization patterns for large-scale workflows
- Domain-specific workflow patterns for common use cases

## 1. Fundamental Workflow Patterns

### Sequential Processing Pattern

The most basic pattern where agents execute in a predetermined order:

```python
# sequential_pattern.py
class SequentialWorkflow:
    """Sequential processing pattern implementation"""
    
    def __init__(self, name: str):
        self.name = name
        self.stages = []
        self.context = WorkflowContext()
        self.error_handler = ErrorHandler()
    
    def add_stage(self, agent: VELOCITY-XAgent, input_transform: Optional[callable] = None):
        """Add a stage to the sequential workflow"""
        stage = WorkflowStage(
            agent=agent,
            input_transform=input_transform,
            stage_id=len(self.stages)
        )
        self.stages.append(stage)
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """Execute the sequential workflow"""
        result = WorkflowResult(self.name)
        current_data = initial_input
        
        for i, stage in enumerate(self.stages):
            try:
                # Transform input if needed
                if stage.input_transform:
                    stage_input = stage.input_transform(current_data, self.context)
                else:
                    stage_input = current_data
                
                # Execute stage
                stage_result = stage.agent.execute(stage_input, self.context.to_dict())
                
                # Update context and prepare for next stage
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

# Example: Code Quality Pipeline
class CodeQualityPipeline(SequentialWorkflow):
    """Sequential pipeline for code quality improvement"""
    
    def __init__(self):
        super().__init__("code-quality-pipeline")
        
        # Add stages in order
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
        """Transform input for Polish Specialist"""
        return {
            "source_code": data,
            "quality_standards": context.get("quality_standards"),
            "performance_targets": context.get("performance_targets")
        }
    
    def _prepare_review_input(self, data: Any, context: WorkflowContext) -> Any:
        """Transform input for Code Reviewer"""
        polish_result = context.get_stage_result(0)
        return {
            "original_code": context.get("initial_input"),
            "polished_code": data,
            "polish_improvements": polish_result.get("improvements", [])
        }
```

### Parallel Processing Pattern

Execute multiple agents simultaneously when tasks are independent:

```python
# parallel_pattern.py
import asyncio
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Dict, List, Tuple

class ParallelWorkflow:
    """Parallel processing pattern implementation"""
    
    def __init__(self, name: str, max_workers: int = 4):
        self.name = name
        self.parallel_stages = []
        self.aggregation_stage = None
        self.max_workers = max_workers
        self.execution_strategy = ParallelExecutionStrategy.THREAD_POOL
    
    def add_parallel_stage(self, agent: VELOCITY-XAgent, input_transform: Optional[callable] = None):
        """Add an agent to execute in parallel"""
        stage = ParallelStage(
            agent=agent,
            input_transform=input_transform,
            stage_id=len(self.parallel_stages)
        )
        self.parallel_stages.append(stage)
    
    def set_aggregation_stage(self, aggregator_agent: VELOCITY-XAgent):
        """Set the agent that will aggregate parallel results"""
        self.aggregation_stage = aggregator_agent
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """Execute parallel workflow"""
        if self.execution_strategy == ParallelExecutionStrategy.THREAD_POOL:
            return self._execute_with_threads(initial_input)
        elif self.execution_strategy == ParallelExecutionStrategy.ASYNC:
            return asyncio.run(self._execute_async(initial_input))
        else:
            return self._execute_with_multiprocessing(initial_input)
    
    def _execute_with_threads(self, initial_input: Any) -> WorkflowResult:
        """Execute using thread pool"""
        result = WorkflowResult(self.name)
        
        def execute_stage(stage: ParallelStage) -> Tuple[int, Any]:
            try:
                # Transform input for this stage
                if stage.input_transform:
                    stage_input = stage.input_transform(initial_input)
                else:
                    stage_input = initial_input
                
                # Execute stage
                stage_result = stage.agent.execute(stage_input)
                return stage.stage_id, stage_result
                
            except Exception as e:
                return stage.stage_id, StageError(str(e))
        
        # Execute all parallel stages
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
        
        # Aggregate results if aggregator is configured
        if self.aggregation_stage:
            try:
                aggregated_result = self.aggregation_stage.execute(parallel_results)
                result.set_final_result(aggregated_result)
            except Exception as e:
                result.mark_failed("aggregation", str(e))
        
        return result
    
    async def _execute_async(self, initial_input: Any) -> WorkflowResult:
        """Execute using asyncio for I/O bound tasks"""
        result = WorkflowResult(self.name)
        
        async def execute_stage_async(stage: ParallelStage) -> Tuple[int, Any]:
            try:
                # Transform input
                if stage.input_transform:
                    stage_input = stage.input_transform(initial_input)
                else:
                    stage_input = initial_input
                
                # Execute stage (wrap in executor if agent is not async)
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
        
        # Execute all stages concurrently
        tasks = [execute_stage_async(stage) for stage in self.parallel_stages]
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Process results
        parallel_results = {}
        for stage_id, stage_result in results:
            parallel_results[stage_id] = stage_result
            result.add_parallel_result(stage_id, stage_result)
        
        # Aggregate if configured
        if self.aggregation_stage:
            aggregated_result = await self._execute_aggregation_async(parallel_results)
            result.set_final_result(aggregated_result)
        
        return result

# Example: Multi-Aspect Analysis Workflow
class MultiAspectAnalysisWorkflow(ParallelWorkflow):
    """Analyze code from multiple perspectives in parallel"""
    
    def __init__(self):
        super().__init__("multi-aspect-analysis", max_workers=6)
        
        # Add parallel analysis agents
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
        
        # Set aggregator
        self.set_aggregation_stage(
            AnalysisAggregatorAgent({})
        )
    
    def _prepare_security_input(self, data: Any) -> Any:
        """Prepare input for security analysis"""
        return {
            "code": data,
            "analysis_type": "security",
            "depth": "comprehensive"
        }
    
    def _prepare_performance_input(self, data: Any) -> Any:
        """Prepare input for performance analysis"""
        return {
            "code": data,
            "analysis_type": "performance",
            "include_benchmarks": True
        }
```

### Conditional Branching Pattern

Route workflow execution based on runtime conditions:

```python
# conditional_pattern.py
class ConditionalWorkflow:
    """Conditional branching pattern implementation"""
    
    def __init__(self, name: str):
        self.name = name
        self.condition_evaluator = None
        self.branches = {}
        self.default_branch = None
        self.merge_stage = None
    
    def set_condition_evaluator(self, evaluator_agent: VELOCITY-XAgent):
        """Set the agent that evaluates conditions"""
        self.condition_evaluator = evaluator_agent
    
    def add_branch(self, condition: str, workflow: WorkflowPattern):
        """Add a conditional branch"""
        self.branches[condition] = workflow
    
    def set_default_branch(self, workflow: WorkflowPattern):
        """Set the default branch when no conditions match"""
        self.default_branch = workflow
    
    def set_merge_stage(self, merger_agent: VELOCITY-XAgent):
        """Set the agent that merges branch results"""
        self.merge_stage = merger_agent
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """Execute conditional workflow"""
        result = WorkflowResult(self.name)
        
        # Evaluate condition
        if not self.condition_evaluator:
            raise WorkflowError("No condition evaluator configured")
        
        try:
            condition_result = self.condition_evaluator.execute(initial_input)
            selected_branch = condition_result.get("selected_branch")
            
            # Execute selected branch
            if selected_branch in self.branches:
                branch_workflow = self.branches[selected_branch]
                branch_result = branch_workflow.execute(initial_input)
                result.add_branch_result(selected_branch, branch_result)
            elif self.default_branch:
                branch_result = self.default_branch.execute(initial_input)
                result.add_branch_result("default", branch_result)
            else:
                raise WorkflowError(f"No branch found for condition: {selected_branch}")
            
            # Merge results if configured
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

class ChangeTypeEvaluatorAgent(VELOCITY-XAgent):
    """Agent that evaluates the type of code change"""
    
    def execute(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """Evaluate change type and select appropriate workflow"""
        changeset = input_data.get("changeset", {})
        
        # Analyze change characteristics
        files_changed = len(changeset.get("files", []))
        lines_added = changeset.get("lines_added", 0)
        lines_removed = changeset.get("lines_removed", 0)
        affects_tests = any("test" in f.get("path", "") for f in changeset.get("files", []))
        affects_config = any("config" in f.get("path", "") for f in changeset.get("files", []))
        
        # Decision logic
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

# Example: Adaptive Code Review Workflow
class AdaptiveCodeReviewWorkflow(ConditionalWorkflow):
    """Workflow that adapts based on change characteristics"""
    
    def __init__(self):
        super().__init__("adaptive-code-review")
        
        # Set condition evaluator
        self.set_condition_evaluator(ChangeTypeEvaluatorAgent({}))
        
        # Define branches for different change types
        self.add_branch("hotfix", self._create_hotfix_workflow())
        self.add_branch("configuration", self._create_config_workflow())
        self.add_branch("major_change", self._create_major_change_workflow())
        self.add_branch("test_change", self._create_test_workflow())
        self.add_branch("standard", self._create_standard_workflow())
        
        # Set default branch
        self.set_default_branch(self._create_standard_workflow())
        
        # Set merge stage
        self.set_merge_stage(ReviewResultMergerAgent({}))
    
    def _create_hotfix_workflow(self) -> SequentialWorkflow:
        """Fast workflow for critical hotfixes"""
        workflow = SequentialWorkflow("hotfix-review")
        workflow.add_stage(SecurityQuickScanAgent({}))
        workflow.add_stage(CriticalIssueDetectorAgent({}))
        return workflow
    
    def _create_major_change_workflow(self) -> SequentialWorkflow:
        """Comprehensive workflow for major changes"""
        workflow = SequentialWorkflow("major-change-review")
        workflow.add_stage(ArchitecturalAnalyzerAgent({}))
        workflow.add_stage(PolishSpecialistAgent({}))
        workflow.add_stage(SecurityGuardianAgent({}))
        workflow.add_stage(PerformanceAnalyzerAgent({}))
        workflow.add_stage(TestEngineerAgent({}))
        return workflow
```

## 2. Advanced Coordination Patterns

### Scatter-Gather Pattern

Distribute work across multiple agents and collect results:

```python
# scatter_gather_pattern.py
class ScatterGatherWorkflow:
    """Scatter-gather pattern for distributing and collecting work"""
    
    def __init__(self, name: str):
        self.name = name
        self.scatter_agent = None
        self.worker_agents = []
        self.gather_agent = None
        self.load_balancer = LoadBalancer()
    
    def set_scatter_agent(self, agent: VELOCITY-XAgent):
        """Set the agent that distributes work"""
        self.scatter_agent = agent
    
    def add_worker_agent(self, agent: VELOCITY-XAgent, capacity: int = 1):
        """Add a worker agent with specified capacity"""
        worker = WorkerAgent(agent, capacity)
        self.worker_agents.append(worker)
    
    def set_gather_agent(self, agent: VELOCITY-XAgent):
        """Set the agent that collects and processes results"""
        self.gather_agent = agent
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """Execute scatter-gather workflow"""
        result = WorkflowResult(self.name)
        
        # Scatter phase: distribute work
        if not self.scatter_agent:
            raise WorkflowError("No scatter agent configured")
        
        scatter_result = self.scatter_agent.execute(initial_input)
        work_items = scatter_result.get("work_items", [])
        
        # Process work items across available workers
        processed_items = self._process_work_items(work_items)
        result.add_scatter_gather_results(processed_items)
        
        # Gather phase: collect and process results
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
        """Process work items using available worker agents"""
        processed_items = []
        
        # Distribute work items to workers based on capacity
        work_distribution = self.load_balancer.distribute_work(
            work_items, self.worker_agents
        )
        
        # Execute work in parallel
        with ThreadPoolExecutor() as executor:
            futures = []
            
            for worker, assigned_items in work_distribution.items():
                future = executor.submit(
                    self._execute_worker_batch,
                    worker,
                    assigned_items
                )
                futures.append(future)
            
            # Collect results
            for future in as_completed(futures):
                batch_results = future.result()
                processed_items.extend(batch_results)
        
        return processed_items
    
    def _execute_worker_batch(self, worker: WorkerAgent, 
                            work_items: List[Any]) -> List[Any]:
        """Execute a batch of work items on a worker"""
        batch_results = []
        
        for work_item in work_items:
            try:
                result = worker.agent.execute(work_item)
                batch_results.append(result)
            except Exception as e:
                batch_results.append(WorkerError(str(e)))
        
        return batch_results

# Example: Large Codebase Analysis
class LargeCodebaseAnalysisWorkflow(ScatterGatherWorkflow):
    """Analyze large codebase by distributing files across workers"""
    
    def __init__(self):
        super().__init__("large-codebase-analysis")
        
        # Set scatter agent to divide codebase
        self.set_scatter_agent(CodebasePartitionerAgent({}))
        
        # Add multiple analysis workers
        for i in range(4):
            self.add_worker_agent(
                FileAnalyzerAgent({"worker_id": i}),
                capacity=10  # Each worker can handle 10 files
            )
        
        # Set gather agent to aggregate results
        self.set_gather_agent(AnalysisAggregatorAgent({}))

class CodebasePartitionerAgent(VELOCITY-XAgent):
    """Agent that partitions codebase into analyzable chunks"""
    
    def execute(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """Partition codebase into work items"""
        codebase_path = input_data.get("codebase_path")
        file_patterns = input_data.get("file_patterns", ["*.py", "*.js", "*.java"])
        
        # Discover files
        all_files = self._discover_files(codebase_path, file_patterns)
        
        # Partition files into chunks
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

### Event-Driven Choreography Pattern

Coordinate agents through events rather than direct orchestration:

```python
# event_driven_pattern.py
class EventDrivenWorkflow:
    """Event-driven choreography pattern"""
    
    def __init__(self, name: str):
        self.name = name
        self.event_bus = EventBus()
        self.participating_agents = {}
        self.event_history = EventHistory()
        self.completion_conditions = []
    
    def register_agent(self, agent: VELOCITY-XAgent, event_subscriptions: List[str]):
        """Register an agent with its event subscriptions"""
        agent_wrapper = EventDrivenAgentWrapper(agent, self.event_bus)
        
        for event_type in event_subscriptions:
            self.event_bus.subscribe(event_type, agent_wrapper.handle_event)
        
        self.participating_agents[agent.metadata.name] = agent_wrapper
    
    def add_completion_condition(self, condition: CompletionCondition):
        """Add condition that determines workflow completion"""
        self.completion_conditions.append(condition)
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """Execute event-driven workflow"""
        result = WorkflowResult(self.name)
        
        # Publish initial event to start the workflow
        initial_event = Event(
            type="workflow_started",
            data=initial_input,
            source="workflow_engine"
        )
        
        self.event_bus.publish(initial_event)
        self.event_history.record(initial_event)
        
        # Monitor events until completion conditions are met
        while not self._is_complete():
            event = self.event_bus.get_next_event(timeout=30)
            
            if event:
                self.event_history.record(event)
                result.add_event(event)
                
                # Check for error events
                if event.type.endswith("_error"):
                    error_handler = self._get_error_handler(event.type)
                    if error_handler:
                        recovery_event = error_handler.handle_error(event)
                        if recovery_event:
                            self.event_bus.publish(recovery_event)
            else:
                # Timeout - check if workflow is stuck
                if self._is_stuck():
                    result.mark_failed("timeout", "Workflow appears to be stuck")
                    break
        
        # Generate final result
        final_result = self._generate_final_result()
        result.set_final_result(final_result)
        
        return result
    
    def _is_complete(self) -> bool:
        """Check if workflow completion conditions are met"""
        return any(condition.is_met(self.event_history) 
                  for condition in self.completion_conditions)
    
    def _is_stuck(self) -> bool:
        """Check if workflow appears to be stuck"""
        recent_events = self.event_history.get_recent_events(minutes=5)
        return len(recent_events) == 0

class EventDrivenAgentWrapper:
    """Wrapper that makes agents event-driven"""
    
    def __init__(self, agent: VELOCITY-XAgent, event_bus: EventBus):
        self.agent = agent
        self.event_bus = event_bus
        self.event_handlers = {}
        self._configure_event_handlers()
    
    def _configure_event_handlers(self):
        """Configure event handlers based on agent capabilities"""
        agent_name = self.agent.metadata.name
        
        # Standard event handlers
        self.event_handlers.update({
            f"{agent_name}_requested": self._handle_execution_request,
            f"{agent_name}_retry": self._handle_retry_request,
            "workflow_paused": self._handle_pause,
            "workflow_resumed": self._handle_resume
        })
        
        # Agent-specific handlers
        if hasattr(self.agent, 'get_event_handlers'):
            custom_handlers = self.agent.get_event_handlers()
            self.event_handlers.update(custom_handlers)
    
    def handle_event(self, event: Event):
        """Handle incoming events"""
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
        """Handle execution request events"""
        try:
            result = self.agent.execute(event.data)
            
            # Publish completion event
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

# Example: CI/CD Pipeline Workflow
class CICDPipelineWorkflow(EventDrivenWorkflow):
    """Event-driven CI/CD pipeline"""
    
    def __init__(self):
        super().__init__("cicd-pipeline")
        
        # Register agents with their event subscriptions
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
        
        # Add completion conditions
        self.add_completion_condition(
            EventBasedCompletion(["deployment_completed", "deployment_failed"])
        )
```

## 3. Error Handling and Resilience Patterns

### Circuit Breaker Pattern

Prevent cascading failures in agent workflows:

```python
# circuit_breaker_pattern.py
from enum import Enum
import time
from threading import Lock

class CircuitState(Enum):
    CLOSED = "closed"      # Normal operation
    OPEN = "open"          # Failing fast
    HALF_OPEN = "half_open"  # Testing recovery

class CircuitBreaker:
    """Circuit breaker for agent protection"""
    
    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
        self.lock = Lock()
    
    def call(self, func, *args, **kwargs):
        """Execute function with circuit breaker protection"""
        with self.lock:
            if self.state == CircuitState.OPEN:
                if self._should_attempt_reset():
                    self.state = CircuitState.HALF_OPEN
                else:
                    raise CircuitBreakerOpenError("Circuit breaker is open")
            
            try:
                result = func(*args, **kwargs)
                self._on_success()
                return result
                
            except Exception as e:
                self._on_failure()
                raise e
    
    def _should_attempt_reset(self) -> bool:
        """Check if enough time has passed to attempt reset"""
        if not self.last_failure_time:
            return True
        
        time_since_failure = time.time() - self.last_failure_time
        return time_since_failure >= self.recovery_timeout
    
    def _on_success(self):
        """Handle successful execution"""
        self.failure_count = 0
        self.state = CircuitState.CLOSED
    
    def _on_failure(self):
        """Handle failed execution"""
        self.failure_count += 1
        self.last_failure_time = time.time()
        
        if self.failure_count >= self.failure_threshold:
            self.state = CircuitState.OPEN

class ResilientAgent(VELOCITY-XAgent):
    """Agent with built-in resilience patterns"""
    
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
        """Execute with resilience patterns"""
        
        # Bulkhead pattern - limit concurrent executions
        with self.bulkhead:
            # Circuit breaker pattern - prevent cascading failures
            return self.circuit_breaker.call(
                self._execute_with_retry,
                input_data,
                context
            )
    
    def _execute_with_retry(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """Execute with retry policy"""
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
        
        raise MaxRetriesExceededError(f"Failed after {self.retry_policy.max_retries} retries", last_exception)
```

### Compensating Transaction Pattern

Handle rollback scenarios in multi-agent workflows:

```python
# compensation_pattern.py
class CompensatingAction:
    """Represents a compensating action for rollback"""
    
    def __init__(self, action: callable, data: Any, description: str):
        self.action = action
        self.data = data
        self.description = description
        self.executed = False
    
    def execute(self) -> bool:
        """Execute the compensating action"""
        try:
            self.action(self.data)
            self.executed = True
            return True
        except Exception as e:
            print(f"Compensation failed: {self.description} - {str(e)}")
            return False

class CompensatingTransactionWorkflow:
    """Workflow with compensating transaction support"""
    
    def __init__(self, name: str):
        self.name = name
        self.stages = []
        self.compensating_actions = []
        self.execution_context = {}
    
    def add_stage(self, agent: VELOCITY-XAgent, compensating_action: Optional[callable] = None):
        """Add a stage with optional compensating action"""
        stage = CompensatingStage(
            agent=agent,
            compensating_action=compensating_action,
            stage_id=len(self.stages)
        )
        self.stages.append(stage)
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """Execute workflow with compensation support"""
        result = WorkflowResult(self.name)
        current_data = initial_input
        executed_stages = []
        
        try:
            for stage in self.stages:
                # Execute stage
                stage_result = stage.agent.execute(current_data, self.execution_context)
                executed_stages.append(stage)
                
                # Record compensating action if provided
                if stage.compensating_action:
                    compensation = CompensatingAction(
                        action=stage.compensating_action,
                        data={
                            "stage_input": current_data,
                            "stage_result": stage_result,
                            "context": self.execution_context.copy()
                        },
                        description=f"Compensate stage {stage.stage_id}"
                    )
                    self.compensating_actions.append(compensation)
                
                # Update context and data for next stage
                self.execution_context[f"stage_{stage.stage_id}_result"] = stage_result
                current_data = stage_result
                result.add_stage_result(stage.stage_id, stage_result)
            
            result.set_final_result(current_data)
            
        except Exception as e:
            # Execute compensating actions in reverse order
            result.mark_failed(len(executed_stages), str(e))
            compensation_result = self._execute_compensations()
            result.add_compensation_result(compensation_result)
        
        return result
    
    def _execute_compensations(self) -> CompensationResult:
        """Execute all compensating actions in reverse order"""
        compensation_result = CompensationResult()
        
        # Execute compensations in reverse order
        for compensation in reversed(self.compensating_actions):
            success = compensation.execute()
            compensation_result.add_result(compensation.description, success)
            
            if not success:
                compensation_result.mark_partial_failure()
        
        return compensation_result

# Example: Database Migration Workflow
class DatabaseMigrationWorkflow(CompensatingTransactionWorkflow):
    """Database migration with rollback support"""
    
    def __init__(self):
        super().__init__("database-migration")
        
        # Add stages with compensating actions
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
            None  # No compensation needed for validation
        )
        
        self.add_stage(
            CleanupAgent({}),
            None  # Cleanup is already a compensating action
        )
    
    def _cleanup_backup(self, data: Dict):
        """Remove backup if migration is rolled back"""
        backup_path = data.get("stage_result", {}).get("backup_path")
        if backup_path:
            # Remove backup file/database
            pass
    
    def _rollback_schema_changes(self, data: Dict):
        """Rollback schema changes"""
        backup_path = data.get("context", {}).get("stage_0_result", {}).get("backup_path")
        if backup_path:
            # Restore schema from backup
            pass
    
    def _rollback_data_changes(self, data: Dict):
        """Rollback data changes"""
        backup_path = data.get("context", {}).get("stage_0_result", {}).get("backup_path")
        if backup_path:
            # Restore data from backup
            pass
```

## 4. Performance Optimization Patterns

### Lazy Evaluation Pattern

Optimize workflows by deferring expensive operations:

```python
# lazy_evaluation_pattern.py
class LazyEvaluationWorkflow:
    """Workflow with lazy evaluation optimization"""
    
    def __init__(self, name: str):
        self.name = name
        self.stages = []
        self.dependency_graph = DependencyGraph()
        self.evaluation_cache = {}
    
    def add_stage(self, agent: VELOCITY-XAgent, dependencies: List[str] = None, 
                 lazy: bool = True):
        """Add a stage with dependency and lazy evaluation configuration"""
        stage = LazyStage(
            agent=agent,
            dependencies=dependencies or [],
            lazy=lazy,
            stage_id=len(self.stages)
        )
        self.stages.append(stage)
        self.dependency_graph.add_stage(stage)
    
    def execute(self, initial_input: Any) -> WorkflowResult:
        """Execute workflow with lazy evaluation"""
        result = WorkflowResult(self.name)
        
        # Determine execution order based on dependencies
        execution_order = self.dependency_graph.topological_sort()
        
        for stage_id in execution_order:
            stage = self.stages[stage_id]
            
            if stage.lazy:
                # Create lazy evaluator for this stage
                lazy_evaluator = LazyEvaluator(
                    stage=stage,
                    input_provider=lambda: self._get_stage_input(stage_id, initial_input),
                    cache=self.evaluation_cache
                )
                result.add_lazy_stage(stage_id, lazy_evaluator)
            else:
                # Execute immediately
                stage_input = self._get_stage_input(stage_id, initial_input)
                stage_result = stage.agent.execute(stage_input)
                result.add_stage_result(stage_id, stage_result)
                self.evaluation_cache[stage_id] = stage_result
        
        return result
    
    def _get_stage_input(self, stage_id: int, initial_input: Any) -> Any:
        """Get input for a specific stage based on dependencies"""
        stage = self.stages[stage_id]
        
        if not stage.dependencies:
            return initial_input
        
        # Collect results from dependencies
        dependency_results = {}
        for dep_stage_id in stage.dependencies:
            if dep_stage_id in self.evaluation_cache:
                dependency_results[dep_stage_id] = self.evaluation_cache[dep_stage_id]
            else:
                # Force evaluation of dependency
                dep_result = self._force_evaluate_stage(dep_stage_id, initial_input)
                dependency_results[dep_stage_id] = dep_result
                self.evaluation_cache[dep_stage_id] = dep_result
        
        return {
            "initial_input": initial_input,
            "dependencies": dependency_results
        }

class LazyEvaluator:
    """Lazy evaluator for deferred stage execution"""
    
    def __init__(self, stage: LazyStage, input_provider: callable, cache: Dict):
        self.stage = stage
        self.input_provider = input_provider
        self.cache = cache
        self._result = None
        self._evaluated = False
    
    def evaluate(self):
        """Force evaluation of the lazy stage"""
        if not self._evaluated:
            stage_input = self.input_provider()
            self._result = self.stage.agent.execute(stage_input)
            self.cache[self.stage.stage_id] = self._result
            self._evaluated = True
        return self._result
    
    @property
    def result(self):
        """Get result, evaluating if necessary"""
        return self.evaluate()
    
    def is_evaluated(self) -> bool:
        """Check if stage has been evaluated"""
        return self._evaluated

# Example: Conditional Analysis Workflow
class ConditionalAnalysisWorkflow(LazyEvaluationWorkflow):
    """Analysis workflow that only executes necessary stages"""
    
    def __init__(self):
        super().__init__("conditional-analysis")
        
        # Basic analysis (always executed)
        self.add_stage(
            BasicAnalyzerAgent({}),
            dependencies=[],
            lazy=False
        )
        
        # Security analysis (lazy - only if needed)
        self.add_stage(
            SecurityAnalyzerAgent({}),
            dependencies=[0],  # Depends on basic analysis
            lazy=True
        )
        
        # Performance analysis (lazy - only if needed)
        self.add_stage(
            PerformanceAnalyzerAgent({}),
            dependencies=[0],
            lazy=True
        )
        
        # Detailed security scan (lazy - only if security issues found)
        self.add_stage(
            DetailedSecurityScanAgent({}),
            dependencies=[1],  # Depends on security analysis
            lazy=True
        )
        
        # Report generator (depends on all analyses)
        self.add_stage(
            ConditionalReportAgent({}),
            dependencies=[0, 1, 2, 3],
            lazy=False
        )
```

### Streaming and Incremental Processing

Process large datasets incrementally:

```python
# streaming_pattern.py
from typing import Iterator, Generator
import asyncio

class StreamingWorkflow:
    """Workflow optimized for streaming/incremental processing"""
    
    def __init__(self, name: str, batch_size: int = 100):
        self.name = name
        self.batch_size = batch_size
        self.stream_processors = []
        self.result_accumulator = ResultAccumulator()
    
    def add_stream_processor(self, agent: VELOCITY-XAgent, buffer_size: int = None):
        """Add an agent as a stream processor"""
        processor = StreamProcessor(
            agent=agent,
            buffer_size=buffer_size or self.batch_size
        )
        self.stream_processors.append(processor)
    
    def execute_stream(self, data_stream: Iterator) -> StreamingResult:
        """Execute workflow on streaming data"""
        result = StreamingResult(self.name)
        
        # Create processing pipeline
        pipeline = self._create_processing_pipeline(data_stream)
        
        # Process stream in batches
        batch_count = 0
        for batch_result in pipeline:
            result.add_batch_result(batch_count, batch_result)
            batch_count += 1
            
            # Emit intermediate results if configured
            if batch_count % 10 == 0:  # Every 10 batches
                intermediate_result = self.result_accumulator.get_intermediate_result()
                result.emit_intermediate(batch_count, intermediate_result)
        
        # Generate final result
        final_result = self.result_accumulator.get_final_result()
        result.set_final_result(final_result)
        
        return result
    
    def _create_processing_pipeline(self, data_stream: Iterator) -> Generator:
        """Create processing pipeline for streaming data"""
        
        # Convert data stream to batches
        batch_stream = self._batch_stream(data_stream, self.batch_size)
        
        # Apply each processor in sequence
        current_stream = batch_stream
        for processor in self.stream_processors:
            current_stream = processor.process_stream(current_stream)
        
        return current_stream
    
    def _batch_stream(self, data_stream: Iterator, batch_size: int) -> Generator:
        """Convert data stream to batches"""
        batch = []
        
        for item in data_stream:
            batch.append(item)
            
            if len(batch) >= batch_size:
                yield batch
                batch = []
        
        # Yield remaining items
        if batch:
            yield batch

class StreamProcessor:
    """Wrapper for agents to handle streaming data"""
    
    def __init__(self, agent: VELOCITY-XAgent, buffer_size: int = 100):
        self.agent = agent
        self.buffer_size = buffer_size
        self.input_buffer = []
        self.output_buffer = []
    
    def process_stream(self, input_stream: Iterator) -> Generator:
        """Process streaming data through the agent"""
        
        for batch in input_stream:
            # Add batch to buffer
            self.input_buffer.extend(batch)
            
            # Process when buffer is full
            while len(self.input_buffer) >= self.buffer_size:
                process_batch = self.input_buffer[:self.buffer_size]
                self.input_buffer = self.input_buffer[self.buffer_size:]
                
                # Process batch through agent
                batch_result = self.agent.execute({
                    "batch": process_batch,
                    "batch_size": len(process_batch)
                })
                
                self.output_buffer.append(batch_result)
                
                # Yield if output buffer is ready
                if len(self.output_buffer) >= 5:  # Yield every 5 processed batches
                    yield self.output_buffer
                    self.output_buffer = []
        
        # Process remaining items
        if self.input_buffer:
            final_result = self.agent.execute({
                "batch": self.input_buffer,
                "batch_size": len(self.input_buffer)
            })
            self.output_buffer.append(final_result)
        
        # Yield final output buffer
        if self.output_buffer:
            yield self.output_buffer

# Example: Large Dataset Processing
class LargeDatasetProcessingWorkflow(StreamingWorkflow):
    """Process large datasets incrementally"""
    
    def __init__(self):
        super().__init__("large-dataset-processing", batch_size=1000)
        
        # Add stream processors in order
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
        """Process large CSV file incrementally"""
        
        def csv_stream():
            import csv
            with open(file_path, 'r') as f:
                reader = csv.DictReader(f)
                for row in reader:
                    yield row
        
        return self.execute_stream(csv_stream())
```

## 5. Summary

Workflow design patterns provide powerful tools for creating sophisticated, reliable, and efficient agentic workflows. By understanding and applying these patterns appropriately, you can build systems that handle complex scenarios while maintaining performance and reliability.

### Key Pattern Categories

✅ **Fundamental Patterns**: Sequential, parallel, and conditional workflows for basic coordination

✅ **Advanced Coordination**: Scatter-gather and event-driven patterns for complex scenarios

✅ **Resilience Patterns**: Circuit breakers and compensating transactions for error handling

✅ **Performance Patterns**: Lazy evaluation and streaming for optimization

✅ **Domain-Specific Patterns**: Specialized patterns for common use cases

### Pattern Selection Guidelines

1. **Start Simple**: Begin with fundamental patterns and add complexity as needed
2. **Consider Scale**: Choose patterns that scale with your data and team size
3. **Plan for Failure**: Always include error handling and resilience patterns
4. **Optimize Judiciously**: Add performance patterns only when needed
5. **Document Decisions**: Record why specific patterns were chosen

## Exercises

1. **Pattern Analysis**: Analyze an existing workflow in your organization and identify which patterns could improve it

2. **Pattern Implementation**: Implement a conditional workflow that adapts based on input characteristics

3. **Error Handling**: Add circuit breaker and retry patterns to an existing agent

4. **Performance Optimization**: Design a streaming workflow for processing large datasets

5. **Custom Pattern**: Create a new workflow pattern for a specific challenge in your domain

## Further Reading

- [Enterprise Implementation](09-enterprise-implementation.md)
- [Team Collaboration Strategies](11-team-collaboration.md)
- [Troubleshooting Guide](12-troubleshooting.md)
- [Performance Optimization Cookbook](appendix-performance.md)

---

*Next Chapter: [Enterprise Implementation](09-enterprise-implementation.md) - Scale VELOCITY-X workflows across large organizations*