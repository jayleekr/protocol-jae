#!/bin/bash
# JAE Code Reviewer Agent
# 코드 리뷰 및 표준 준수 전문가

set -euo pipefail

# 스크립트 디렉토리 및 공통 함수 로드
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../core/common.sh"

# 에이전트 정보
readonly AGENT_NAME="jae-code-reviewer"
readonly AGENT_DESCRIPTION="코드 리뷰 및 표준 준수 전문가"

# 필수 도구
readonly REQUIRED_TOOLS=("python3" "git")

# 사용법 출력
usage() {
    cat << EOF
Usage: $0 [OPTIONS] <input_file>

JAE Code Reviewer - 코드 리뷰 및 표준 준수 전문가

OPTIONS:
    -h, --help              Show this help message
    -v, --verbose           Enable verbose logging
    -o, --output DIR        Output directory (default: auto-generated)
    --context FILE          Additional context file
    --strict                Enable strict review mode
    --focus AREA            Focus on specific area (security|performance|style|all)

ARGUMENTS:
    input_file              Python file to review (.py)

EXAMPLES:
    $0 src/example.py
    $0 --strict --focus security src/module.py
    $0 --context context.txt src/complex.py

EOF
}

# 코드 리뷰 체크리스트 실행
run_functionality_review() {
    local file="$1"
    local output_dir="$2"
    
    log_info "Running functionality review on: $file"
    
    python3 << EOF > "$output_dir/functionality_review.json"
import ast
import json
import re

class FunctionalityReviewer(ast.NodeVisitor):
    def __init__(self):
        self.issues = []
        self.functions = []
        self.classes = []
    
    def visit_FunctionDef(self, node):
        self.functions.append({
            "name": node.name,
            "line": node.lineno,
            "args_count": len(node.args.args),
            "has_docstring": ast.get_docstring(node) is not None,
            "has_return": any(isinstance(n, ast.Return) for n in ast.walk(node))
        })
        
        # 함수명 검사
        if not re.match(r'^[a-z_][a-z0-9_]*$', node.name) and not node.name.startswith('__'):
            self.issues.append({
                "type": "naming",
                "severity": "medium",
                "line": node.lineno,
                "message": f"Function '{node.name}' should use snake_case naming"
            })
        
        # docstring 검사
        if not ast.get_docstring(node) and not node.name.startswith('_'):
            self.issues.append({
                "type": "documentation",
                "severity": "low",
                "line": node.lineno,
                "message": f"Public function '{node.name}' missing docstring"
            })
        
        # 매개변수 개수 검사
        if len(node.args.args) > 5:
            self.issues.append({
                "type": "design",
                "severity": "medium",
                "line": node.lineno,
                "message": f"Function '{node.name}' has too many parameters ({len(node.args.args)})"
            })
        
        self.generic_visit(node)
    
    def visit_ClassDef(self, node):
        self.classes.append({
            "name": node.name,
            "line": node.lineno,
            "methods_count": len([n for n in node.body if isinstance(n, ast.FunctionDef)]),
            "has_docstring": ast.get_docstring(node) is not None
        })
        
        # 클래스명 검사
        if not re.match(r'^[A-Z][a-zA-Z0-9]*$', node.name):
            self.issues.append({
                "type": "naming",
                "severity": "medium",
                "line": node.lineno,
                "message": f"Class '{node.name}' should use PascalCase naming"
            })
        
        self.generic_visit(node)
    
    def visit_Try(self, node):
        # 너무 넓은 예외 처리
        for handler in node.handlers:
            if handler.type is None or (isinstance(handler.type, ast.Name) and handler.type.id == 'Exception'):
                self.issues.append({
                    "type": "error_handling",
                    "severity": "medium",
                    "line": handler.lineno,
                    "message": "Avoid bare except or catching Exception too broadly"
                })
        
        self.generic_visit(node)

try:
    with open("$file", "r") as f:
        content = f.read()
        tree = ast.parse(content)
    
    reviewer = FunctionalityReviewer()
    reviewer.visit(tree)
    
    result = {
        "file": "$file",
        "timestamp": "$(date -Iseconds)",
        "total_issues": len(reviewer.issues),
        "issues": reviewer.issues,
        "statistics": {
            "functions_count": len(reviewer.functions),
            "classes_count": len(reviewer.classes),
            "functions_with_docstring": sum(1 for f in reviewer.functions if f["has_docstring"]),
            "public_functions": len([f for f in reviewer.functions if not f["name"].startswith("_")])
        }
    }
    
    print(json.dumps(result, indent=2))
    
except Exception as e:
    print(json.dumps({"error": str(e)}, indent=2))
EOF
    
    log_info "Functionality review completed"
}

