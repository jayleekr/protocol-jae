#!/bin/bash
# VELOCITY-X Polish Specialist Agent
# 코드 품질 개선 및 리팩토링 전문가

set -euo pipefail

# 스크립트 디렉토리 및 공통 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/common.sh"

# 에이전트 정보
readonly AGENT_NAME="velocity-x-polish-specialist"
readonly AGENT_DESCRIPTION="코드 품질 개선 및 리팩토링 전문가"

# 필수 도구
readonly REQUIRED_TOOLS=("python3" "git")

# 사용법 출력
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <input_file>

VELOCITY-X Polish Specialist - 코드 품질 개선 및 리팩토링 전문가

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose logging
    -o, --output DIR        Output directory (default: auto-generated)
    --format-only           Only apply code formatting
    --analyze-only          Only analyze, don't modify files
    --config FILE           Custom configuration file

ARGUMENTS:
    input_file              Python file to polish (.py)

EXAMPLES:
    $0 src/example.py
    $0 --format-only src/module.py
    $0 --analyze-only --verbose src/complex.py

EOF
}

# 도구 실행 함수들
run_static_analysis() {
    local file="$1"
    local output_dir="$2"
    
    log_info "Running static analysis on: $file"
    
    # Ruff 실행
    if command -v ruff &> /dev/null; then
        log_debug "Running ruff check..."
        ruff check "$file" --format=json --output-file="$output_dir/ruff_report.json" || true
        ruff check "$file" --format=text > "$output_dir/ruff_report.txt" || true
    fi
    
    # Pylint 실행  
    if command -v pylint &> /dev/null; then
        log_debug "Running pylint..."
        pylint "$file" --output-format=json > "$output_dir/pylint_report.json" || true
        pylint "$file" > "$output_dir/pylint_report.txt" || true
    fi
    
    # MyPy 실행
    if command -v mypy &> /dev/null; then
        log_debug "Running mypy..."
        mypy "$file" --json-report "$output_dir" || true
    fi
    
    log_info "Static analysis completed"
}

run_complexity_analysis() {
    local file="$1"
    local output_dir="$2"
    
    log_info "Running complexity analysis on: $file"
    
    # Radon 복잡도 분석
    if command -v radon &> /dev/null; then
        log_debug "Running radon complexity analysis..."
        radon cc "$file" --json > "$output_dir/complexity_report.json" || true
        radon cc "$file" > "$output_dir/complexity_report.txt" || true
        radon mi "$file" > "$output_dir/maintainability_report.txt" || true
    fi
    
    log_info "Complexity analysis completed"
}

apply_code_formatting() {
    local file="$1"
    local output_dir="$2"
    local formatted_file="$output_dir/$(basename "$file")"
    
    log_info "Applying code formatting to: $file"
    
    # 원본 파일 복사
    cp "$file" "$formatted_file"
    
    # Black 포맷팅
    if command -v black &> /dev/null; then
        log_debug "Running black formatter..."
        black --line-length=88 --target-version=py311 "$formatted_file" || true
    fi
    
    # isort import 정리
    if command -v isort &> /dev/null; then
        log_debug "Running isort..."
        isort --profile=black "$formatted_file" || true
    fi
    
    log_info "Code formatting completed: $formatted_file"
    echo "$formatted_file"
}

