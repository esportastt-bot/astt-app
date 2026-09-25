import re

with open('lib/screens/codes_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

pattern = re.compile(r'\s*const SizedBox\(height: 24\),\s*ElevatedButton\.icon\(.*?\}\,\s*\)', re.DOTALL)
content = pattern.sub('', content)

with open('lib/screens/codes_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)