run_security_review() {
    local file="$1"
    local output_dir="$2"
    
    log_info "Running security review on: $file"
    
    python3 << EOF > "$output_dir/security_review.json"
import ast
import json
import re

class SecurityReviewer(ast.NodeVisitor):
    def __init__(self):
        self.security_issues = []
    
    def visit_Call(self, node):
        # SQL injection 위험
        if (isinstance(node.func, ast.Attribute) and 
            isinstance(node.func.attr, str) and
            node.func.attr in ['execute', 'executemany']):
            
            for arg in node.args:
                if isinstance(arg, ast.BinOp) and isinstance(arg.op, (ast.Add, ast.Mod)):
                    self.security_issues.append({
                        "type": "sql_injection",
                        "severity": "high",
                        "line": node.lineno,
                        "message": "Potential SQL injection vulnerability - use parameterized queries"
                    })
        
        # eval/exec 사용
        if isinstance(node.func, ast.Name) and node.func.id in ['eval', 'exec']:
            self.security_issues.append({
                "type": "code_injection",
                "severity": "high", 
                "line": node.lineno,
                "message": f"Use of {node.func.id}() is dangerous - avoid if possible"
            })
        
        # subprocess with shell=True
        if (isinstance(node.func, ast.Attribute) and 
            isinstance(node.func.value, ast.Name) and
            node.func.value.id == 'subprocess'):
            
            for keyword in node.keywords:
                if keyword.arg == 'shell' and isinstance(keyword.value, ast.Constant) and keyword.value.value:
                    self.security_issues.append({
                        "type": "command_injection",
                        "severity": "high",
                        "line": node.lineno,
                        "message": "subprocess with shell=True can be dangerous"
                    })
        
        self.generic_visit(node)
    
    def visit_Assign(self, node):
        # 하드코딩된 비밀번호/키 할당 탐지
        for target in node.targets:
            if isinstance(target, ast.Name):
                var_name = target.id.lower()
                if isinstance(node.value, ast.Str):
                    value = node.value.s
                elif isinstance(node.value, ast.Constant) and isinstance(node.value.value, str):
                    value = node.value.value
                else:
                    continue
                
                # 민감한 변수명 패턴
                sensitive_patterns = [
                    'password', 'pwd', 'pass', 'secret', 'key', 'token', 
                    'api_key', 'auth', 'credential', 'private'
                ]
                
                for pattern in sensitive_patterns:
                    if pattern in var_name and len(value) > 3:  # 최소 길이 체크
                        self.security_issues.append({
                            "type": f"hardcoded_{pattern}",
                            "severity": "high",
                            "line": node.lineno,
                            "message": f"Potential hardcoded {pattern} detected: {var_name}"
                        })
                        break
        
        self.generic_visit(node)
        
    def visit_Str(self, node):
        # 문자열 내 패턴 검사 (Python 3.7 이하 호환성)
        self._check_string_patterns(node.s, node.lineno)
        self.generic_visit(node)
    
    def visit_Constant(self, node):
        # 상수 내 패턴 검사 (Python 3.8+)
        if isinstance(node.value, str):
            self._check_string_patterns(node.value, node.lineno)
        self.generic_visit(node)
    
    def _check_string_patterns(self, text, lineno):
        # 문자열 내 민감한 패턴 검사
        patterns = [
            (r'password\s*=\s*["\'][^"\']+["\']', "hardcoded_password"),
            (r'api[_-]?key\s*[=:]\s*["\'][^"\']+["\']', "hardcoded_api_key"),
            (r'secret\s*[=:]\s*["\'][^"\']+["\']', "hardcoded_secret"),
            (r'token\s*[=:]\s*["\'][^"\']+["\']', "hardcoded_token")
        ]
        
        for pattern, issue_type in patterns:
            if re.search(pattern, text, re.IGNORECASE):
                self.security_issues.append({
                    "type": issue_type,
                    "severity": "high",
                    "line": lineno,
                    "message": f"Potential {issue_type.replace('_', ' ')} in string literal"
                })

try:
    with open("$file", "r") as f:
        content = f.read()
        tree = ast.parse(content)
    
    reviewer = SecurityReviewer()
    reviewer.visit(tree)
    
    result = {
        "file": "$file",
        "timestamp": "$(date -Iseconds)",
        "total_security_issues": len(reviewer.security_issues),
        "security_issues": reviewer.security_issues,
        "security_score": max(0, 100 - len(reviewer.security_issues) * 10)
    }
    
    print(json.dumps(result, indent=2))
    
except Exception as e:
    print(json.dumps({"error": str(e)}, indent=2))
EOF
    
    log_info "Security review completed"
}

