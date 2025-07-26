"""Configuration for Jae agents and tools."""

import os
from pathlib import Path

from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Project paths
PROJECT_ROOT = Path(__file__).parent.parent
SRC_DIR = PROJECT_ROOT / "src"
TESTS_DIR = PROJECT_ROOT / "tests"

# LLM Configuration
LLM_CONFIG = {
    "openai": {
        "api_key": os.getenv("OPENAI_API_KEY"),
        "model": os.getenv("OPENAI_MODEL_NAME", "gpt-4-turbo-preview"),
    },
    "anthropic": {
        "api_key": os.getenv("ANTHROPIC_API_KEY"),
        "model": os.getenv("ANTHROPIC_MODEL_NAME", "claude-3-opus-20240229"),
    },
}

# Agent Configuration
AGENT_CONFIG = {
    "polish_specialist": {
        "role": "코드 품질 개선 전문가",
        "goal": "코드의 가독성, 유지보수성, 성능을 개선하고 클린 코드 원칙을 적용",
        "backstory": """당신은 20년 이상의 경험을 가진 시니어 소프트웨어 엔지니어입니다.
        Robert C. Martin의 클린 코드 원칙, Martin Fowler의 리팩토링 기법을 마스터했으며,
        DRY, KISS, SOLID 원칙을 완벽하게 이해하고 있습니다.
        코드의 품질을 개선하여 기술 부채를 줄이는 것이 당신의 사명입니다.""",
    },
    "code_reviewer": {
        "role": "코드 리뷰 전문가",
        "goal": "잠재적 버그, 보안 취약점, 성능 문제를 찾아내고 모범 사례 준수 확인",
        "backstory": """당신은 구글, 아마존 등 빅테크 기업에서 코드 리뷰 문화를 정착시킨
        전문가입니다. 수천 개의 PR을 리뷰하며 쌓은 경험으로 코드의 문제점을
        즉시 파악할 수 있습니다. OWASP Top 10 보안 취약점에 정통하며,
        성능 최적화와 확장성 있는 설계에 대한 깊은 통찰력을 가지고 있습니다.""",
    },
    "test_engineer": {
        "role": "테스트 자동화 전문가",
        "goal": "포괄적인 테스트 케이스를 생성하여 코드의 신뢰성과 안정성 보장",
        "backstory": """당신은 TDD/BDD 방법론의 선구자이며, 
        테스트 자동화 분야의 전문가입니다.
        단위 테스트, 통합 테스트, E2E 테스트의 균형을 완벽하게 이해하고 있으며,
        테스트 커버리지 90% 이상을 달성하는 것을 목표로 합니다.
        테스트 피라미드 원칙을 따르며, 빠르고 신뢰할 수 있는 테스트를 작성합니다.""",
    },
}

# Tool Configuration
TOOL_CONFIG = {
    "static_analysis": {
        "ruff": {
            "enabled": True,
            "config_file": PROJECT_ROOT / "pyproject.toml",
        },
        "pylint": {
            "enabled": True,
            "min_score": 8.0,
        },
    },
    "test_frameworks": {
        "pytest": {
            "enabled": True,
            "min_coverage": 80,
        },
    },
}

# CrewAI Configuration
CREW_CONFIG = {
    "verbose": os.getenv("CREW_VERBOSE", "true").lower() == "true",
    "memory": os.getenv("CREW_MEMORY", "true").lower() == "true",
    "max_iterations": 5,
}