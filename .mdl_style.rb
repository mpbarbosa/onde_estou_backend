# Enable all rules, then override below
all

# Disable line-length check — technical docs with ARNs, URLs, and table rows
# cannot reasonably comply with the 80-char default.
exclude_rule 'MD013'

# Allow sequential ordered-list numbering (1. 2. 3.) rather than requiring all 1.
rule 'MD029', :style => :ordered

# Allow duplicate headings when they appear under different parent sections.
# API docs legitimately repeat sub-headings like "Response — 200 OK" per endpoint.
rule 'MD024', :allow_different_nesting => true
