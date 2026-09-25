import re

with open('lib/screens/codes_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

with open('replacement.txt', 'r', encoding='utf-8') as f:
    new_card = f.read()

pattern = re.compile(r'return Card\(.*?\);\s*},\s*\);\s*}\s*}\s*', re.DOTALL)
match = pattern.search(content)

if match:
    # Need to keep the listview closing brackets
    new_content = content[:match.start()] + new_card + """
            },
          );
        },
      ),
    );
  }
}
"""
    with open('lib/screens/codes_screen.dart', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Replaced successfully.")
else:
    print("Could not find the Card block.")
