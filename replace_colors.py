import os
import re

lib_dir = "lib"

replacements = [
    (r"Colors\.blue(?!Grey)", "const Color(0xFF1B4332)"),
    (r"Colors\.lightBlue(?!Grey)", "const Color(0xFFD8F3DC)"),
    (r"Colors\.blueAccent", "const Color(0xFF2D6A4F)"),
    (r"0xFF2196F3", "0xFF1B4332"),
    (r"0xFF1976D2", "0xFF1B4332"),
    (r"0xFF0EA5E9", "0xFF1B4332"),
    (r"0xFF3B82F6", "0xFF1B4332"),
    (r"0xFF42A5F5", "0xFF2D6A4F"),
    (r"0xFFBBDEFB", "0xFFD8F3DC"),
    (r"0xFFE3F2FD", "0xFFD8F3DC"),
    (r"0xFFEFF6FF", "0xFFD8F3DC"),
    (r"0xFF0284C7", "0xFF1B4332"),
    # Convert 'const const'
    (r"const\s+const\s+Color", "const Color"),
]

changed_files = 0
for root, dirs, files in os.walk(lib_dir):
    for filename in files:
        if filename.endswith(".dart"):
            filepath = os.path.join(root, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            
            new_content = content
            # Safe replacement for string values
            for pattern, repl in replacements:
                if repl.startswith("const Color"):
                    # if the user wrote "const Colors.blue", make sure we don't get "const const Color"
                    new_content = re.sub(r"const\s+" + pattern, repl, new_content)
                new_content = re.sub(pattern, repl, new_content)

            if new_content != content:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                changed_files += 1

print(f"Replaced colors in {changed_files} files.")
