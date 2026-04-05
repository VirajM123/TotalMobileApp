$content = Get-Content "l:/Total App/totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart" -Raw
# Remove the duplicate addToCart method
$content = $content -replace '(?s)// Overload for String \(productId\) - for backward compatibility\r?\n  void addToCart\(String productId, \{int quantity = 1\}\) \{\r?\n    setState\(\(\) \{\r?\n      _cart\[productId\] = \(_cart\[productId\] \?\? 0\) \+ quantity;\r?\n    \}\);\r?\n  \}\r?\n\r?\n', ''
Set-Content -Path "l:/Total App/totalsolution/lib/screens/salesman/salesman_dashboard_enhanced.dart" -Value $content
Write-Host "Done"
