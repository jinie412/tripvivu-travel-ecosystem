import os

root_dir = r'c:\Users\PC\Documents\QNHU\US\TN\Project\GPTravelAdvisorMobile\lib'

for root, dirs, files in os.walk(root_dir):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            new_content = content.replace('constants/app_colors.dart', 'theme/app_colors.dart')
            
            if new_content != content:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f'Updated: {path}')
