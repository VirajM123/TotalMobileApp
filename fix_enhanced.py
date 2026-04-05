import os

# Read the file
file_path = r'l:\Total App\totalsolution\lib\screens\salesman\salesman_dashboard_enhanced.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the rateController initialization
old_text = "final rateController = TextEditingController(\n      text: product.price.toStringAsFixed(0),"

new_text = "final rateController = TextEditingController(\n      text: existingCartItem != null ? existingCartItem.rate.toStringAsFixed(0) : product.price.toStringAsFixed(0),"

if old_text in content:
    content = content.replace(old_text, new_text)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("SUCCESS: Updated rateController")
else:
    print("ERROR: Old text not found")
    # Let's find what we have
    idx = content.find('final rateController')
    if idx >= 0:
        print("Found at:", idx)
        print("Context:", repr(content[idx:idx+150]))
