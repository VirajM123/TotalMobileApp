#!/usr/bin/env python3
# Data Bridge: Transform Excel/CSV from any PC → Your Total Solution App
# Usage: python data_bridge.py products.xlsx  OR  python data_bridge.py customers.xlsx

import sys
import json
import requests
import pandas as pd
from pathlib import Path

# CONFIG: Update with your mobile backend IP:PORT (find with ipconfig)
MOBILE_BACKEND = "http://localhost:3000"

def transform_and_sync(file_path, data_type):
    """
    Transform Excel/CSV → JSON → POST to /sync/products or /sync/customers
    """
    file = Path(file_path)
    if not file.exists():
        print(f"❌ File not found: {file_path}")
        return False
    
    try:
        # Read Excel/CSV
        if file.suffix.lower() in ['.xlsx', '.xls']:
            df = pd.read_excel(file_path)
        else:
            df = pd.read_csv(file_path)
        
        print(f"📊 Loaded {len(df)} rows from {file.name}")
        
        # Transform based on type (match your ProductModel/CustomerModel)
        if data_type == "products":
            data = df[["Name", "Category", "SKU", "Price", "Stock", "Description"]].rename(columns={
                "Name": "name", "Category": "category", "SKU": "sku", 
                "Price": "price", "Stock": "stock", "Description": "description"
            }).fillna("").to_dict("records")
            endpoint = f"{MOBILE_BACKEND}/sync/products"
            payload_key = "products"
        elif data_type == "customers":
            data = df[["Name", "Phone", "Address", "Area", "Route"]].rename(columns={
                "Name": "name", "Phone": "phone", "Address": "address", 
                "Area": "area", "Route": "route"
            }).fillna("").to_dict("records")
            endpoint = f"{MOBILE_BACKEND}/sync/customers"
            payload_key = "customers"
        else:
            print("❌ Type must be 'products' or 'customers'")
            return False
        
        # Generate IDs (idempotent sync)
        for i, item in enumerate(data):
            item["id"] = f"{data_type}_{Path(file.stem).stem}_{i}"
        
        # POST to backend
        response = requests.post(
            endpoint, 
            json={payload_key: data},
            timeout=30
        )
        
        result = response.json()
        print(f"✅ SYNC SUCCESS: {result.get('message', 'Data imported!')}")
        print(f"   📈 Inserted: {result.get('inserted', 0)}, Updated: {result.get('updated', 0)}")
        return True
        
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python data_bridge.py <excel_or_csv_file.xlsx>")
        print("Example: python data_bridge.py products.xlsx")
        sys.exit(1)
    
    file_path = sys.argv[1]
    # Auto-detect type from filename
    data_type = "products" if "product" in file_path.lower() or "prod" in file_path.lower() else "customers"
    
    print(f"🚀 Transforming {file_path} → Total Solution App ({data_type})")
    print(f"📡 Backend:", MOBILE_BACKEND)
    
    success = transform_and_sync(file_path, data_type)
    sys.exit(0 if success else 1)