detect_code_smells() {
    local file="$1"
    local output_dir="$2"
    
    log_info "Detecting code smells in: $file"
    
    # 간단한 코드 스멜 탐지 스크립트
    python3 << EOF > "$output_dir/code_smells.json"
import ast
import json
import sys

class CodeSmellDetector(ast.NodeVisitor):
    def __init__(self):
        self.smells = []
        self.current_class = None
        self.current_function = None
    
    def visit_FunctionDef(self, node):
        self.current_function = node.name
        
        # 긴 함수 탐지
        if len(node.body) > 20:
            self.smells.append({
                "type": "long_function",
                "line": node.lineno,
                "message": f"Function '{node.name}' is too long ({len(node.body)} lines)",
                "severity": "medium"
            })
        
        # 매개변수가 너무 많음
        if len(node.args.args) > 5:
            self.smells.append({
                "type": "too_many_parameters",
                "line": node.lineno,
                "message": f"Function '{node.name}' has too many parameters ({len(node.args.args)})",
                "severity": "medium"
            })
        
        self.generic_visit(node)
        self.current_function = None
    
    def visit_ClassDef(self, node):
        self.current_class = node.name
        
        # 클래스가 너무 큼
        if len(node.body) > 50:
            self.smells.append({
                "type": "large_class",
                "line": node.lineno,
                "message": f"Class '{node.name}' is too large ({len(node.body)} members)",
                "severity": "high"
            })
        
        self.generic_visit(node)
        self.current_class = None
    
    def visit_For(self, node):
        # 중첩 루프 탐지
        for child in ast.walk(node):
            if isinstance(child, (ast.For, ast.While)) and child != node:
                self.smells.append({
                    "type": "nested_loop",
                    "line": node.lineno,
                    "message": "Nested loop detected - consider optimization",
                    "severity": "medium"
                })
                break
        
        self.generic_visit(node)

try:
    with open("$file", "r") as f:
        tree = ast.parse(f.read())
    
    detector = CodeSmellDetector()
    detector.visit(tree)
    
    result = {
        "file": "$file",
        "timestamp": "$(date -Iseconds)",
        "total_smells": len(detector.smells),
        "smells": detector.smells
    }
    
    print(json.dumps(result, indent=2))
    
except Exception as e:
    print(json.dumps({"error": str(e)}, indent=2))
EOF
    
    log_info "Code smell detection completed"
}

generate_improvement_suggestions() {
    local file="$1"
    local output_dir="$2"
    
    log_info "Generating improvement suggestions for: $file"
    
    # 분석 결과들을 종합하여 개선 제안 생성
    python3 << EOF > "$output_dir/improvement_suggestions.json"
import json
import os

suggestions = {
    "file": "$file",
    "timestamp": "$(date -Iseconds)",
    "suggestions": []
}

# 정적 분석 결과 읽기
reports_dir = "$output_dir"

# Ruff 결과 처리
ruff_file = os.path.join(reports_dir, "ruff_report.json")
if os.path.exists(ruff_file):
    try:
        with open(ruff_file) as f:
            ruff_data = json.load(f)
        
        for issue in ruff_data:
            suggestions["suggestions"].append({
                "type": "style_issue",
                "tool": "ruff",
                "line": issue.get("location", {}).get("row", 0),
                "message": issue.get("message", ""),
                "code": issue.get("code", ""),
                "priority": "low"
            })
    except Exception as e:
        pass

# 코드 스멜 결과 처리
smells_file = os.path.join(reports_dir, "code_smells.json")
if os.path.exists(smells_file):
    try:
        with open(smells_file) as f:
            smells_data = json.load(f)
        
        for smell in smells_data.get("smells", []):
            suggestions["suggestions"].append({
                "type": "code_smell",
                "tool": "ast_analyzer",
                "line": smell.get("line", 0),
                "message": smell.get("message", ""),
                "smell_type": smell.get("type", ""),
                "priority": smell.get("severity", "medium")
            })
    except Exception as e:
        pass

# 일반적인 개선 제안 추가
general_suggestions = [
    {
        "type": "general",
        "tool": "polish_specialist",
        "message": "Consider adding type hints for better code clarity",
        "priority": "medium"
    },
    {
        "type": "general", 
        "tool": "polish_specialist",
        "message": "Add docstrings for public functions and classes",
        "priority": "medium"
    },
    {
        "type": "general",
        "tool": "polish_specialist", 
        "message": "Consider extracting magic numbers into named constants",
        "priority": "low"
    }
]

suggestions["suggestions"].extend(general_suggestions)
suggestions["total_suggestions"] = len(suggestions["suggestions"])

print(json.dumps(suggestions, indent=2))
EOF
    
    log_info "Improvement suggestions generated"
}

