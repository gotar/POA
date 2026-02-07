import { Controller } from "@hotwired/stimulus"
import Prism from "prismjs"

// Import core Prism CSS - use the full path in vendor
// import "prismjs/themes/prism.css" // Removed - causes module resolution errors

// Import common languages
import "prismjs/components/prism-javascript"
import "prismjs/components/prism-ruby"
import "prismjs/components/prism-python"
import "prismjs/components/prism-sql"
import "prismjs/components/prism-json"
import "prismjs/components/prism-markup" // XML/HTML
import "prismjs/components/prism-css"
import "prismjs/components/prism-bash"
import "prismjs/components/prism-yaml"

// Add CSS manually since import fails
const prismCSS = `
code[class*="language-"],
pre[class*="language-"] {
  color: #f8f8f2;
  background: none;
  text-shadow: 0 1px rgba(0, 0, 0, 0.3);
  font-family: Consolas, Monaco, 'Andale Mono', 'Ubuntu Mono', monospace;
  text-align: left;
  white-space: pre;
  word-spacing: normal;
  word-break: normal;
  word-wrap: normal;
  line-height: 1.5;
  tab-size: 4;
  hyphens: none;
}

pre[class*="language-"] {
  padding: 1em;
  margin: .5em 0;
  overflow: auto;
  border-radius: 0.3em;
  background: #2d2d2d;
}

:not(pre) > code[class*="language-"] {
  padding: .1em;
  border-radius: .3em;
  white-space: normal;
  background: #2d2d2d;
}

.token.comment,
.token.prolog,
.token.doctype,
.token.cdata {
  color: #6272a4;
}

.token.punctuation {
  color: #f8f8f2;
}

.token.namespace {
  opacity: .7;
}

.token.property,
.token.tag,
.token.constant,
.token.symbol,
.token.deleted {
  color: #ff79c6;
}

.token.boolean,
.token.number {
  color: #bd93f9;
}

.token.selector,
.token.attr-name,
.token.string,
.token.char,
.token.builtin,
.token.inserted {
  color: #50fa7b;
}

.token.operator,
.token.entity,
.token.url,
.language-css .token.string,
.style .token.string,
.token.variable {
  color: #f8f8f2;
}

.token.atrule,
.token.attr-value,
.token.function,
.token.class-name {
  color: #f1fa8c;
}

.token.keyword {
  color: #8be9fd;
}

.token.regex,
.token.important {
  color: #ffb86c;
}
`

// Inject Prism CSS dynamically
if (typeof document !== 'undefined') {
  const styleId = 'prism-highlight-css'
  if (!document.getElementById(styleId)) {
    const style = document.createElement('style')
    style.id = styleId
    style.textContent = prismCSS
    document.head.appendChild(style)
  }
}

// Syntax highlighting for code blocks
export default class extends Controller {
  connect() {
    // Wait a bit for content to load, then highlight
    setTimeout(() => {
      this.highlightCodeBlocks()
    }, 100)

    // Also highlight on turbo frame loads
    document.addEventListener('turbo:frame-load', () => {
      setTimeout(() => {
        this.highlightCodeBlocks()
      }, 50)
    })
  }

  highlightCodeBlocks() {
    // Check if Prism is available
    if (typeof Prism === 'undefined') {
      console.warn('Prism.js not available, skipping syntax highlighting')
      return
    }

    try {
      // Find all code blocks that haven't been highlighted yet
      const codeBlocks = this.element.querySelectorAll('pre code:not(.language-markup):not(.language-none)')

      codeBlocks.forEach((block) => {
        // Only highlight if not already highlighted
        if (!block.classList.contains('highlighted')) {
          Prism.highlightElement(block)
          block.classList.add('highlighted')
        }
      })
    } catch (error) {
      console.warn('Syntax highlighting failed:', error)
    }
  }
}