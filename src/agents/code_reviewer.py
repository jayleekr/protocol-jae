"""Code Reviewer Agent - Automated code review expert."""

from typing import List, Dict, Any, Optional
from crewai import Agent, Task
from langchain_openai import ChatOpenAI
from src.config import AGENT_CONFIG, LLM_CONFIG
from src.tools.git_tools import git_file_tool, git_diff_tool, git_status_tool
from src.tools.analysis_tools import ruff_tool, pylint_tool


class CodeReviewer:
    """Agent specialized in code review and best practices enforcement."""

    def __init__(self):
        """Initialize the Code Reviewer agent."""
        self.config = AGENT_CONFIG["code_reviewer"]
        
        # Initialize LLM
        self.llm = ChatOpenAI(
            model_name=LLM_CONFIG["openai"]["model"],
            openai_api_key=LLM_CONFIG["openai"]["api_key"],
            temperature=0.3,  # Slightly higher for more comprehensive reviews
        )
        
        # Initialize tools
        self.tools = [
            git_file_tool,
            git_diff_tool,
            git_status_tool,
            ruff_tool,
            pylint_tool,
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

    def create_review_task(
        self, 
        file_path: str, 
        context: Optional[str] = None
    ) -> Task:
        """
        Create a task for reviewing code.

        Args:
            file_path: Path to the file to review
            context: Optional context about the changes

        Returns:
            Task object for code review
        """
        task_description = f"""
        당신의 임무는 {file_path} 파일에 대한 철저한 코드 리뷰를 수행하는 것입니다.

        리뷰 체크리스트:
        
        1. 코드 품질 검사:
           - Git File Tool을 사용하여 전체 코드 읽기
           - Ruff와 Pylint로 자동 검사 수행
           - 코드 스타일 가이드 준수 여부 확인
        
        2. 버그 및 오류 검토:
           - 잠재적 런타임 오류 찾기
           - 엣지 케이스 처리 확인
           - 예외 처리 적절성 검토
           - 타입 안정성 확인
        
        3. 보안 취약점 검사:
           - SQL 인젝션 가능성
           - XSS 취약점
           - 하드코딩된 시크릿/비밀번호
           - 안전하지 않은 직렬화/역직렬화
           - OWASP Top 10 관련 이슈
        
        4. 성능 및 최적화:
           - 불필요한 반복문이나 연산
           - 메모리 누수 가능성
           - 데이터베이스 쿼리 최적화 기회
           - 캐싱 기회
        
        5. 설계 및 아키텍처:
           - SOLID 원칙 준수
           - 디자인 패턴 적절성
           - 모듈화 및 재사용성
           - 의존성 관리
        
        6. 가독성 및 유지보수성:
           - 변수/함수 네이밍 명확성
           - 주석의 적절성
           - 복잡도가 높은 함수 식별
           - 코드 중복 확인
        
        {f"추가 컨텍스트: {context}" if context else ""}
        
        리뷰 결과는 다음 형식으로 제공해주세요:
        
        ## 요약
        - 전반적인 코드 품질 평가
        - 주요 발견사항
        
        ## 중요 이슈 (반드시 수정 필요)
        - 보안 취약점
        - 버그나 오류
        - 심각한 성능 문제
        
        ## 개선 제안 (권장사항)
        - 코드 품질 개선
        - 가독성 향상
        - 성능 최적화
        
        ## 칭찬할 점
        - 잘 작성된 부분
        - 좋은 패턴 사용
        
        ## 점수
        - 전체 점수: X/10
        - 세부 점수: 보안(X/10), 성능(X/10), 가독성(X/10), 설계(X/10)
        """
        
        return Task(
            description=task_description,
            agent=self.agent,
            expected_output=(
                "1. 구조화된 코드 리뷰 보고서\n"
                "2. 발견된 이슈 목록과 심각도\n"
                "3. 구체적인 개선 제안\n"
                "4. 전체 코드 품질 점수"
            ),
        )

    def review_code(
        self, 
        file_path: str,
        context: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Review code in the given file.

        Args:
            file_path: Path to the file to review
            context: Optional context about the changes

        Returns:
            Dictionary containing review results
        """
        task = self.create_review_task(file_path, context)
        result = task.execute()
        
        return {
            "file_path": file_path,
            "review": result,
            "agent": "code_reviewer",
        }

    def review_changes(self) -> Dict[str, Any]:
        """
        Review all changed files in the repository.

        Returns:
            Dictionary containing review results for all changed files
        """
        # First, check git status to find changed files
        status_task = Task(
            description="Git Status Tool을 사용하여 변경된 파일 목록을 가져오세요.",
            agent=self.agent,
            expected_output="변경된 파일 목록",
        )
        
        status_result = status_task.execute()
        
        # Then create a comprehensive review task
        review_task = Task(
            description=f"""
            다음 변경사항들에 대해 종합적인 코드 리뷰를 수행하세요:
            
            {status_result}
            
            각 파일에 대해:
            1. Git Diff Tool로 변경사항 확인
            2. 변경된 부분에 집중하여 리뷰 수행
            3. 전체 컨텍스트를 고려한 영향도 분석
            """,
            agent=self.agent,
            expected_output="모든 변경사항에 대한 종합적인 리뷰 보고서",
        )
        
        result = review_task.execute()
        
        return {
            "review": result,
            "agent": "code_reviewer",
            "type": "changes_review",
        }