# 메인 폴리싱 함수
polish_code() {
    local input_file="$1"
    local analyze_only="${2:-false}"
    local format_only="${3:-false}"
    
    show_progress 1 6 "Validating input file"
    validate_input_file "$input_file"
    
    show_progress 2 6 "Running static analysis"
    run_static_analysis "$input_file" "$AGENT_OUTPUT_DIR"
    
    show_progress 3 6 "Analyzing complexity"
    run_complexity_analysis "$input_file" "$AGENT_OUTPUT_DIR"
    
    show_progress 4 6 "Detecting code smells"
    detect_code_smells "$input_file" "$AGENT_OUTPUT_DIR"
    
    if [[ "$analyze_only" == "true" ]]; then
        show_progress 6 6 "Analysis completed (no modifications)"
        return 0
    fi
    
    show_progress 5 6 "Applying code formatting"
    local formatted_file
    formatted_file=$(apply_code_formatting "$input_file" "$AGENT_OUTPUT_DIR")
    
    if [[ "$format_only" != "true" ]]; then
        show_progress 6 6 "Generating improvement suggestions"
        generate_improvement_suggestions "$input_file" "$AGENT_OUTPUT_DIR"
    fi
    
    # 결과 요약 생성
    cat > "$AGENT_OUTPUT_DIR/summary.json" << EOF
{
    "agent": "$AGENT_NAME",
    "input_file": "$input_file",
    "formatted_file": "$formatted_file",
    "analyze_only": $analyze_only,
    "format_only": $format_only,
    "timestamp": "$(date -Iseconds)",
    "status": "completed",
    "output_files": {
        "static_analysis": "ruff_report.json, pylint_report.json",
        "complexity_analysis": "complexity_report.json",
        "code_smells": "code_smells.json",
        "formatted_code": "$(basename "$formatted_file")",
        "suggestions": "improvement_suggestions.json"
    }
}
EOF
    
    show_progress 6 6 "Code polishing completed"
    log_info "All polishing tasks completed successfully"
}

# 메인 함수
main() {
    local input_file=""
    local analyze_only=false
    local format_only=false
    local verbose=false
    
    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                export VELOCITY-X_LOG_LEVEL=$LOG_DEBUG
                verbose=true
                shift
                ;;
            -o|--output)
                export VELOCITY-X_OUTPUT_DIR="$2"
                shift 2
                ;;
            --analyze-only)
                analyze_only=true
                shift
                ;;
            --format-only)
                format_only=true
                shift
                ;;
            --config)
                # 커스텀 설정 파일 (향후 구현)
                shift 2
                ;;
            -*)
                error_exit "Unknown option: $1"
                ;;
            *)
                if [[ -z "$input_file" ]]; then
                    input_file="$1"
                else
                    error_exit "Multiple input files not supported"
                fi
                shift
                ;;
        esac
    done
    
    # 입력 파일 검증
    if [[ -z "$input_file" ]]; then
        error_exit "Input file is required. Use -h for help."
    fi
    
    if [[ ! "$input_file" =~ \.py$ ]]; then
        error_exit "Input file must be a Python file (.py)"
    fi
    
    # 필수 도구 확인
    check_required_tools "${REQUIRED_TOOLS[@]}"
    
    # 에이전트 초기화
    init_agent "$AGENT_NAME" "$input_file"
    
    # 트랩 설정 (에러 시 정리)
    trap 'cleanup_agent "error" "Agent interrupted or failed"' INT TERM ERR
    
    # 메인 작업 수행
    polish_code "$input_file" "$analyze_only" "$format_only"
    
    # 성공적으로 완료
    cleanup_agent "success" "Code polishing completed successfully"
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi