#!/usr/bin/env python3
"""
VELOCITY-X Workflow Engine
워크플로우 자동 호출 및 에이전트 간 조율을 담당하는 핵심 엔진
"""

import json
import subprocess
import sys
import time
import yaml
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Tuple, Any
import logging
import os
import threading
from dataclasses import dataclass, asdict
from enum import Enum

# 로깅 설정
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger('velocity_x.workflow_engine')

class AgentStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    SUCCESS = "success"
    FAILED = "failed"
    SKIPPED = "skipped"
    BLOCKED = "blocked"

@dataclass
class AgentConfig:
    name: str
    phase: int
    order: int
    role: str
    command: str
    timeout: int
    enabled: bool
    required_tools: List[str]
    input_types: List[str]
    output_types: List[str]
    dependencies: List[str]
    parallel_with: Optional[List[str]] = None
    blocking_conditions: Optional[List[str]] = None
    conditions: Optional[Dict[str, Any]] = None
    quality_gates: Optional[Dict[str, Any]] = None

@dataclass
class AgentResult:
    agent_name: str
    status: AgentStatus
    start_time: datetime
    end_time: Optional[datetime]
    output_dir: Optional[str]
    error_message: Optional[str]
    metadata: Optional[Dict[str, Any]]

class WorkflowEngine:
    """VELOCITY-X 워크플로우 엔진 - 에이전트들의 자동 호출 및 조율"""
    
    def __init__(self, config_dir: Optional[str] = None):
        self.config_dir = Path(config_dir or os.getenv('VELOCITY-X_CONFIG_DIR', './config'))
        self.commands_dir = Path(os.getenv('VELOCITY-X_COMMANDS_DIR', '.'))
        self.output_dir = Path(os.getenv('VELOCITY-X_OUTPUT_DIR', './velocity-x-output'))
        self.temp_dir = Path(os.getenv('VELOCITY-X_TEMP_DIR', '/tmp/velocity-x-workflow'))
        
        # 설정 로드
        self.agents_config = self._load_agents_config()
        self.tools_config = self._load_tools_config()
        
        # 실행 상태 관리
        self.agent_results: Dict[str, AgentResult] = {}
        self.workflow_id = datetime.now().strftime('%Y%m%d_%H%M%S')
        self.workflow_start_time = datetime.now()
        
        # 디렉토리 생성
        self.output_dir.mkdir(parents=True, exist_ok=True)
        self.temp_dir.mkdir(parents=True, exist_ok=True)
        
        logger.info(f"Workflow engine initialized with ID: {self.workflow_id}")
    
    def _load_agents_config(self) -> Dict[str, AgentConfig]:
        """에이전트 설정 로드"""
        config_file = self.config_dir / 'agents.yaml'
        
        if not config_file.exists():
            raise FileNotFoundError(f"Agents config not found: {config_file}")
        
        with open(config_file) as f:
            config_data = yaml.safe_load(f)
        
        agents = {}
        for name, agent_data in config_data.get('agents', {}).items():
            agents[name] = AgentConfig(
                name=name,
                phase=agent_data.get('phase', 1),
                order=agent_data.get('order', 999),
                role=agent_data.get('role', ''),
                command=agent_data.get('command', ''),
                timeout=agent_data.get('timeout', 300),
                enabled=agent_data.get('enabled', True),
                required_tools=agent_data.get('required_tools', []),
                input_types=agent_data.get('input_types', []),
                output_types=agent_data.get('output_types', []),
                dependencies=agent_data.get('dependencies', []),
                parallel_with=agent_data.get('parallel_with'),
                blocking_conditions=agent_data.get('blocking_conditions'),
                conditions=agent_data.get('conditions'),
                quality_gates=agent_data.get('quality_gates')
            )
        
        logger.info(f"Loaded {len(agents)} agent configurations")
        return agents
    
    def _load_tools_config(self) -> Dict[str, Any]:
        """도구 설정 로드"""
        config_file = self.config_dir / 'tools.yaml'
        
        if not config_file.exists():
            logger.warning(f"Tools config not found: {config_file}")
            return {}
        
        with open(config_file) as f:
            return yaml.safe_load(f)
    
    def _save_workflow_state(self):
        """워크플로우 상태 저장"""
        state_file = self.temp_dir / f'workflow_state_{self.workflow_id}.json'
        
        state = {
            'workflow_id': self.workflow_id,
            'start_time': self.workflow_start_time.isoformat(),
            'agent_results': {
                name: {
                    'agent_name': result.agent_name,
                    'status': result.status.value,
                    'start_time': result.start_time.isoformat(),
                    'end_time': result.end_time.isoformat() if result.end_time else None,
                    'output_dir': str(result.output_dir) if result.output_dir else None,
                    'error_message': result.error_message,
                    'metadata': result.metadata
                }
                for name, result in self.agent_results.items()
            }
        }
        
        with open(state_file, 'w') as f:
            json.dump(state, f, indent=2)
        
        logger.debug(f"Workflow state saved: {state_file}")
    
    def _check_dependencies(self, agent_name: str) -> bool:
        """에이전트 의존성 확인"""
        agent_config = self.agents_config[agent_name]
        
        for dep_agent in agent_config.dependencies:
            if dep_agent not in self.agent_results:
                logger.debug(f"Dependency not met: {agent_name} requires {dep_agent}")
                return False
            
            dep_result = self.agent_results[dep_agent]
            if dep_result.status != AgentStatus.SUCCESS:
                logger.warning(f"Dependency failed: {dep_agent} status is {dep_result.status.value}")
                return False
        
        return True
    
    def _check_conditions(self, agent_name: str) -> bool:
        """에이전트 실행 조건 확인"""
        agent_config = self.agents_config[agent_name]
        
        if not agent_config.conditions:
            return True
        
        # 예: frontend_code_present 조건 확인
        if 'frontend_code_present' in agent_config.conditions:
            required = agent_config.conditions['frontend_code_present']
            # 실제 구현에서는 파일 시스템을 스캔하여 확인
            # 여기서는 간단히 True로 가정
            actual = True
            if required != actual:
                logger.info(f"Condition not met for {agent_name}: frontend_code_present={actual}, required={required}")
                return False
        
        return True
    
    def _check_blocking_conditions(self, agent_name: str) -> bool:
        """차단 조건 확인 (보안 취약점 등)"""
        agent_config = self.agents_config[agent_name]
        
        if not agent_config.blocking_conditions:
            return False  # 차단 없음
        
        # 이전 에이전트 결과에서 차단 조건 확인
        for dep_agent in agent_config.dependencies:
            if dep_agent in self.agent_results:
                dep_result = self.agent_results[dep_agent]
                if dep_result.metadata:
                    # 보안 에이전트에서 high_severity_vulnerabilities 확인
                    if 'high_severity_vulnerabilities' in agent_config.blocking_conditions:
                        vulnerabilities = dep_result.metadata.get('security_issues', [])
                        high_severity = [v for v in vulnerabilities if v.get('severity') == 'high']
                        if high_severity:
                            logger.error(f"Blocking condition met: {len(high_severity)} high severity vulnerabilities found")
                            return True  # 차단
        
        return False  # 차단 없음
    
    def _run_agent(self, agent_name: str, input_files: List[str]) -> AgentResult:
        """단일 에이전트 실행"""
        agent_config = self.agents_config[agent_name]
        start_time = datetime.now()
        
        logger.info(f"Starting agent: {agent_name}")
        
        # 에이전트 스크립트 경로
        script_path = self.commands_dir / agent_config.command
        
        if not script_path.exists():
            error_msg = f"Agent script not found: {script_path}"
            logger.error(error_msg)
            return AgentResult(
                agent_name=agent_name,
                status=AgentStatus.FAILED,
                start_time=start_time,
                end_time=datetime.now(),
                output_dir=None,
                error_message=error_msg,
                metadata=None
            )
        
        # 명령어 구성
        cmd = [str(script_path)]
        if input_files:
            cmd.extend(input_files)
        
        # 환경 변수 설정
        env = os.environ.copy()
        env.update({
            'VELOCITY-X_WORKFLOW_ID': self.workflow_id,
            'VELOCITY-X_AGENT_NAME': agent_name,
            'VELOCITY-X_OUTPUT_DIR': str(self.output_dir),
            'VELOCITY-X_TEMP_DIR': str(self.temp_dir)
        })
        
        try:
            # 에이전트 실행
            logger.debug(f"Executing: {' '.join(cmd)}")
            result = subprocess.run(
                cmd,
                timeout=agent_config.timeout,
                capture_output=True,
                text=True,
                env=env
            )
            
            end_time = datetime.now()
            
            if result.returncode == 0:
                logger.info(f"Agent {agent_name} completed successfully")
                
                # 출력 디렉토리 찾기
                output_pattern = self.output_dir / f"{agent_name}_*"
                output_dirs = list(self.output_dir.glob(f"{agent_name}_*"))
                output_dir = str(output_dirs[-1]) if output_dirs else None
                
                # 메타데이터 로드
                metadata = None
                if output_dir:
                    metadata_file = Path(output_dir) / 'summary.json'
                    if metadata_file.exists():
                        with open(metadata_file) as f:
                            metadata = json.load(f)
                
                return AgentResult(
                    agent_name=agent_name,
                    status=AgentStatus.SUCCESS,
                    start_time=start_time,
                    end_time=end_time,
                    output_dir=output_dir,
                    error_message=None,
                    metadata=metadata
                )
            else:
                error_msg = f"Agent failed with exit code {result.returncode}: {result.stderr}"
                logger.error(error_msg)
                return AgentResult(
                    agent_name=agent_name,
                    status=AgentStatus.FAILED,
                    start_time=start_time,
                    end_time=end_time,
                    output_dir=None,
                    error_message=error_msg,
                    metadata=None
                )
        
        except subprocess.TimeoutExpired:
            error_msg = f"Agent {agent_name} timed out after {agent_config.timeout} seconds"
            logger.error(error_msg)
            return AgentResult(
                agent_name=agent_name,
                status=AgentStatus.FAILED,
                start_time=start_time,
                end_time=datetime.now(),
                output_dir=None,
                error_message=error_msg,
                metadata=None
            )
        
        except Exception as e:
            error_msg = f"Unexpected error running {agent_name}: {str(e)}"
            logger.error(error_msg)
            return AgentResult(
                agent_name=agent_name,
                status=AgentStatus.FAILED,
                start_time=start_time,
                end_time=datetime.now(),
                output_dir=None,
                error_message=error_msg,
                metadata=None
            )
    
    def _get_ready_agents(self, agent_names: List[str]) -> List[str]:
        """실행 준비된 에이전트 목록 반환"""
        ready = []
        
        for agent_name in agent_names:
            if agent_name in self.agent_results:
                continue  # 이미 실행됨
            
            if not self.agents_config[agent_name].enabled:
                logger.info(f"Agent {agent_name} is disabled, skipping")
                self.agent_results[agent_name] = AgentResult(
                    agent_name=agent_name,
                    status=AgentStatus.SKIPPED,
                    start_time=datetime.now(),
                    end_time=datetime.now(),
                    output_dir=None,
                    error_message="Agent disabled",
                    metadata=None
                )
                continue
            
            # 의존성 확인
            if not self._check_dependencies(agent_name):
                continue
            
            # 실행 조건 확인
            if not self._check_conditions(agent_name):
                logger.info(f"Agent {agent_name} conditions not met, skipping")
                self.agent_results[agent_name] = AgentResult(
                    agent_name=agent_name,
                    status=AgentStatus.SKIPPED,
                    start_time=datetime.now(),
                    end_time=datetime.now(),
                    output_dir=None,
                    error_message="Conditions not met",
                    metadata=None
                )
                continue
            
            # 차단 조건 확인
            if self._check_blocking_conditions(agent_name):
                logger.warning(f"Agent {agent_name} blocked by conditions")
                self.agent_results[agent_name] = AgentResult(
                    agent_name=agent_name,
                    status=AgentStatus.BLOCKED,
                    start_time=datetime.now(),
                    end_time=datetime.now(),
                    output_dir=None,
                    error_message="Blocked by conditions",
                    metadata=None
                )
                continue
            
            ready.append(agent_name)
        
        return ready
    
    def run_workflow(self, workflow_name: str, input_files: List[str] = None) -> Dict[str, Any]:
        """워크플로우 실행"""
        logger.info(f"Starting workflow: {workflow_name}")
        
        # 워크플로우 정의 로드
        config_file = self.config_dir / 'agents.yaml'
        with open(config_file) as f:
            config_data = yaml.safe_load(f)
        
        workflows = config_data.get('workflows', {})
        if workflow_name not in workflows:
            raise ValueError(f"Workflow not found: {workflow_name}")
        
        workflow_config = workflows[workflow_name]
        agent_names = workflow_config['agents']
        
        # 에이전트를 phase와 order로 정렬
        sorted_agents = sorted(
            agent_names,
            key=lambda name: (
                self.agents_config[name].phase,
                self.agents_config[name].order
            )
        )
        
        logger.info(f"Workflow {workflow_name} will execute agents: {sorted_agents}")
        
        # 워크플로우 실행
        input_files = input_files or []
        max_iterations = 50  # 무한 루프 방지
        iteration = 0
        
        while iteration < max_iterations:
            iteration += 1
            ready_agents = self._get_ready_agents(sorted_agents)
            
            if not ready_agents:
                # 모든 에이전트가 완료되었거나 더 이상 실행할 수 없음
                break
            
            logger.info(f"Iteration {iteration}: Ready agents: {ready_agents}")
            
            # 병렬 실행 가능한 에이전트 그룹핑
            parallel_groups = self._group_parallel_agents(ready_agents)
            
            for group in parallel_groups:
                if len(group) == 1:
                    # 순차 실행
                    agent_name = group[0]
                    result = self._run_agent(agent_name, input_files)
                    self.agent_results[agent_name] = result
                    
                    # 실패 시 워크플로우 중단 여부 결정
                    if result.status == AgentStatus.FAILED:
                        logger.error(f"Agent {agent_name} failed, checking if workflow should continue")
                        # 중요한 에이전트 실패 시 중단
                        if agent_name in ['velocity-x-security-guardian']:
                            logger.error("Critical agent failed, stopping workflow")
                            break
                else:
                    # 병렬 실행
                    logger.info(f"Running agents in parallel: {group}")
                    threads = []
                    results = {}
                    
                    def run_agent_thread(agent_name):
                        results[agent_name] = self._run_agent(agent_name, input_files)
                    
                    for agent_name in group:
                        thread = threading.Thread(target=run_agent_thread, args=(agent_name,))
                        threads.append(thread)
                        thread.start()
                    
                    # 모든 스레드 완료 대기
                    for thread in threads:
                        thread.join()
                    
                    # 결과 저장
                    for agent_name, result in results.items():
                        self.agent_results[agent_name] = result
            
            # 상태 저장
            self._save_workflow_state()
            
            # 진행률 표시
            completed = len([r for r in self.agent_results.values() 
                           if r.status in [AgentStatus.SUCCESS, AgentStatus.FAILED, AgentStatus.SKIPPED, AgentStatus.BLOCKED]])
            total = len(sorted_agents)
            logger.info(f"Progress: {completed}/{total} agents completed")
        
        # 최종 결과 정리
        end_time = datetime.now()
        duration = end_time - self.workflow_start_time
        
        # 성공/실패 통계
        success_count = len([r for r in self.agent_results.values() if r.status == AgentStatus.SUCCESS])
        failed_count = len([r for r in self.agent_results.values() if r.status == AgentStatus.FAILED])
        skipped_count = len([r for r in self.agent_results.values() if r.status == AgentStatus.SKIPPED])
        blocked_count = len([r for r in self.agent_results.values() if r.status == AgentStatus.BLOCKED])
        
        overall_status = "success" if failed_count == 0 and blocked_count == 0 else "failed"
        
        summary = {
            'workflow_id': self.workflow_id,
            'workflow_name': workflow_name,
            'status': overall_status,
            'start_time': self.workflow_start_time.isoformat(),
            'end_time': end_time.isoformat(),
            'duration_seconds': duration.total_seconds(),
            'statistics': {
                'total_agents': len(sorted_agents),
                'success': success_count,
                'failed': failed_count,
                'skipped': skipped_count,
                'blocked': blocked_count
            },
            'agent_results': {name: asdict(result) for name, result in self.agent_results.items()}
        }
        
        # 최종 보고서 저장
        report_file = self.output_dir / f'workflow_report_{self.workflow_id}.json'
        with open(report_file, 'w') as f:
            json.dump(summary, f, indent=2, default=str)
        
        logger.info(f"Workflow {workflow_name} completed with status: {overall_status}")
        logger.info(f"Final report saved: {report_file}")
        
        return summary
    
    def _group_parallel_agents(self, ready_agents: List[str]) -> List[List[str]]:
        """병렬 실행 가능한 에이전트들을 그룹핑"""
        groups = []
        remaining = ready_agents.copy()
        
        while remaining:
            agent = remaining[0]
            group = [agent]
            remaining.remove(agent)
            
            # 같은 그룹에 추가할 수 있는 에이전트 찾기
            agent_config = self.agents_config[agent]
            if agent_config.parallel_with:
                for parallel_agent in agent_config.parallel_with:
                    if parallel_agent in remaining:
                        group.append(parallel_agent)
                        remaining.remove(parallel_agent)
            
            groups.append(group)
        
        return groups

def main():
    """CLI 인터페이스"""
    import argparse
    
    parser = argparse.ArgumentParser(description='VELOCITY-X Workflow Engine')
    parser.add_argument('workflow', help='Workflow name to run')
    parser.add_argument('files', nargs='*', help='Input files')
    parser.add_argument('--config-dir', help='Configuration directory')
    parser.add_argument('--verbose', '-v', action='store_true', help='Verbose logging')
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    try:
        engine = WorkflowEngine(config_dir=args.config_dir)
        result = engine.run_workflow(args.workflow, args.files)
        
        print(f"\nWorkflow {args.workflow} completed!")
        print(f"Status: {result['status']}")
        print(f"Duration: {result['duration_seconds']:.1f} seconds")
        print(f"Success: {result['statistics']['success']}")
        print(f"Failed: {result['statistics']['failed']}")
        print(f"Report: {result.get('report_file', 'N/A')}")
        
        sys.exit(0 if result['status'] == 'success' else 1)
        
    except Exception as e:
        logger.error(f"Workflow execution failed: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()