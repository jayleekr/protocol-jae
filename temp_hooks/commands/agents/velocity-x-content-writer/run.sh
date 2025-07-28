#!/bin/bash
#=============================================================================
# VELOCITY-X Content Writer Agent
# Technical content writing and markdown generation specialist
#=============================================================================

set -euo pipefail

# Script directory and paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"
AGENT_NAME="velocity-x-content-writer"

# Load common utilities
source "${SCRIPT_DIR}/../../core/common.sh"

#=============================================================================
# Agent-specific Functions
#=============================================================================

generate_chapter_outline() {
    local topic="$1"
    local output_file="$2"
    
    log "INFO" "Generating chapter outline for: $topic"
    
    cat > "$output_file" << EOF
# Chapter Outline: $topic

## 1. Introduction
- Context and background
- Learning objectives
- Prerequisites

## 2. Core Concepts
- Key terminology
- Fundamental principles
- Theoretical foundation

## 3. Practical Implementation
- Step-by-step guide
- Code examples
- Best practices

## 4. Advanced Topics
- Edge cases
- Performance considerations
- Common pitfalls

## 5. Summary
- Key takeaways
- Further reading
- Exercises
EOF
}

create_markdown_content() {
    local outline_file="$1"
    local reference_dir="$2"
    local output_file="$3"
    
    log "INFO" "Creating markdown content from outline"
    
    # Extract chapter title
    local chapter_title=$(grep "^# Chapter Outline:" "$outline_file" | sed 's/# Chapter Outline: //')
    
    # Generate content header
    cat > "$output_file" << EOF
# $chapter_title

> *"The best way to predict the future is to invent it." - Alan Kay*

## Overview

This chapter explores the fundamental concepts and practical applications of $chapter_title in the context of agentic development workflows.

EOF

    # Add content sections based on outline
    while IFS= read -r line; do
        if [[ $line =~ ^##[[:space:]](.+) ]]; then
            echo -e "\n$line\n" >> "$output_file"
            
            # Add placeholder content for each section
            case "${BASH_REMATCH[1]}" in
                "1. Introduction")
                    echo "In modern software development, understanding $chapter_title is crucial for building robust and scalable systems. This section provides the foundational knowledge needed to master these concepts." >> "$output_file"
                    ;;
                "2. Core Concepts")
                    echo "Let's dive into the essential concepts that form the backbone of $chapter_title:" >> "$output_file"
                    echo -e "\n### Key Terminology\n" >> "$output_file"
                    echo "- **Agent**: An autonomous entity that performs specific tasks" >> "$output_file"
                    echo "- **Workflow**: A sequence of coordinated agent actions" >> "$output_file"
                    echo "- **Pipeline**: An automated process for continuous integration" >> "$output_file"
                    ;;
                "3. Practical Implementation")
                    echo "Now let's see how these concepts translate into real-world applications:" >> "$output_file"
                    echo -e "\n\`\`\`python\n# Example implementation\nclass AgentWorkflow:\n    def __init__(self):\n        self.agents = []\n    \n    def add_agent(self, agent):\n        self.agents.append(agent)\n    \n    def execute(self):\n        for agent in self.agents:\n            agent.run()\n\`\`\`\n" >> "$output_file"
                    ;;
                "4. Advanced Topics")
                    echo "For experienced practitioners, consider these advanced aspects:" >> "$output_file"
                    echo -e "\n### Performance Optimization\n" >> "$output_file"
                    echo "When scaling agentic workflows, consider:" >> "$output_file"
                    echo "1. Parallel execution strategies" >> "$output_file"
                    echo "2. Resource allocation optimization" >> "$output_file"
                    echo "3. Caching and memoization techniques" >> "$output_file"
                    ;;
                "5. Summary")
                    echo "In this chapter, we've covered the essential aspects of $chapter_title. The key takeaways are:" >> "$output_file"
                    echo -e "\n✅ Understanding the fundamental concepts" >> "$output_file"
                    echo "✅ Implementing practical solutions" >> "$output_file"
                    echo "✅ Applying best practices" >> "$output_file"
                    echo "✅ Avoiding common pitfalls" >> "$output_file"
                    ;;
            esac
        fi
    done < "$outline_file"
    
    # Add references if available
    if [[ -d "$reference_dir" ]] && [[ -n "$(ls -A "$reference_dir" 2>/dev/null)" ]]; then
        echo -e "\n## References\n" >> "$output_file"
        for ref in "$reference_dir"/*.md; do
            if [[ -f "$ref" ]]; then
                local ref_name=$(basename "$ref" .md)
                echo "- [$ref_name](references/$(basename "$ref"))" >> "$output_file"
            fi
        done
    fi
}

validate_markdown() {
    local content_file="$1"
    local report_file="$2"
    
    log "INFO" "Validating markdown content"
    
    local validation_report="{
  \"file\": \"$content_file\",
  \"timestamp\": \"$(date -u +"%Y-%m-%dT%H:%M:%SZ")\",
  \"checks\": {
    \"structure\": {
      \"has_title\": $(grep -q "^# " "$content_file" && echo "true" || echo "false"),
      \"has_sections\": $(grep -q "^## " "$content_file" && echo "true" || echo "false"),
      \"has_code_blocks\": $(grep -q '```' "$content_file" && echo "true" || echo "false")
    },
    \"content\": {
      \"word_count\": $(wc -w < "$content_file"),
      \"line_count\": $(wc -l < "$content_file"),
      \"heading_count\": $(grep -c "^#" "$content_file" || echo 0)
    },
    \"quality\": {
      \"has_overview\": $(grep -q "## Overview" "$content_file" && echo "true" || echo "false"),
      \"has_examples\": $(grep -q '```' "$content_file" && echo "true" || echo "false"),
      \"has_summary\": $(grep -q "## Summary" "$content_file" && echo "true" || echo "false")
    }
  }
}"
    
    echo "$validation_report" > "$report_file"
}

generate_metadata() {
    local content_file="$1"
    local metadata_file="$2"
    
    log "INFO" "Generating content metadata"
    
    local title=$(grep "^# " "$content_file" | head -1 | sed 's/^# //')
    local word_count=$(wc -w < "$content_file")
    local estimated_reading_time=$((word_count / 200)) # Assuming 200 words per minute
    
    cat > "$metadata_file" << EOF
{
  "title": "$title",
  "created_at": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "author": "VELOCITY-X Content Writer",
  "language": "en",
  "statistics": {
    "word_count": $word_count,
    "estimated_reading_time_minutes": $estimated_reading_time,
    "sections": $(grep -c "^## " "$content_file" || echo 0),
    "code_blocks": $(grep -c '```' "$content_file" | awk '{print $1/2}' || echo 0)
  },
  "tags": ["VELOCITY-X", "agentic-development", "technical-writing"],
  "status": "draft"
}
EOF
}

#=============================================================================
# Main Execution
#=============================================================================

main() {
    local topic="${1:-}"
    local reference_dir="${2:-}"
    
    # Initialize agent
    init_agent "$AGENT_NAME"
    
    # Validate inputs
    if [[ -z "$topic" ]]; then
        log "ERROR" "Topic is required"
        echo "Usage: $0 <topic> [reference_dir]"
        exit 1
    fi
    
    # Prepare output directory
    prepare_output_dir "$AGENT_NAME"
    
    log "INFO" "Starting content generation for topic: $topic"
    
    # Generate chapter outline
    local outline_file="$AGENT_OUTPUT_DIR/chapter_outline.md"
    generate_chapter_outline "$topic" "$outline_file"
    
    # Create markdown content
    local content_file="$AGENT_OUTPUT_DIR/chapter_content.md"
    create_markdown_content "$outline_file" "${reference_dir:-/dev/null}" "$content_file"
    
    # Validate content
    local validation_report="$AGENT_OUTPUT_DIR/validation_report.json"
    validate_markdown "$content_file" "$validation_report"
    
    # Generate metadata
    local metadata_file="$AGENT_OUTPUT_DIR/metadata.json"
    generate_metadata "$content_file" "$metadata_file"
    
    # Create summary
    local summary_file="$AGENT_OUTPUT_DIR/summary.json"
    cat > "$summary_file" << EOF
{
  "agent": "$AGENT_NAME",
  "status": "completed",
  "topic": "$topic",
  "outputs": {
    "outline": "chapter_outline.md",
    "content": "chapter_content.md",
    "validation": "validation_report.json",
    "metadata": "metadata.json"
  },
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
}
EOF
    
    log "SUCCESS" "Content generation completed"
    log "INFO" "Output directory: $AGENT_OUTPUT_DIR"
    
    # Display summary
    echo -e "\n📝 Content Generation Summary:"
    echo "Topic: $topic"
    echo "Word Count: $(jq -r '.statistics.word_count' "$metadata_file")"
    echo "Reading Time: $(jq -r '.statistics.estimated_reading_time_minutes' "$metadata_file") minutes"
    echo "Sections: $(jq -r '.statistics.sections' "$metadata_file")"
}

# Run main function
main "$@"