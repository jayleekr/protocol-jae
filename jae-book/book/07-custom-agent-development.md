---
title: Custom Agent Development
chapter: 7
author: JAE Team
date: 2025-07-27
reading_time: 25 minutes
---

# Custom Agent Development

> *"The true power of agentic workflows lies not in the agents you have, but in the agents you can create to solve your unique challenges."* - Martin Fowler (adapted)

## Overview

While JAE's built-in agents provide powerful capabilities, the real magic happens when you create custom agents tailored to your specific domain, tools, and workflow requirements. This chapter provides a comprehensive guide to developing, testing, and deploying custom agents that seamlessly integrate with the JAE ecosystem.

By the end of this chapter, you'll understand:
- The JAE agent architecture and development patterns
- How to design and implement custom agents from scratch
- Best practices for agent integration and interoperability
- Testing strategies for agent validation and reliability
- Deployment and maintenance patterns for production use

## 1. Agent Architecture Fundamentals

### JAE Agent Anatomy

Every JAE agent follows a consistent architectural pattern:

```python
# agent_base.py
from abc import ABC, abstractmethod
from typing import Dict, Any, List, Optional
from dataclasses import dataclass
from enum import Enum

class AgentCapability(Enum):
    """Standard agent capabilities"""
    ANALYSIS = "analysis"
    TRANSFORMATION = "transformation"
    VALIDATION = "validation"
    GENERATION = "generation"
    MONITORING = "monitoring"

@dataclass
class AgentMetadata:
    """Agent metadata and configuration"""
    name: str
    version: str
    description: str
    capabilities: List[AgentCapability]
    dependencies: List[str]
    tools_required: List[str]
    min_jae_version: str

class JAEAgent(ABC):
    """Base class for all JAE agents"""
    
    def __init__(self, config: Dict[str, Any]):
        self.config = config
        self.metadata = self._load_metadata()
        self.tools = self._initialize_tools()
        self.context = AgentContext()
        self.metrics = AgentMetrics()
    
    @abstractmethod
    def _load_metadata(self) -> AgentMetadata:
        """Load agent metadata"""
        pass
    
    @abstractmethod
    def execute(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """Main agent execution method"""
        pass
    
    @abstractmethod
    def validate_input(self, input_data: Any) -> bool:
        """Validate input data"""
        pass
    
    def _initialize_tools(self) -> Dict[str, Any]:
        """Initialize required tools"""
        tools = {}
        for tool_name in self.metadata.tools_required:
            tool = ToolFactory.create_tool(tool_name, self.config)
            tools[tool_name] = tool
        return tools
    
    def handoff_to(self, next_agent: str, data: Any, context: Dict = None) -> HandoffResult:
        """Hand off work to another agent"""
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
        """Log agent execution for monitoring and debugging"""
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

### Agent Communication Protocol

JAE agents communicate through a standardized protocol:

```python
# agent_communication.py
class AgentMessage:
    """Standard message format for agent communication"""
    
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
        """Add custom header to message"""
        self.headers[key] = value
    
    def serialize(self) -> Dict[str, Any]:
        """Serialize message for transmission"""
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
    """Central communication bus for agent interactions"""
    
    def __init__(self):
        self.subscribers = {}
        self.message_queue = Queue()
        self.message_history = MessageHistory()
    
    def register_agent(self, agent_name: str, agent_instance: JAEAgent):
        """Register agent with communication bus"""
        self.subscribers[agent_name] = agent_instance
    
    def send_message(self, message: AgentMessage):
        """Send message to target agent"""
        if message.receiver in self.subscribers:
            self.message_queue.put(message)
            self.message_history.record(message)
        else:
            raise AgentNotFoundError(f"Agent {message.receiver} not found")
    
    def broadcast_message(self, sender: str, message_type: str, payload: Any):
        """Broadcast message to all registered agents"""
        for agent_name in self.subscribers:
            if agent_name != sender:
                message = AgentMessage(sender, agent_name, message_type, payload)
                self.send_message(message)
