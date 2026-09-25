import re
with open('index.html', 'r', encoding='utf-8') as f:
    content = f.read()
scripts = re.findall(r'<script>(.*?)</script>', content, re.DOTALL)
with open('temp2.js', 'w', encoding='utf-8') as f:
    for s in scripts:
        f.write(s)
