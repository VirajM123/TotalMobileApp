import re

with open('l:/Total App/totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Remove duplicate addToCart method - find and remove using simpler pattern
# Look for the comment and the method that follows
pattern = r'// Overload for String \(productId\) - for backward compatibility\n  void addToCart\(String productId, \{int quantity = 1\}\) \{\n    setState\(\(\) \{\n      _cart\[productId\] = \(_cart\[productId\] \?\? 0\) \+ quantity;\n    \}\);\n  \}\n\n'
content = re.sub(pattern, '', content)

with open('l:/Total App/totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Done')