run_performance_review() {
    local file="$1"
    local output_dir="$2"
    
    log_info "Running performance review on: $file"
    
    python3 << EOF > "$output_dir/performance_review.json"
import ast
import json

class PerformanceReviewer(ast.NodeVisitor):
    def __init__(self):
        self.performance_issues = []
    
    def visit_For(self, node):
        # 중첩 루프 감지
        nested_loops = 0
        for child in ast.walk(node):
            if isinstance(child, (ast.For, ast.While)) and child != node:
                nested_loops += 1
        
        if nested_loops > 0:
            self.performance_issues.append({
                "type": "nested_loop",
                "severity": "medium",
                "line": node.lineno,
                "message": f"Nested loop detected - consider optimization (O(n²) complexity)"
            })
        
        # 루프 내 객체 생성
        for stmt in ast.walk(node):
            if isinstance(stmt, ast.Call):
                if (isinstance(stmt.func, ast.Name) and 
                    stmt.func.id in ['list', 'dict', 'set', 'tuple']):
                    self.performance_issues.append({
                        "type": "object_creation_in_loop",
                        "severity": "low",
                        "line": stmt.lineno,
                        "message": "Object creation inside loop - consider moving outside"
                    })
                    break
        
        self.generic_visit(node)
    
    def visit_ListComp(self, node):
        # 중첩된 리스트 컴프리헨션
        nested_comps = len([n for n in ast.walk(node) if isinstance(n, ast.ListComp) and n != node])
        if nested_comps > 0:
            self.performance_issues.append({
                "type": "nested_comprehension",
                "severity": "medium",
                "line": node.lineno,
                "message": "Nested list comprehension - consider simplification"
            })
        
        self.generic_visit(node)
    
    def visit_Call(self, node):
        # len() 호출이 루프 조건에 있는지 확인
        if isinstance(node.func, ast.Name) and node.func.id == 'len':
            # 상위 노드가 비교 연산자인지 확인
            # 이는 간단한 예시이며, 실제로는 더 복잡한 분석이 필요
            pass
        
        self.generic_visit(node)

try:
    with open("$file", "r") as f:
        content = f.read()
        tree = ast.parse(content)
    
    reviewer = PerformanceReviewer()
    reviewer.visit(tree)
    
    result = {
        "file": "$file",
        "timestamp": "$(date -Iseconds)",
        "total_performance_issues": len(reviewer.performance_issues),
        "performance_issues": reviewer.performance_issues,
        "performance_score": max(0, 100 - len(reviewer.performance_issues) * 5)
    }
    
    print(json.dumps(result, indent=2))
    
except Exception as e:
    print(json.dumps({"error": str(e)}, indent=2))
EOF
    
    log_info "Performance review completed"
}

