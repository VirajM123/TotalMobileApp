import re

# Read the file
with open('l:/Total App/totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Update rateController to load from existing cart item
old_rate = '''    final rateController = TextEditingController(
      text: product.price.toStringAsFixed(0),
    );'''

new_rate = '''    final rateController = TextEditingController(
      text: existingCartItem != null 
          ? existingCartItem.rate.toStringAsFixed(0) 
          : product.price.toStringAsFixed(0),
    );'''

content = content.replace(old_rate, new_rate)

# Fix 2: Update schPerController and schAmtController to load from existing cart item
old_sch = '''    final schPerController = TextEditingController(text: '0');
    final schAmtController = TextEditingController(text: '0');'''

new_sch = '''    final schPerController = TextEditingController(
      text: existingCartItem != null ? existingCartItem.schPer.toString() : '0',
    );
    final schAmtController = TextEditingController(
      text: existingCartItem != null ? existingCartItem.schAmt.toString() : '0',
    );'''

content = content.replace(old_sch, new_sch)

# Write the file back
with open('l:/Total App/totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart', 'w', encoding='utf-8') as f:
    f.write(content)

print('Fix applied successfully!')
print('Updated:')
print('1. rateController - now loads from existingCartItem.rate')
print('2. schPerController - now loads from existingCartItem.schPer')
print('3. schAmtController - now loads from existingCartItem.schAmt')
