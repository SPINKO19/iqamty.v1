import os

filepath = r"c:\Users\14382\iqamty.v1\lib\src\components\app_sidebar.dart"
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

new_content = content.replace("withOpacity(", "withValues(alpha: ")

if new_content != content:
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
