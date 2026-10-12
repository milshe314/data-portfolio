import pandas as pd

customers = pd.read_csv("E-Commerce Sales/csv/customers.csv")
orders = pd.read_csv("E-Commerce Sales/csv/orders.csv")
payments = pd.read_csv("E-Commerce Sales/csv/payments.csv")
products = pd.read_csv("E-Commerce Sales/csv/products.csv")
#  ========================================
#  1. 重複資料處理
#  ========================================
orders_clean = orders.drop_duplicates().copy()
#  ========================================
#  2. 異常值處理
#  ========================================
orders_clean = orders_clean.loc[
    orders_clean["Quantity"].isna()
    | (orders_clean["Quantity"] > 0)
].copy()
#  ========================================
#  3. 關聯完整性處理
#  ========================================
orders_clean = orders_clean.loc[
    orders_clean["CustomerID"].isin(customers["CustomerID"])
].copy()
payments_clean = payments.loc[
    payments["OrderID"].isin(orders_clean["OrderID"])
].copy()
customers_clean = customers.copy()
products_clean = products.copy()
#  ========================================
#  4. 資料型別調整
#  ========================================
orders_clean["OrderDate"] = pd.to_datetime(
    orders_clean["OrderDate"],
    errors="coerce",
)

customers_clean["SignupDate"] = pd.to_datetime(
    customers_clean["SignupDate"],
    errors="coerce",
)

payments_clean["PaymentDate"] = pd.to_datetime(
    payments_clean["PaymentDate"],
    errors="coerce",
)

orders_clean["Quantity"] = orders_clean["Quantity"].astype("Int64")
customers_clean["Age"] = customers_clean["Age"].astype("Int64")
#  ========================================
#  5. 輸出前驗證
#  ========================================
assert orders_clean.duplicated().sum() == 0
assert orders_clean["OrderID"].is_unique
assert customers_clean["CustomerID"].is_unique
assert products_clean["ProductID"].is_unique
assert payments_clean["PaymentID"].is_unique
assert payments_clean["OrderID"].is_unique

assert not (orders_clean["Quantity"].dropna() <= 0).any()

assert orders_clean["CustomerID"].isin(customers_clean["CustomerID"]).all()
assert orders_clean["ProductID"].isin(products_clean["ProductID"]).all()
assert payments_clean["OrderID"].isin(orders_clean["OrderID"]).all()
#  ========================================
#  6. 建立分析用資料集
#  ========================================
orders_clean.to_csv("E-Commerce Sales/clean_csv/orders_clean.csv", index=False)
customers_clean.to_csv("E-Commerce Sales/clean_csv/customers_clean.csv", index=False)
products_clean.to_csv("E-Commerce Sales/clean_csv/products_clean.csv", index=False)
payments_clean.to_csv("E-Commerce Sales/clean_csv/payments_clean.csv", index=False)