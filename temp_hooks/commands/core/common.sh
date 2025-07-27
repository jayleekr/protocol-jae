#!/bin/bash
# JAE Common Utilities
# 모든 에이전트 스크립트에서 사용하는 공통 함수들

set -euo pipefail

# 색상 정의
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m' # No Color

# 로그 레벨
readonly LOG_DEBUG=0
readonly LOG_INFO=1
readonly LOG_WARN=2
readonly LOG_ERROR=3

# 환경 변수 설정
export JAE_COMMANDS_DIR="${JAE_COMMANDS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export JAE_CONFIG_DIR="${JAE_CONFIG_DIR:-$JAE_COMMANDS_DIR/config}"
export JAE_TOOLS_DIR="${JAE_TOOLS_DIR:-$JAE_COMMANDS_DIR/tools}"
export JAE_OUTPUT_DIR="${JAE_OUTPUT_DIR:-./jae-output}"
export JAE_TEMP_DIR="${JAE_TEMP_DIR:-/tmp/jae-workflow}"
export JAE_LOG_LEVEL="${JAE_LOG_LEVEL:-$LOG_INFO}"

# 로깅 함수
log() {
    local level=$1
    shift
    local message="$*"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    if [[ $level -ge $JAE_LOG_LEVEL ]]; then
        case $level in
            $LOG_DEBUG) echo -e "${CYAN}[DEBUG]${NC} $timestamp: $message" ;;
            $LOG_INFO)  echo -e "${GREEN}[INFO]${NC}  $timestamp: $message" ;;
            $LOG_WARN)  echo -e "${YELLOW}[WARN]${NC}  $timestamp: $message" ;;
            $LOG_ERROR) echo -e "${RED}[ERROR]${NC} $timestamp: $message" >&2 ;;
        esac
    fi
}

log_debug() { log $LOG_DEBUG "$@"; }
log_info()  { log $LOG_INFO "$@"; }
log_warn()  { log $LOG_WARN "$@"; }
log_error() { log $LOG_ERROR "$@"; }

# 에러 처리
error_exit() {
    log_error "$1"
    exit "${2:-1}"
}

# 필수 도구 확인
check_required_tools() {
    local tools=("$@")
    local missing_tools=()
    
    for tool in "${tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error_exit "Missing required tools: ${missing_tools[*]}"
    fi
}