run_style_review() {
    local file="$1"
    local output_dir="$2"
    
    log_info "Running style review on: $file"
    
    # Ruff를 사용한 스타일 검사
    if command -v ruff &> /dev/null; then
        ruff check "$file" --format=json --output-file="$output_dir/style_issues.json" || true
    fi
    
    # 추가 스타일 검사
    python3 << EOF > "$output_dir/style_review.json"
import ast
import json
import re

class StyleReviewer(ast.NodeVisitor):
    def __init__(self):
        self.style_issues = []
        self.line_count = 0
    
    def check_line_length(self, content):
        lines = content.split('\n')
        self.line_count = len(lines)
        
        for i, line in enumerate(lines, 1):
            if len(line) > 88:  # Black's default
                self.style_issues.append({
                    "type": "line_length",
                    "severity": "low",
                    "line": i,
                    "message": f"Line too long ({len(line)} > 88 characters)"
                })
    
    def visit_FunctionDef(self, node):
        # 함수 사이 빈 줄 (간단한 검사)
        # 실제로는 더 정교한 분석이 필요
        
        self.generic_visit(node)
    
    def visit_Import(self, node):
        # import 정렬 (간단한 검사)
        # 실제로는 isort와 같은 도구 사용 권장
        
        self.generic_visit(node)

try:
    with open("$file", "r") as f:
        content = f.read()
        tree = ast.parse(content)
    
    reviewer = StyleReviewer()
    reviewer.check_line_length(content)
    reviewer.visit(tree)
    
    result = {
        "file": "$file",
        "timestamp": "$(date -Iseconds)",
        "total_style_issues": len(reviewer.style_issues),
        "style_issues": reviewer.style_issues,
        "statistics": {
            "total_lines": reviewer.line_count,
            "long_lines": len([i for i in reviewer.style_issues if i["type"] == "line_length"])
        }
    }
    
    print(json.dumps(result, indent=2))
    
except Exception as e:
    print(json.dumps({"error": str(e)}, indent=2))
EOF
    
    log_info "Style review completed"
}

generate_review_summary() {
    local input_file="$1"
    local output_dir="$2"
    local focus_area="$3"
    
    log_info "Generating review summary"
    
    python3 << EOF > "$output_dir/review_summary.json"
import json
import os
from datetime import datetime

def load_json_file(filepath):
    try:
        with open(filepath) as f:
            return json.load(f)
    except:
        return {}

# 각 리뷰 결과 로드
functionality = load_json_file("$output_dir/functionality_review.json")
security = load_json_file("$output_dir/security_review.json")
performance = load_json_file("$output_dir/performance_review.json")
style = load_json_file("$output_dir/style_review.json")

# 점수 계산
functionality_score = max(0, 100 - functionality.get("total_issues", 0) * 5)
security_score = security.get("security_score", 100)
performance_score = performance.get("performance_score", 100)
style_score = max(0, 100 - style.get("total_style_issues", 0) * 2)

# 전체 점수 (가중 평균)
weights = {"functionality": 0.3, "security": 0.3, "performance": 0.2, "style": 0.2}
overall_score = (
    functionality_score * weights["functionality"] +
    security_score * weights["security"] +
    performance_score * weights["performance"] +
    style_score * weights["style"]
)

# 중요 이슈 (반드시 수정 필요)
critical_issues = []
for issue in security.get("security_issues", []):
    if issue.get("severity") == "high":
        critical_issues.append(issue)

for issue in functionality.get("issues", []):
    if issue.get("severity") == "high":
        critical_issues.append(issue)

# 개선 제안
improvements = []
if functionality_score < 80:
    improvements.append("Improve function documentation and naming conventions")
if security_score < 90:
    improvements.append("Address security vulnerabilities immediately")
if performance_score < 80:
    improvements.append("Optimize nested loops and algorithm complexity")
if style_score < 90:
    improvements.append("Follow PEP 8 style guidelines more consistently")

# 칭찬할 점
praise_points = []
if security_score >= 95:
    praise_points.append("Excellent security practices")
if functionality_score >= 90:
    praise_points.append("Well-structured and documented code")
if performance_score >= 90:
    praise_points.append("Efficient algorithm implementation")
if style_score >= 95:
    praise_points.append("Consistent code style")

summary = {
    "file": "$input_file",
    "timestamp": datetime.now().isoformat(),
    "focus_area": "$focus_area",
    "overall_score": round(overall_score, 1),
    "detailed_scores": {
        "functionality": round(functionality_score, 1),
        "security": round(security_score, 1),
        "performance": round(performance_score, 1),
        "style": round(style_score, 1)
    },
    "total_issues": {
        "critical": len(critical_issues),
        "functionality": functionality.get("total_issues", 0),
        "security": security.get("total_security_issues", 0),
        "performance": performance.get("total_performance_issues", 0),
        "style": style.get("total_style_issues", 0)
    },
    "critical_issues": critical_issues,
    "improvement_suggestions": improvements,
    "praise_points": praise_points,
    "recommendation": "APPROVE" if overall_score >= 80 and len(critical_issues) == 0 else "NEEDS_CHANGES"
}

print(json.dumps(summary, indent=2))
EOF
    
    log_info "Review summary generated"
}

