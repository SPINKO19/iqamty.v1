import os

lib_dir = "lib"

changed_files = 0
for root, dirs, files in os.walk(lib_dir):
    for filename in files:
        if filename.endswith(".dart"):
            filepath = os.path.join(root, filename)
            with open(filepath, "r", encoding="utf-8") as f:
                content = f.read()
            
            new_content = content.replace("Appconst Color(0xFF1B4332)", "AppColors.blue")
            
            if new_content != content:
                with open(filepath, "w", encoding="utf-8") as f:
                    f.write(new_content)
                changed_files += 1

print(f"Fixed broken AppColors.blue in {changed_files} files.")