```

## 2. Custom Agent Development Process

### Step 1: Agent Design and Planning

Before coding, carefully design your agent:

```python
# agent_design_template.py
"""
Agent Design Template

1. Agent Purpose and Scope
   - What specific problem does this agent solve?
   - What are the input/output requirements?
   - What domain expertise does it provide?

2. Capabilities Definition
   - What actions can this agent perform?
   - What tools and resources does it need?
   - How does it integrate with other agents?

3. Interface Design
   - What is the agent's public API?
   - What configuration options are needed?
   - How does it handle errors and edge cases?

4. Integration Points
   - Which agents will it collaborate with?
   - What handoff mechanisms are required?
   - How will it participate in workflows?
"""

class AgentDesignSpec:
    """Formal specification for agent design"""
    
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
        """Validate agent design for completeness and consistency"""
        issues = []
        
        if not self.purpose:
            issues.append("Agent purpose not defined")
        
        if not self.capabilities:
            issues.append("No capabilities defined")
        
        if not self.inputs or not self.outputs:
            issues.append("Input/output specifications missing")
        
        # Check for circular dependencies
        if self._has_circular_dependencies():
            issues.append("Circular dependencies detected")
        
        return DesignValidationResult(
            is_valid=len(issues) == 0,
            issues=issues
        )
```

### Step 2: Implementation Framework

Use JAE's agent framework for consistent implementation:

```python
# custom_agent_example.py
class APIContractValidatorAgent(JAEAgent):
    """
    Custom agent for validating API contracts and ensuring 
    backward compatibility in microservice architectures.
    """
    
    def _load_metadata(self) -> AgentMetadata:
        return AgentMetadata(
            name="api-contract-validator",
            version="1.0.0",
            description="Validates API contracts for backward compatibility",
            capabilities=[
                AgentCapability.ANALYSIS,
                AgentCapability.VALIDATION
            ],
            dependencies=["openapi-spec-validator", "json-schema"],
            tools_required=["Read", "Grep", "WebFetch"],
            min_jae_version="1.0.0"
        )
    
    def validate_input(self, input_data: Any) -> bool:
        """Validate that input contains required API specification data"""
        required_fields = ["current_spec", "previous_spec", "service_name"]
        
        if not isinstance(input_data, dict):
            return False
        
        return all(field in input_data for field in required_fields)
    
    def execute(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """Execute API contract validation"""
        if not self.validate_input(input_data):
            raise ValueError("Invalid input data for API contract validation")
        
        start_time = time.time()
        
        try:
            # Extract specifications
            current_spec = input_data["current_spec"]
            previous_spec = input_data["previous_spec"]
            service_name = input_data["service_name"]
            
            # Perform validation
            validation_result = self._validate_contract_compatibility(
                current_spec, previous_spec, service_name
            )
            
            # Generate report
            report = self._generate_validation_report(validation_result)
            
            # Log successful execution
            execution_time = time.time() - start_time
            self.log_execution(input_data, report, execution_time, True)
            
            return report
            
        except Exception as e:
            execution_time = time.time() - start_time
            self.log_execution(input_data, None, execution_time, False)
            raise AgentExecutionError(f"API contract validation failed: {str(e)}")
    
    def _validate_contract_compatibility(self, current_spec: Dict, 
                                       previous_spec: Dict, 
                                       service_name: str) -> ValidationResult:
        """Core validation logic for API compatibility"""
        validation_result = ValidationResult(service_name)
        
        # Check for breaking changes
        breaking_changes = self._detect_breaking_changes(current_spec, previous_spec)
        validation_result.add_breaking_changes(breaking_changes)
        
        # Check for deprecated features
        deprecations = self._detect_deprecations(current_spec, previous_spec)
        validation_result.add_deprecations(deprecations)
        
        # Validate schema evolution
        schema_issues = self._validate_schema_evolution(current_spec, previous_spec)
        validation_result.add_schema_issues(schema_issues)
        
        # Check API versioning compliance
        versioning_issues = self._validate_versioning_strategy(current_spec)
        validation_result.add_versioning_issues(versioning_issues)
        
        return validation_result
    
    def _detect_breaking_changes(self, current: Dict, previous: Dict) -> List[BreakingChange]:
        """Detect breaking changes between API versions"""
        breaking_changes = []
        
        # Check for removed endpoints
        current_paths = set(current.get("paths", {}).keys())
        previous_paths = set(previous.get("paths", {}).keys())
        removed_paths = previous_paths - current_paths
        
        for path in removed_paths:
            breaking_changes.append(BreakingChange(
                type="endpoint_removal",
                path=path,
                severity="critical",
                description=f"Endpoint {path} has been removed",
                recommendation="Deprecate instead of removing, or maintain compatibility"
            ))
        
        # Check for parameter changes
        for path in current_paths.intersection(previous_paths):
            path_changes = self._analyze_path_changes(
                current["paths"][path], 
                previous["paths"][path]
            )
            breaking_changes.extend(path_changes)
        
        return breaking_changes
    
    def _generate_validation_report(self, validation_result: ValidationResult) -> Dict[str, Any]:
        """Generate comprehensive validation report"""
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

### Step 3: Advanced Agent Features

Add sophisticated features to your custom agents:

```python
# advanced_agent_features.py
class AdvancedCustomAgent(JAEAgent):
    """Example of advanced agent features"""
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.ml_model = self._load_ml_model()
        self.cache = self._initialize_cache()
        self.learning_system = LearningSystem()
    
    def execute_with_learning(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """Execute with machine learning enhancement"""
        
        # Use ML to predict execution strategy
        execution_strategy = self.ml_model.predict_strategy(input_data)
        
        # Execute with predicted strategy
        result = self._execute_with_strategy(input_data, execution_strategy)
        
        # Learn from execution results
        self.learning_system.learn_from_execution(
            input_data, execution_strategy, result
        )
        
        return result
    
    def execute_with_caching(self, input_data: Any, context: Optional[Dict] = None) -> Any:
        """Execute with intelligent caching"""
        
        # Generate cache key
        cache_key = self._generate_cache_key(input_data, context)
        
        # Check cache
        cached_result = self.cache.get(cache_key)
        if cached_result and self._is_cache_valid(cached_result):
            self.metrics.record_cache_hit()
            return cached_result.data
        
        # Execute and cache result
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
        """Execute with automatic retry logic"""
        
        max_retries = self.config.get("max_retries", 3)
        retry_delay = self.config.get("retry_delay", 1.0)
        
        for attempt in range(max_retries + 1):
            try:
                return self.execute(input_data, context)
            
            except RetryableError as e:
                if attempt < max_retries:
                    self.metrics.record_retry(attempt + 1)
                    time.sleep(retry_delay * (2 ** attempt))  # Exponential backoff
                    continue
                else:
                    raise MaxRetriesExceededError(f"Failed after {max_retries} retries: {str(e)}")
            
            except NonRetryableError as e:
                raise e
    
    def _load_ml_model(self):
        """Load machine learning model for agent enhancement"""
        model_path = self.config.get("ml_model_path")
        if model_path:
            return MLModelLoader.load(model_path)
        return None
    
    def _initialize_cache(self):
        """Initialize caching system"""
        cache_config = self.config.get("cache", {})
        cache_type = cache_config.get("type", "memory")
        
        if cache_type == "redis":
            return RedisCache(cache_config)
        elif cache_type == "memory":
            return MemoryCache(cache_config)
        else:
            return NoOpCache()
```

## 3. Agent Integration Patterns

### Workflow Integration

Integrate custom agents into JAE workflows:

```python
# workflow_integration.py
class WorkflowIntegration:
    """Integration patterns for custom agents in workflows"""
    
    @staticmethod
    def create_sequential_workflow(agents: List[JAEAgent]) -> SequentialWorkflow:
        """Create a sequential workflow with custom agents"""
        workflow = SequentialWorkflow()
        
        for i, agent in enumerate(agents):
            if i == 0:
                # First agent receives raw input
                workflow.add_stage(WorkflowStage(
                    agent=agent,
                    input_source="workflow_input"
                ))
            else:
                # Subsequent agents receive output from previous agent
                workflow.add_stage(WorkflowStage(
                    agent=agent,
                    input_source=f"stage_{i-1}_output"
                ))
        
        return workflow
    
    @staticmethod
    def create_parallel_workflow(agents: List[JAEAgent], 
                               aggregator: AggregatorAgent) -> ParallelWorkflow:
        """Create a parallel workflow with result aggregation"""
        workflow = ParallelWorkflow()
        
        # Add parallel agents
        for agent in agents:
            workflow.add_parallel_stage(WorkflowStage(
                agent=agent,
                input_source="workflow_input"
            ))
        
        # Add aggregation stage
        workflow.add_aggregation_stage(WorkflowStage(
            agent=aggregator,
            input_source="parallel_outputs"
        ))
        
        return workflow
    
    @staticmethod
    def create_conditional_workflow(condition_agent: JAEAgent, 
                                  branch_agents: Dict[str, JAEAgent]) -> ConditionalWorkflow:
        """Create a conditional workflow with branching logic"""
        workflow = ConditionalWorkflow()
        
        # Add condition evaluation stage
        workflow.add_condition_stage(WorkflowStage(
            agent=condition_agent,
            input_source="workflow_input"
        ))
        
        # Add conditional branches
        for condition, agent in branch_agents.items():
            workflow.add_branch(condition, WorkflowStage(
                agent=agent,
                input_source="workflow_input"
            ))
        
        return workflow

# Example: API validation workflow
class APIValidationWorkflow:
    """Custom workflow for API validation process"""
    
    def __init__(self):
        self.contract_validator = APIContractValidatorAgent({})
        self.security_analyzer = SecurityAnalyzerAgent({})
        self.performance_tester = PerformanceTesterAgent({})
        self.report_generator = ReportGeneratorAgent({})
    
    def create_workflow(self) -> SequentialWorkflow:
        """Create comprehensive API validation workflow"""
        
        # Create sequential workflow
        workflow = WorkflowIntegration.create_sequential_workflow([
            self.contract_validator,
            self.security_analyzer,
            self.performance_tester,
            self.report_generator
        ])
        
        # Add workflow-level configuration
        workflow.configure({
            "fail_fast": True,  # Stop on first critical issue
            "parallel_security_and_performance": True,  # Run these in parallel
            "generate_detailed_reports": True
        })
        
        return workflow
```

### Event-Driven Integration

Create event-driven integrations for reactive agents:

```python
# event_driven_integration.py
class EventDrivenAgent(JAEAgent):
    """Base class for event-driven agents"""
    
    def __init__(self, config: Dict[str, Any]):
        super().__init__(config)
        self.event_handlers = {}
        self.event_bus = EventBus()
        self._register_event_handlers()
    
    def _register_event_handlers(self):
        """Register event handlers for this agent"""
        pass  # Override in subclasses
    
    def register_event_handler(self, event_type: str, handler: callable):
        """Register handler for specific event type"""
        if event_type not in self.event_handlers:
            self.event_handlers[event_type] = []
        self.event_handlers[event_type].append(handler)
    
    def handle_event(self, event: Event):
        """Handle incoming event"""
        event_type = event.type
        
        if event_type in self.event_handlers:
            for handler in self.event_handlers[event_type]:
                try:
                    handler(event)
                except Exception as e:
                    self.log_error(f"Error handling event {event_type}: {str(e)}")

class CodeChangeMonitorAgent(EventDrivenAgent):
    """Agent that monitors code changes and triggers analysis"""
    
    def _register_event_handlers(self):
        """Register handlers for code change events"""
        self.register_event_handler("file_changed", self._handle_file_change)
        self.register_event_handler("pull_request_opened", self._handle_pr_opened)
        self.register_event_handler("commit_pushed", self._handle_commit_pushed)
    
    def _handle_file_change(self, event: Event):
        """Handle file change events"""
        file_path = event.data["file_path"]
        change_type = event.data["change_type"]
        
        # Determine if this change requires immediate analysis
        if self._requires_immediate_analysis(file_path, change_type):
            # Trigger quality trio workflow
            self._trigger_quality_analysis(event.data)
    
    def _handle_pr_opened(self, event: Event):
        """Handle pull request opened events"""
        pr_data = event.data
        
        # Schedule comprehensive review
        self._schedule_comprehensive_review(pr_data)
    
    def _trigger_quality_analysis(self, change_data: Dict):
        """Trigger quality analysis workflow"""
        analysis_event = Event(
            type="quality_analysis_requested",
            data=change_data,
            source=self.metadata.name
        )
        
        self.event_bus.publish(analysis_event)
```

## 4. Testing Custom Agents

### Unit Testing Framework

Comprehensive testing framework for custom agents:

```python
# agent_testing_framework.py
import unittest
from unittest.mock import Mock, patch
import pytest

class AgentTestCase(unittest.TestCase):
    """Base test case for agent testing"""
    
    def setUp(self):
        """Set up test environment"""
        self.agent_config = self._get_test_config()
        self.agent = self._create_agent_instance()
        self.mock_tools = self._setup_mock_tools()
    
    def _get_test_config(self) -> Dict[str, Any]:
        """Get test configuration for agent"""
        return {
            "test_mode": True,
            "cache_enabled": False,
            "ml_model_path": None  # Disable ML in tests
        }
    
    def _create_agent_instance(self):
        """Create agent instance for testing"""
        raise NotImplementedError("Subclasses must implement this method")
    
    def _setup_mock_tools(self) -> Dict[str, Mock]:
        """Set up mock tools for testing"""
        mock_tools = {}
        for tool_name in self.agent.metadata.tools_required:
            mock_tools[tool_name] = Mock()
        return mock_tools
    
    def test_agent_metadata(self):
        """Test agent metadata is properly configured"""
        metadata = self.agent.metadata
        
        self.assertIsInstance(metadata.name, str)
        self.assertIsInstance(metadata.version, str)
        self.assertIsInstance(metadata.description, str)
        self.assertTrue(len(metadata.capabilities) > 0)
    
    def test_input_validation(self):
        """Test input validation logic"""
        # Test valid input
        valid_input = self._get_valid_test_input()
        self.assertTrue(self.agent.validate_input(valid_input))
        
        # Test invalid input
        invalid_inputs = self._get_invalid_test_inputs()
        for invalid_input in invalid_inputs:
            self.assertFalse(self.agent.validate_input(invalid_input))
    
    def test_successful_execution(self):
        """Test successful agent execution"""
        input_data = self._get_valid_test_input()
        
        with patch.object(self.agent, 'tools', self.mock_tools):
            result = self.agent.execute(input_data)
        
        self.assertIsNotNone(result)
        self._validate_output_format(result)
    
    def test_error_handling(self):
        """Test agent error handling"""
        # Test with invalid input
        with self.assertRaises(ValueError):
            self.agent.execute(self._get_invalid_test_inputs()[0])
        
        # Test with tool failure
        self.mock_tools["Read"].side_effect = Exception("Tool failure")
        
        with patch.object(self.agent, 'tools', self.mock_tools):
            with self.assertRaises(AgentExecutionError):
                self.agent.execute(self._get_valid_test_input())

class APIContractValidatorAgentTest(AgentTestCase):
    """Test cases for API Contract Validator Agent"""
    
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
            {},  # Empty input
            {"current_spec": {}},  # Missing fields
            "invalid_type",  # Wrong type
        ]
    
    def _validate_output_format(self, result):
        """Validate the output format of API validation"""
        self.assertIn("service_name", result)
        self.assertIn("compatibility_status", result)
        self.assertIn("breaking_changes", result)
        self.assertIn("recommendations", result)
    
    def test_breaking_change_detection(self):
        """Test detection of breaking changes"""
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
        
        # Should detect removal of /admin endpoint
        self.assertTrue(len(result["breaking_changes"]) > 0)
```

### Integration Testing

Test agent integration with other components:

```python
# integration_testing.py
class AgentIntegrationTest(unittest.TestCase):
    """Integration tests for agent workflows"""
    
    def setUp(self):
        """Set up integration test environment"""
        self.test_environment = TestEnvironment()
        self.agent_registry = AgentRegistry()
        self.workflow_engine = WorkflowEngine()
    
    def test_agent_handoff(self):
        """Test agent-to-agent handoff"""
        # Set up agents
        source_agent = APIContractValidatorAgent({})
        target_agent = SecurityAnalyzerAgent({})
        
        # Register agents
        self.agent_registry.register(source_agent)
        self.agent_registry.register(target_agent)
        
        # Test handoff
        test_data = {"validation_result": "sample_data"}
        handoff_result = source_agent.handoff_to(
            target_agent.metadata.name, 
            test_data
        )
        
        self.assertTrue(handoff_result.success)
        self.assertEqual(handoff_result.target_agent, target_agent.metadata.name)
    
    def test_workflow_execution(self):
        """Test complete workflow execution"""
        # Create test workflow
        workflow = APIValidationWorkflow().create_workflow()
        
        # Execute workflow with test data
        test_input = self._get_workflow_test_input()
        result = self.workflow_engine.execute(workflow, test_input)
        
        # Validate workflow completion
        self.assertTrue(result.success)
        self.assertIsNotNone(result.final_output)
    
    def test_event_driven_integration(self):
        """Test event-driven agent integration"""
        # Set up event-driven agents
        monitor_agent = CodeChangeMonitorAgent({})
        analysis_agent = QualityAnalysisAgent({})
        
        # Set up event bus
        event_bus = EventBus()
        event_bus.register_agent(monitor_agent)
        event_bus.register_agent(analysis_agent)
        
        # Trigger test event
        test_event = Event(
            type="file_changed",
            data={"file_path": "test.py", "change_type": "modified"}
        )
        
        event_bus.publish(test_event)
        
        # Verify event handling
        # (This would require more sophisticated event tracking in a real implementation)
```

### Performance Testing

Test agent performance and scalability:

```python
# performance_testing.py
import time
import concurrent.futures
from typing import List

class AgentPerformanceTest:
    """Performance testing framework for agents"""
    
    def __init__(self, agent_class, config: Dict[str, Any]):
        self.agent_class = agent_class
        self.config = config
    
    def test_execution_time(self, test_inputs: List[Any], 
                          expected_max_time: float) -> PerformanceResult:
        """Test agent execution time"""
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
        """Test agent memory usage"""
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
        """Test agent performance under concurrent load"""
        
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

## 5. Deployment and Production Considerations

### Deployment Strategies

Deploy custom agents safely and efficiently:

```python
# deployment_strategies.py
class AgentDeploymentManager:
    """Manages deployment of custom agents"""
    
    def __init__(self, environment: str):
        self.environment = environment
        self.deployment_config = self._load_deployment_config()
        self.health_checker = AgentHealthChecker()
        self.rollback_manager = RollbackManager()
    
    def deploy_agent(self, agent_package: AgentPackage) -> DeploymentResult:
        """Deploy agent with safety checks"""
        
        # Validate agent package
        validation_result = self._validate_agent_package(agent_package)
        if not validation_result.is_valid:
            return DeploymentResult(
                success=False,
                errors=validation_result.errors
            )
        
        # Create deployment plan
        deployment_plan = self._create_deployment_plan(agent_package)
        
        try:
            # Execute deployment
            return self._execute_deployment(deployment_plan)
        
        except DeploymentError as e:
            # Automatic rollback on failure
            self.rollback_manager.rollback_deployment(deployment_plan)
            raise e
    
    def blue_green_deploy(self, agent_package: AgentPackage) -> DeploymentResult:
        """Deploy using blue-green strategy"""
        
        # Deploy to green environment
        green_deployment = self._deploy_to_environment(agent_package, "green")
        
        if green_deployment.success:
            # Run health checks on green
            health_check = self.health_checker.check_agent_health(
                agent_package.metadata.name, "green"
            )
            
            if health_check.is_healthy:
                # Switch traffic to green
                self._switch_traffic("green")
                
                # Mark blue as standby
                self._mark_environment_standby("blue")
                
                return DeploymentResult(success=True)
            else:
                # Rollback green deployment
                self._destroy_environment("green")
                return DeploymentResult(
                    success=False,
                    errors=["Health check failed on green environment"]
                )
        
        return green_deployment
    
    def canary_deploy(self, agent_package: AgentPackage, 
                     traffic_percentage: int = 10) -> DeploymentResult:
        """Deploy using canary strategy"""
        
        # Deploy canary version
        canary_deployment = self._deploy_canary(agent_package)
        
        if canary_deployment.success:
            # Route small percentage of traffic to canary
            self._route_traffic_to_canary(traffic_percentage)
            
            # Monitor canary performance
            canary_metrics = self._monitor_canary_metrics(duration_minutes=30)
            
            if canary_metrics.are_acceptable():
                # Gradually increase traffic
                self._gradual_traffic_increase(agent_package)
                return DeploymentResult(success=True)
            else:
                # Rollback canary
                self._rollback_canary()
                return DeploymentResult(
                    success=False,
                    errors=["Canary metrics unacceptable"]
                )
        
        return canary_deployment
```

### Monitoring and Observability

Implement comprehensive monitoring for production agents:

```python
# agent_monitoring.py
class AgentMonitoringSystem:
    """Comprehensive monitoring system for production agents"""
    
    def __init__(self):
        self.metrics_collector = MetricsCollector()
        self.log_aggregator = LogAggregator()
        self.alert_manager = AlertManager()
        self.dashboard = MonitoringDashboard()
    
    def setup_agent_monitoring(self, agent: JAEAgent) -> MonitoringSetup:
        """Set up monitoring for an agent"""
        
        setup = MonitoringSetup(agent.metadata.name)
        
        # Set up metrics collection
        setup.add_metric("execution_time", MetricType.HISTOGRAM)
        setup.add_metric("success_rate", MetricType.GAUGE)
        setup.add_metric("error_rate", MetricType.COUNTER)
        setup.add_metric("memory_usage", MetricType.GAUGE)
        setup.add_metric("cache_hit_rate", MetricType.GAUGE)
        
        # Set up log aggregation
        setup.configure_logging(
            log_level="INFO",
            structured_logging=True,
            correlation_tracking=True
        )
        
        # Set up alerts
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
    
    def create_monitoring_dashboard(self, agents: List[JAEAgent]) -> Dashboard:
        """Create monitoring dashboard for agents"""
        
        dashboard = Dashboard("JAE Agents Monitoring")
        
        # Overview panel
        overview_panel = Panel("Overview")
        overview_panel.add_widget(MetricWidget(
            title="Active Agents",
            metric="active_agents_count",
            visualization="single_stat"
        ))
        overview_panel.add_widget(MetricWidget(
            title="Total Executions",
            metric="total_executions",
            visualization="single_stat"
        ))
        dashboard.add_panel(overview_panel)
        
        # Performance panel
        performance_panel = Panel("Performance")
        performance_panel.add_widget(MetricWidget(
            title="Execution Times",
            metric="execution_time",
            visualization="time_series",
            aggregation="percentile(95)"
        ))
        performance_panel.add_widget(MetricWidget(
            title="Success Rate",
            metric="success_rate",
            visualization="gauge"
        ))
        dashboard.add_panel(performance_panel)
        
        # Agent-specific panels
        for agent in agents:
            agent_panel = Panel(f"Agent: {agent.metadata.name}")
            
            agent_panel.add_widget(MetricWidget(
                title="Executions",
                metric=f"{agent.metadata.name}.executions",
                visualization="time_series"
            ))
            
            agent_panel.add_widget(MetricWidget(
                title="Error Rate",
                metric=f"{agent.metadata.name}.error_rate",
                visualization="time_series"
            ))
            
            dashboard.add_panel(agent_panel)
        
        return dashboard
```

### Maintenance and Updates

Establish maintenance procedures for production agents:

```python
# agent_maintenance.py
class AgentMaintenanceManager:
    """Manages maintenance and updates for production agents"""
    
    def __init__(self):
        self.version_manager = VersionManager()
        self.backup_manager = BackupManager()
        self.health_checker = HealthChecker()
        self.scheduler = MaintenanceScheduler()
    
    def schedule_maintenance(self, agent_name: str, 
                           maintenance_type: str, 
                           schedule: str) -> MaintenanceJob:
        """Schedule regular maintenance for an agent"""
        
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
        """Update agent to new version"""
        
        # Create backup before update
        backup_result = self.backup_manager.create_backup(agent_name)
        if not backup_result.success:
            return UpdateResult(
                success=False,
                error="Failed to create backup before update"
            )
        
        try:
            if update_strategy == "rolling":
                return self._rolling_update(agent_name, new_version)
            elif update_strategy == "blue_green":
                return self._blue_green_update(agent_name, new_version)
            elif update_strategy == "immediate":
                return self._immediate_update(agent_name, new_version)
        
        except UpdateError as e:
            # Restore from backup on failure
            self.backup_manager.restore_backup(agent_name, backup_result.backup_id)
            return UpdateResult(
                success=False,
                error=f"Update failed: {str(e)}. Restored from backup."
            )
    
    def _rolling_update(self, agent_name: str, new_version: str) -> UpdateResult:
        """Perform rolling update of agent instances"""
        
        agent_instances = self._get_agent_instances(agent_name)
        
        for instance in agent_instances:
            # Update one instance at a time
            update_result = self._update_single_instance(instance, new_version)
            
            if not update_result.success:
                return UpdateResult(
                    success=False,
                    error=f"Failed to update instance {instance.id}"
                )
            
            # Wait for instance to be healthy before continuing
            health_check = self.health_checker.wait_for_healthy(
                instance, timeout_seconds=300
            )
            
            if not health_check.is_healthy:
                return UpdateResult(
                    success=False,
                    error=f"Instance {instance.id} failed health check after update"
                )
        
        return UpdateResult(success=True)
```

## 6. Summary

Custom agent development is a powerful capability that allows you to extend JAE's functionality to meet your specific requirements. Through careful design, robust implementation, comprehensive testing, and proper deployment practices, you can create agents that seamlessly integrate with the JAE ecosystem.

### Key Takeaways

✅ **Structured Development**: Follow JAE's agent architecture patterns for consistency and interoperability

✅ **Comprehensive Testing**: Implement unit, integration, and performance tests for reliability

✅ **Safe Deployment**: Use deployment strategies like blue-green and canary for safe production releases

✅ **Production Monitoring**: Implement comprehensive monitoring and alerting for production agents

✅ **Maintenance Planning**: Establish regular maintenance procedures for long-term reliability

### Development Checklist

- [ ] Design agent architecture and define capabilities
- [ ] Implement core agent functionality following JAE patterns
- [ ] Add advanced features (caching, retry logic, ML enhancement)
- [ ] Create comprehensive test suite
- [ ] Set up CI/CD pipeline for agent deployment
- [ ] Implement monitoring and alerting
- [ ] Document agent API and usage patterns
- [ ] Plan maintenance and update procedures

## Exercises

1. **Agent Design**: Design a custom agent for a specific need in your domain (e.g., database migration validator, infrastructure compliance checker)

2. **Implementation**: Implement a basic version of your designed agent following JAE patterns

3. **Testing**: Create a comprehensive test suite for your agent including unit, integration, and performance tests

4. **Integration**: Integrate your agent with existing JAE workflows

5. **Deployment**: Set up a deployment pipeline for your agent with proper monitoring

## Further Reading

- [Workflow Design Patterns](08-workflow-design.md)
- [Enterprise Implementation](09-enterprise-implementation.md)
- [Team Collaboration Strategies](11-team-collaboration.md)
- [JAE Agent API Reference](appendix-api-reference.md)

---

*Next Chapter: [Workflow Design Patterns](08-workflow-design.md) - Learn advanced patterns for designing sophisticated agent workflows*