# 메인 코드 리뷰 함수
review_code() {
    local input_file="$1"
    local focus_area="${2:-all}"
    local strict_mode="${3:-false}"
    
    show_progress 1 6 "Validating input file"
    validate_input_file "$input_file"
    
    case "$focus_area" in
        "security")
            show_progress 2 6 "Running security review"
            run_security_review "$input_file" "$AGENT_OUTPUT_DIR"
            show_progress 6 6 "Security review completed"
            ;;
        "performance")
            show_progress 2 6 "Running performance review"
            run_performance_review "$input_file" "$AGENT_OUTPUT_DIR"
            show_progress 6 6 "Performance review completed"
            ;;
        "style")
            show_progress 2 6 "Running style review"
            run_style_review "$input_file" "$AGENT_OUTPUT_DIR"
            show_progress 6 6 "Style review completed"
            ;;
        "all"|*)
            show_progress 2 6 "Running functionality review"
            run_functionality_review "$input_file" "$AGENT_OUTPUT_DIR"
            
            show_progress 3 6 "Running security review"
            run_security_review "$input_file" "$AGENT_OUTPUT_DIR"
            
            show_progress 4 6 "Running performance review"
            run_performance_review "$input_file" "$AGENT_OUTPUT_DIR"
            
            show_progress 5 6 "Running style review"
            run_style_review "$input_file" "$AGENT_OUTPUT_DIR"
            
            show_progress 6 6 "Generating review summary"
            generate_review_summary "$input_file" "$AGENT_OUTPUT_DIR" "$focus_area"
            ;;
    esac
    
    # 전체 결과 요약 생성
    cat > "$AGENT_OUTPUT_DIR/summary.json" << EOF
{
    "agent": "$AGENT_NAME",
    "input_file": "$input_file",
    "focus_area": "$focus_area",
    "strict_mode": $strict_mode,
    "timestamp": "$(date -Iseconds)",
    "status": "completed",
    "output_files": {
        "functionality_review": "functionality_review.json",
        "security_review": "security_review.json", 
        "performance_review": "performance_review.json",
        "style_review": "style_review.json",
        "review_summary": "review_summary.json"
    }
}
EOF
    
    log_info "Code review completed successfully"
}

# 메인 함수
main() {
    local input_file=""
    local focus_area="all"
    local strict_mode=false
    local context_file=""
    
    # 옵션 파싱
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                export JAE_LOG_LEVEL=$LOG_DEBUG
                shift
                ;;
            -o|--output)
                export JAE_OUTPUT_DIR="$2"
                shift 2
                ;;
            --context)
                context_file="$2"
                shift 2
                ;;
            --strict)
                strict_mode=true
                shift
                ;;
            --focus)
                focus_area="$2"
                if [[ ! "$focus_area" =~ ^(security|performance|style|all)$ ]]; then
                    error_exit "Invalid focus area: $focus_area"
                fi
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
    
    # 컨텍스트 파일 검증
    if [[ -n "$context_file" ]]; then
        validate_input_file "$context_file"
    fi
    
    # 필수 도구 확인
    check_required_tools "${REQUIRED_TOOLS[@]}"
    
    # 에이전트 초기화
    init_agent "$AGENT_NAME" "$input_file"
    
    # 트랩 설정
    trap 'cleanup_agent "error" "Agent interrupted or failed"' INT TERM ERR
    
    # 메인 작업 수행
    review_code "$input_file" "$focus_area" "$strict_mode"
    
    # 성공적으로 완료
    cleanup_agent "success" "Code review completed successfully"
}

# 스크립트가 직접 실행될 때만 main 함수 호출
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi