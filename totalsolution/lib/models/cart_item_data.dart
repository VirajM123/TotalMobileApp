// Cart item data class to store all order details
class CartItemData {
  final String productId;
  final String productName;
  final String sku;
  int quantity;
  double rate;
  double schPer;
  double schAmt;
  double grossAmt;
  double netAmt;

  CartItemData({
    required this.productId,
    required this.productName,
    required this.sku,
    required this.quantity,
    required this.rate,
    this.schPer = 0,
    this.schAmt = 0,
    this.grossAmt = 0,
    this.netAmt = 0,
  });

  // Calculate and update amounts - FIXED: Ensure schAmt is always calculated correctly
  // Formula: grossAmt = quantity * rate
  //         schAmt = (schPer / 100) * grossAmt
  //         netAmt = grossAmt - schAmt
  void calculate() {
    // Always calculate grossAmt first (quantity * rate)
    grossAmt = quantity * rate;

    // Always calculate schAmt from schPer percentage of grossAmt
    // This ensures schAmt is never stale or incorrectly set
    if (schPer > 0) {
      schAmt = (schPer / 100) * grossAmt;
    } else {
      schAmt = 0;
    }

    // Net amount is always gross amount minus scheme amount
    netAmt = grossAmt - schAmt;
  }
}
