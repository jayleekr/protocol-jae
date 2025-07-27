#!/bin/bash

# 실제 Claude Code와 연동하는 피드백 루프 스크립트

set -e

# 설정
TARGET_FILE="${1:-test_sample.py}"
MAX_ITERATIONS=3
WORK_DIR="claude-agents/work-real"
RESULTS_DIR="claude-agents/results-real/$(date +%Y%m%d_%H%M%S)"

# 색상
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 초기화
mkdir -p "$WORK_DIR" "$RESULTS_DIR"
cp "$TARGET_FILE" "$WORK_DIR/current_code.py"

echo -e "${BLUE}=== Claude Code 실제 연동 테스트 ===${NC}"
echo "대상 파일: $TARGET_FILE"
echo ""

# Claude에게 직접 요청
echo -e "${YELLOW}Claude Code에 분석 요청 중...${NC}"

# 프롬프트 파일 생성
cat > "$WORK_DIR/analyze_request.md" << 'EOF'
당신은 코드 품질 분석 전문가입니다. 
주어진 Python 코드를 분석하고 다음 JSON 형식으로 결과를 제공하세요:

```json
{
  "complexity_score": <McCabe complexity>,
  "issues": ["issue1", "issue2"],
  "quality_met": <true/false>,
  "improvements_needed": ["improvement1", "improvement2"]
}
```

복잡도 기준: McCabe < 10
품질 기준: 가독성, 중복 없음, 명확한 구조

분석할 코드:
EOF

cat "$TARGET_FILE" >> "$WORK_DIR/analyze_request.md"

echo -e "${BLUE}분석 프롬프트 생성 완료${NC}"
echo "위치: $WORK_DIR/analyze_request.md"
echo ""

# 사용자에게 Claude Code 실행 방법 안내
echo -e "${GREEN}=== Claude Code 실행 방법 ===${NC}"
echo "1. 다음 명령어를 실행하세요:"
echo "   cat $WORK_DIR/analyze_request.md | claude"
echo ""
echo "2. 또는 대화형으로:"
echo "   claude"
echo "   그 다음 프롬프트 내용을 붙여넣기"
echo ""
echo "3. 피드백 루프 시뮬레이션:"
echo "   - 복잡도가 10 이상이면 개선 요청"
echo "   - Claude가 개선한 코드로 다시 분석"
echo "   - 품질 기준 충족까지 반복"

# 데모용 응답 예시 생성
cat > "$RESULTS_DIR/example_response.json" << 'EOF'
{
  "complexity_score": 8,
  "issues": [],
  "quality_met": true,
  "improvements_needed": [],
  "improved_code": "# Claude가 개선한 코드가 여기 들어갑니다"
}
EOF

echo -e "\n${YELLOW}예시 응답 저장됨: $RESULTS_DIR/example_response.json${NC}"

# 실제 사용을 위한 헬퍼 스크립트 생성
cat > "$RESULTS_DIR/run_analysis.sh" << 'EOF'
#!/bin/bash
# Claude Code로 분석 실행하는 헬퍼 스크립트

echo "Claude Code에 분석 요청..."
# 실제로는: cat analyze_request.md | claude > result.json

echo "결과 파싱..."
# jq로 JSON 파싱하여 품질 확인

echo "피드백 적용..."
# 필요시 개선 요청 반복
EOF

chmod +x "$RESULTS_DIR/run_analysis.sh"

echo -e "\n${GREEN}✅ 준비 완료!${NC}"
echo "생성된 파일들:"
echo "- 분석 요청: $WORK_DIR/analyze_request.md"
echo "- 헬퍼 스크립트: $RESULTS_DIR/run_analysis.sh"
echo "- 예시 응답: $RESULTS_DIR/example_response.json"