# 디렉토리 생성
ensure_dir() {
    local dir="$1"
    if [[ ! -d "$dir" ]]; then
        log_debug "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

# YAML 파싱 함수 (yq 사용)
get_yaml_value() {
    local file="$1"
    local key="$2"
    
    if [[ ! -f "$file" ]]; then
        error_exit "YAML file not found: $file"
    fi
    
    if command -v yq &> /dev/null; then
        yq eval "$key" "$file"
    else
        # yq가 없으면 간단한 grep 기반 파싱 (제한적)
        grep "^$key:" "$file" | cut -d':' -f2- | sed 's/^ *//'
    fi
}

# 에이전트 설정 로드
load_agent_config() {
    local agent_name="$1"
    local config_file="$JAE_CONFIG_DIR/agents.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        error_exit "Agent config file not found: $config_file"
    fi
    
    # 에이전트별 설정 추출 (readonly 변수가 이미 설정된 경우 건너뛰기)
    if [[ -z "${AGENT_NAME:-}" ]]; then
        export AGENT_NAME="$agent_name"
    fi
    export AGENT_PHASE=$(get_yaml_value "$config_file" ".agents.${agent_name}.phase")
    export AGENT_ORDER=$(get_yaml_value "$config_file" ".agents.${agent_name}.order")
    export AGENT_TIMEOUT=$(get_yaml_value "$config_file" ".agents.${agent_name}.timeout")
    export AGENT_ROLE=$(get_yaml_value "$config_file" ".agents.${agent_name}.role")
    
    log_debug "Loaded config for agent: $agent_name (Phase $AGENT_PHASE, Order $AGENT_ORDER)"
}

# 도구 설정 로드
load_tool_config() {
    local tool_name="$1"
    local config_file="$JAE_CONFIG_DIR/tools.yaml"
    
    if [[ ! -f "$config_file" ]]; then
        error_exit "Tool config file not found: $config_file"
    fi
    
    # 도구 설정 검증
    if ! get_yaml_value "$config_file" ".tools.${tool_name}" &> /dev/null; then
        error_exit "Tool configuration not found: $tool_name"
    fi
    
    log_debug "Tool config available for: $tool_name"
}

# 입력 파일 검증
validate_input_file() {
    local file="$1"
    
    if [[ ! -f "$file" ]]; then
        error_exit "Input file not found: $file"
    fi
    
    if [[ ! -r "$file" ]]; then
        error_exit "Input file not readable: $file"
    fi
    
    log_debug "Input file validated: $file"
}

# 출력 디렉토리 준비
prepare_output_dir() {
    local agent_name="$1"
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    
    export AGENT_OUTPUT_DIR="$JAE_OUTPUT_DIR/${agent_name}_${timestamp}"
    ensure_dir "$AGENT_OUTPUT_DIR"
    
    log_info "Output directory: $AGENT_OUTPUT_DIR"
}

# 작업 컨텍스트 저장
save_context() {
    local context_file="$AGENT_OUTPUT_DIR/context.json"
    
    cat > "$context_file" << EOF
{
    "agent": "$AGENT_NAME",
    "timestamp": "$(date -Iseconds)",
    "phase": $AGENT_PHASE,
    "order": $AGENT_ORDER,
    "input_files": $(printf '%s\n' "${INPUT_FILES[@]:-}" | jq -R . | jq -s .),
    "environment": {
        "pwd": "$(pwd)",
        "user": "$USER",
        "git_branch": "$(git branch --show-current 2>/dev/null || echo 'unknown')",
        "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
    }
}
EOF
    
    log_debug "Context saved: $context_file"
}

# 결과 메타데이터 저장
save_result_metadata() {
    local status="$1"
    local message="$2"
    local result_file="$AGENT_OUTPUT_DIR/result.json"
    
    cat > "$result_file" << EOF
{
    "agent": "$AGENT_NAME",
    "status": "$status",
    "message": "$message",
    "timestamp": "$(date -Iseconds)",
    "duration_seconds": $(($(date +%s) - ${START_TIME:-$(date +%s)})),
    "output_files": $(find "$AGENT_OUTPUT_DIR" -type f -name "*.json" -o -name "*.py" -o -name "*.md" | jq -R . | jq -s .)
}
EOF
    
    log_info "Result metadata saved: $result_file"
}

# 진행 상황 표시
show_progress() {
    local current="$1"
    local total="$2"
    local task="$3"
    
    local percent=$((current * 100 / total))
    local bar_length=50
    local filled_length=$((percent * bar_length / 100))
    
    printf "\r${BLUE}[%s] %3d%% " "$AGENT_NAME" "$percent"
    printf "%*s" "$filled_length" | tr ' ' '='
    printf "%*s" $((bar_length - filled_length)) | tr ' ' '-'
    printf "${NC} %s" "$task"
    
    if [[ $current -eq $total ]]; then
        echo ""
    fi
}

# 에이전트 상태 업데이트
update_agent_status() {
    local status="$1"
    local message="${2:-}"
    local status_file="$JAE_TEMP_DIR/agent_status_${AGENT_NAME}.json"
    
    ensure_dir "$JAE_TEMP_DIR"
    
    cat > "$status_file" << EOF
{
    "agent": "$AGENT_NAME",
    "status": "$status",
    "message": "$message",
    "timestamp": "$(date -Iseconds)",
    "pid": $$,
    "output_dir": "$AGENT_OUTPUT_DIR"
}
EOF
    
    log_debug "Agent status updated: $status"
}

# 다른 에이전트의 출력 찾기
find_agent_output() {
    local agent_name="$1"
    local output_pattern="$JAE_OUTPUT_DIR/${agent_name}_*"
    
    # 가장 최근 출력 디렉토리 찾기
    local latest_dir=$(ls -dt $output_pattern 2>/dev/null | head -n1)
    
    if [[ -n "$latest_dir" && -d "$latest_dir" ]]; then
        echo "$latest_dir"
    else
        log_warn "No output found for agent: $agent_name"
        return 1
    fi
}

# 의존성 확인
check_dependencies() {
    local agent_name="$1"
    local config_file="$JAE_CONFIG_DIR/agents.yaml"
    
    # 의존성 에이전트 목록 가져오기
    local dependencies=$(get_yaml_value "$config_file" ".agents.${agent_name}.dependencies[]" 2>/dev/null || echo "")
    
    if [[ -n "$dependencies" ]]; then
        log_info "Checking dependencies for $agent_name: $dependencies"
        
        while IFS= read -r dep_agent; do
            if [[ -n "$dep_agent" ]]; then
                local dep_output=$(find_agent_output "$dep_agent")
                if [[ $? -ne 0 ]]; then
                    error_exit "Dependency not satisfied: $dep_agent output not found"
                fi
                log_debug "Dependency satisfied: $dep_agent -> $dep_output"
            fi
        done <<< "$dependencies"
    fi
}

# 초기화 함수
init_agent() {
    local agent_name="$1"
    shift
    export INPUT_FILES=("$@")
    export START_TIME=$(date +%s)
    
    log_info "Initializing JAE agent: $agent_name"
    
    # 설정 로드
    load_agent_config "$agent_name"
    
    # 출력 디렉토리 준비
    prepare_output_dir "$agent_name"
    
    # 의존성 확인
    check_dependencies "$agent_name"
    
    # 컨텍스트 저장
    save_context
    
    # 상태 업데이트
    update_agent_status "running" "Agent initialized"
    
    log_info "Agent $agent_name initialized successfully"
}

# 정리 함수
cleanup_agent() {
    local status="${1:-success}"
    local message="${2:-Agent completed successfully}"
    
    # 결과 메타데이터 저장
    save_result_metadata "$status" "$message"
    
    # 상태 업데이트
    update_agent_status "$status" "$message"
    
    if [[ "$status" == "success" ]]; then
        log_info "Agent $AGENT_NAME completed successfully"
    else
        log_error "Agent $AGENT_NAME failed: $message"
    fi
}

# 도구 실행 헬퍼
run_tool() {
    local tool_name="$1"
    shift
    local args=("$@")
    
    log_debug "Running tool: $tool_name with args: ${args[*]}"
    
    # 도구 설정 로드
    load_tool_config "$tool_name"
    
    # 도구별 실행 로직은 각 에이전트에서 구현
    log_info "Tool $tool_name execution delegated to agent"
}