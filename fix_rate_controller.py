import sys
with open('l:/Total App/totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Check if the old text exists
old = 'text: product.price.toStringAsFixed(0),'
new = 'text: existingCartItem != null ? existingCartItem.rate.toStringAsFixed(0) : product.price.toStringAsFixed(0),'

if old in content:
    content = content.replace(old, new)
    with open('l:/Total App/totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart', 'w', encoding='utf-8') as f:
        f.write(content)
    print('SUCCESS: Updated rateController')
else:
    print('OLD TEXT NOT FOUND')
    # Show what we have around rateController
    idx = content.find('final rateController')
    if idx >= 0:
        print('Found rateController at:', idx)
        print('Context:', content[idx:idx+200])
