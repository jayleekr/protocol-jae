"""Test Engineer Agent - Automated test generation expert."""

from typing import Any, Dict

from crewai import Agent, Task
from langchain_openai import ChatOpenAI

from src.config import AGENT_CONFIG, LLM_CONFIG
from src.tools.git_tools import git_file_tool


class TestEngineer:
    """Agent specialized in test generation and test coverage improvement."""

    def __init__(self):
        """Initialize the Test Engineer agent."""
        self.config = AGENT_CONFIG["test_engineer"]
        
        # Initialize LLM
        self.llm = ChatOpenAI(
            model_name=LLM_CONFIG["openai"]["model"],
            openai_api_key=LLM_CONFIG["openai"]["api_key"],
            temperature=0.2,  # Low temperature for consistent test generation
        )
        
        # Initialize tools
        self.tools = [
            git_file_tool,
        ]
        
        # Create the agent
        self.agent = Agent(
            role=self.config["role"],
            goal=self.config["goal"],
            backstory=self.config["backstory"],
            tools=self.tools,
            llm=self.llm,
            verbose=True,
            allow_delegation=False,
        )

    def create_test_generation_task(
        self, 
        file_path: str,
        test_framework: str = "pytest"
    ) -> Task:
        """
        Create a task for generating tests.

        Args:
            file_path: Path to the file to test
            test_framework: Testing framework to use (default: pytest)

        Returns:
            Task object for test generation
        """
        task_description = f"""
        당신의 임무는 {file_path} 파일에 대한 포괄적인 테스트를 생성하는 것입니다.

        테스트 생성 가이드라인:
        
        1. 코드 분석:
           - Git File Tool을 사용하여 소스 코드 읽기
           - 모든 함수, 클래스, 메서드 식별
           - 각 컴포넌트의 입출력 및 동작 이해
        
        2. 테스트 케이스 설계:
           - 정상 케이스 (Happy Path)
           - 경계값 테스트 (Boundary Cases)
           - 예외 케이스 (Edge Cases)
           - 오류 처리 테스트
           - 부정적 테스트 (Negative Testing)
        
        3. 테스트 유형별 구현:
           - 단위 테스트 (Unit Tests): 개별 함수/메서드
           - 통합 테스트 (Integration Tests): 컴포넌트 간 상호작용
           - 파라미터화 테스트: 다양한 입력값 테스트
           - Mock/Stub 사용: 외부 의존성 격리
        
        4. 테스트 구조:
           - Arrange-Act-Assert (AAA) 패턴 사용
           - 명확한 테스트 이름 (test_<기능>_<시나리오>_<예상결과>)
           - 독립적이고 반복 가능한 테스트
           - 적절한 픽스처(fixture) 사용
        
        5. 커버리지 목표:
           - 라인 커버리지: 90% 이상
           - 브랜치 커버리지: 80% 이상
           - 모든 public 메서드 테스트
           - 중요한 private 메서드도 간접 테스트
        
        테스트 프레임워크: {test_framework}
        
        생성할 테스트 파일 구조:
        ```python
        import pytest
        from unittest.mock import Mock, patch
        # 필요한 import 문들
        
        class Test<ClassName>:
            @pytest.fixture
            def setup(self):
                # 테스트 설정
                pass
            
            def test_<method>_정상케이스(self, setup):
                # Given
                # When
                # Then
                pass
            
            def test_<method>_예외케이스(self, setup):
                # Given
                # When
                # Then
                pass
            
            @pytest.mark.parametrize("input,expected", [
                # 파라미터화된 테스트 케이스들
            ])
            def test_<method>_다양한입력(self, input, expected):
                # 테스트 구현
                pass
        ```
        
        테스트 파일은 tests/ 디렉토리에 test_<원본파일명>.py 형식으로 저장하세요.
        """
        
        return Task(
            description=task_description,
            agent=self.agent,
            expected_output=(
                "1. 완성된 테스트 파일\n"
                "2. 테스트 케이스 목록과 각각의 목적\n"
                "3. 예상 테스트 커버리지\n"
                "4. 추가 테스트가 필요한 영역 (있는 경우)"
            ),
        )

    def generate_tests(
        self, 
        file_path: str,
        test_framework: str = "pytest"
    ) -> Dict[str, Any]:
        """
        Generate tests for the given file.

        Args:
            file_path: Path to the file to test
            test_framework: Testing framework to use

        Returns:
            Dictionary containing generated tests and metadata
        """
        task = self.create_test_generation_task(file_path, test_framework)
        result = task.execute()
        
        return {
            "source_file": file_path,
            "test_results": result,
            "framework": test_framework,
            "agent": "test_engineer",
        }

    def improve_test_coverage(
        self, test_file_path: str, source_file_path: str
    ) -> Dict[str, Any]:
        """
        Improve existing test coverage by adding missing tests.

        Args:
            test_file_path: Path to existing test file
            source_file_path: Path to source file being tested

        Returns:
            Dictionary containing coverage improvements
        """
        task = Task(
            description=f"""
            기존 테스트 파일 {test_file_path}의 커버리지를 개선하세요.
            
            1. Git File Tool로 소스 파일({source_file_path})과 테스트 파일 읽기
            2. 테스트되지 않은 코드 경로 식별
            3. 누락된 엣지 케이스 찾기
            4. 추가 테스트 케이스 생성
            5. 기존 테스트와 일관된 스타일 유지
            
            결과물:
            - 추가할 테스트 케이스들
            - 개선된 커버리지 예상치
            - 테스트 추가 이유 설명
            """,
            agent=self.agent,
            expected_output="추가 테스트 케이스와 커버리지 개선 계획",
        )
        
        result = task.execute()
        
        return {
            "test_file": test_file_path,
            "source_file": source_file_path,
            "improvements": result,
            "agent": "test_engineer",
        }