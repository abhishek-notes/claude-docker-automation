#!/bin/bash

# Multi-LLM Helper - Uses desktop apps, not APIs!

echo "🤖 Multi-LLM Task Helper"
echo "======================="
echo ""

TASK=${1:-"review"}
CONTENT=${2:-""}

case $TASK in
    "review")
        echo "📝 Code Review Request"
        echo ""
        echo "1. Open ChatGPT Desktop"
        echo "2. Paste this prompt:"
        echo ""
        echo "Please review this code for:"
        echo "- Security issues"
        echo "- Performance problems"
        echo "- Best practices"
        echo "- Potential bugs"
        echo ""
        echo "[Paste your code here]"
        ;;
        
    "test")
        echo "🧪 Test Generation Request"
        echo ""
        echo "1. Open Google AI Studio (FREE!)"
        echo "2. Paste this prompt:"
        echo ""
        echo "Generate comprehensive tests for this code:"
        echo "- Unit tests"
        echo "- Edge cases"
        echo "- Integration tests"
        echo ""
        echo "[Paste your code here]"
        ;;
        
    "document")
        echo "📚 Documentation Request"
        echo ""
        echo "1. Open Claude Desktop"
        echo "2. Paste this prompt:"
        echo ""
        echo "Create documentation for this code:"
        echo "- API documentation"
        echo "- Usage examples"
        echo "- Architecture overview"
        echo ""
        echo "[Paste your code here]"
        ;;
        
    *)
        echo "Usage: $0 {review|test|document}"
        ;;
esac
