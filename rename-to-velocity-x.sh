#!/bin/bash

# Script to rename JAE to VELOCITY-X throughout the project
# This script handles file content updates and file/directory renames

set -e

echo "Starting JAE to VELOCITY-X renaming process..."

# Create backup
echo "Creating backup..."
cp -r . ../agentic-workflow-backup-$(date +%Y%m%d_%H%M%S) 2>/dev/null || true

# Function to replace text in files
replace_in_files() {
    local search="$1"
    local replace="$2"
    echo "Replacing '$search' with '$replace' in all files..."
    
    # Find all text files and replace content
    find . -type f \
        -not -path "./.git/*" \
        -not -path "./node_modules/*" \
        -not -path "./venv/*" \
        -not -path "./__pycache__/*" \
        -not -name "*.pyc" \
        -not -name "*.pyo" \
        -not -name "*.so" \
        -not -name "*.dylib" \
        -not -name "*.png" \
        -not -name "*.jpg" \
        -not -name "*.jpeg" \
        -not -name "*.gif" \
        -not -name "*.ico" \
        -not -name "*.pdf" \
        -not -name "rename-to-velocity-x.sh" \
        -exec grep -l "$search" {} \; 2>/dev/null | while read -r file; do
        echo "  Updating: $file"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            sed -i '' "s/$search/$replace/g" "$file"
        else
            # Linux
            sed -i "s/$search/$replace/g" "$file"
        fi
    done
}

# Step 1: Replace content in files
echo "Step 1: Updating file contents..."
replace_in_files "JAE" "VELOCITY-X"
replace_in_files "Jae" "Velocity-X"
replace_in_files "jae-" "velocity-x-"

# Step 2: Rename files
echo "Step 2: Renaming files..."
find . -type f -name "*jae-*" -not -path "./.git/*" | while read -r file; do
    newfile=$(echo "$file" | sed 's/jae-/velocity-x-/g')
    echo "  Renaming: $file -> $newfile"
    mv "$file" "$newfile"
done

find . -type f -name "*JAE*" -not -path "./.git/*" | while read -r file; do
    newfile=$(echo "$file" | sed 's/JAE/VELOCITY-X/g')
    echo "  Renaming: $file -> $newfile"
    mv "$file" "$newfile"
done

# Step 3: Rename directories
echo "Step 3: Renaming directories..."
# Start from deepest directories first to avoid path issues
find . -type d -name "*jae*" -not -path "./.git/*" | sort -r | while read -r dir; do
    newdir=$(echo "$dir" | sed 's/jae/velocity-x/g')
    if [ "$dir" != "$newdir" ]; then
        echo "  Renaming: $dir -> $newdir"
        mv "$dir" "$newdir"
    fi
done

# Step 4: Update specific configuration files that might have special formatting
echo "Step 4: Updating configuration files..."

# Update package.json if it exists
if [ -f "package.json" ]; then
    echo "  Updating package.json..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/"name": ".*jae.*"/"name": "velocity-x"/g' package.json
    else
        sed -i 's/"name": ".*jae.*"/"name": "velocity-x"/g' package.json
    fi
fi

# Update pyproject.toml if it exists
if [ -f "pyproject.toml" ]; then
    echo "  Updating pyproject.toml..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/name = ".*jae.*"/name = "velocity-x"/g' pyproject.toml
    else
        sed -i 's/name = ".*jae.*"/name = "velocity-x"/g' pyproject.toml
    fi
fi

echo "Step 5: Verifying changes..."
# Show summary of changes
echo "Files still containing 'JAE':"
grep -r "JAE" . --exclude-dir=.git --exclude-dir=node_modules --exclude="rename-to-velocity-x.sh" 2>/dev/null | head -10 || echo "  None found"

echo "Files still containing 'jae-':"
grep -r "jae-" . --exclude-dir=.git --exclude-dir=node_modules --exclude="rename-to-velocity-x.sh" 2>/dev/null | head -10 || echo "  None found"

echo ""
echo "Renaming complete! Please review the changes and commit when ready."
echo "A backup was created in the parent directory."