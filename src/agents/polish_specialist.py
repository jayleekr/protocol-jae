"""Polish Specialist Agent - Code quality improvement expert."""

from typing import Any, Dict

from crewai import Agent, Task
from langchain_openai import ChatOpenAI

from src.config import AGENT_CONFIG, LLM_CONFIG
from src.tools.analysis_tools import complexity_tool, pylint_tool, ruff_tool
from src.tools.git_tools import git_diff_tool, git_file_tool


class PolishSpecialist:
    """Agent specialized in code quality improvement and refactoring."""

    def __init__(self):
        """Initialize the Polish Specialist agent."""
        self.config = AGENT_CONFIG["polish_specialist"]
        
        # Initialize LLM
        self.llm = ChatOpenAI(
            model_name=LLM_CONFIG["openai"]["model"],
            openai_api_key=LLM_CONFIG["openai"]["api_key"],
            temperature=0.1,  # Low temperature for consistent refactoring
        )
        
        # Initialize tools
        self.tools = [
            git_file_tool,
            git_diff_tool,
            ruff_tool,
            pylint_tool,
            complexity_tool,
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

    def create_polish_task(self, file_path: str) -> Task:
        """
        Create a task for polishing code.

        Args:
            file_path: Path to the file to polish

        Returns:
            Task object for code polishing
        """
        task_description = f"""
        당신의 임무는 {file_path} 파일의 코드 품질을 개선하는 것입니다.

        다음 단계를 따라주세요:
        
        1. 파일 분석:
           - Git File Tool을 사용하여 파일을 읽어주세요
           - Ruff Tool로 코드 스타일 문제를 확인하세요
           - Pylint Tool로 코드 품질을 분석하세요
           - Code Complexity Tool로 복잡도를 확인하세요
        
        2. 개선 사항 식별:
           - DRY (Don't Repeat Yourself) 원칙 위반 찾기
           - KISS (Keep It Simple, Stupid) 원칙 적용 기회 찾기
           - SOLID 원칙 위반 확인
           - 변수명/함수명 개선 기회
           - 불필요한 복잡도 제거 가능성
           - 코드 가독성 개선 포인트
        
        3. 리팩토링 수행:
           - 식별된 문제들을 하나씩 수정
           - Git File Tool을 사용하여 개선된 코드 저장
           - 각 변경사항에 대한 이유 설명
        
        4. 검증:
           - 수정 후 다시 분석 도구 실행
           - Git Diff Tool로 변경사항 확인
           - 개선 결과 요약
        
        최종 산출물:
        - 개선된 코드가 저장된 파일
        - 수행한 개선사항 목록과 각각의 이유
        - 코드 품질 점수의 변화 (있는 경우)
        """
        
        return Task(
            description=task_description,
            agent=self.agent,
            expected_output=(
                "1. 개선된 코드 파일\n"
                "2. 수행한 리팩토링 작업 목록\n"
                "3. 코드 품질 메트릭 개선 결과"
            ),
        )

    def polish_code(self, file_path: str) -> Dict[str, Any]:
        """
        Polish code in the given file.

        Args:
            file_path: Path to the file to polish

        Returns:
            Dictionary containing results and improvements made
        """
        task = self.create_polish_task(file_path)
        result = task.execute()
        
        return {
            "file_path": file_path,
            "improvements": result,
            "agent": "polish_specialist",
        }