import pandas as pd

pd.set_option("display.unicode.east_asian_width", True)
pd.set_option("display.unicode.ambiguous_as_wide", True)

customers = pd.read_csv(
    "E-Commerce Sales/clean_csv/customers_clean.csv",
    parse_dates=["SignupDate"],
)

orders = pd.read_csv(
    "E-Commerce Sales/clean_csv/orders_clean.csv",
    parse_dates=["OrderDate"],
)

payments = pd.read_csv(
    "E-Commerce Sales/clean_csv/payments_clean.csv",
    parse_dates=["PaymentDate"],
)

products = pd.read_csv("E-Commerce Sales/clean_csv/products_clean.csv")

# ========================================
# 1. 每月營收、訂單量與銷售量的趨勢如何?
# ========================================
df1 = pd.merge(orders, products, on="ProductID")
df1["年月"] = df1["OrderDate"].dt.strftime("%Y-%m")
df1["每月營收"] = df1["UnitPrice"] * (1 - df1["Discount"]) * df1["Quantity"]
df1 = (
    df1.loc[
        (df1["Quantity"].notna())
        & (df1["OrderDate"].notna())
        & (df1["Discount"].notna())
        & (df1["Status"] == "Completed")
    ]
    .groupby("年月", as_index=False)
    .agg(
        每月營收=("每月營收", "sum"),
        訂單量=("OrderID", "nunique"),
        銷售量=("Quantity", "sum"),
    )
    .sort_values("年月")
)
df1["每月營收"] = df1["每月營收"].round(2)
print(df1.to_string(index=False))
# ========================================
# 2.不同折扣幅度下，訂單數與平均購買數量是否有差異?
# ========================================
df2 = (
    orders.loc[
        (orders["Quantity"].notna())
        & (orders["Discount"].notna())
        & (orders["Status"] == "Completed")
    ]
    .groupby("Discount", as_index=False)
    .agg(訂單數=("OrderID", "nunique"), 平均購買數量=("Quantity", "mean"))
    .rename(columns={"Discount": "折扣"})
)
df2["平均購買數量"] = df2["平均購買數量"].round(2)
print(df2.to_string(index=False))
# ========================================
# 3.不同年齡層的支付方式使用比例有何差異?
# ========================================
df3 = pd.merge(orders, customers, on="CustomerID")
df3["年齡層"] = pd.cut(
    df3["Age"],
    bins=[0, 10, 20, 30, 40, 50, 60, float("inf")],
    labels=[
        "0-10 歲",
        "11-20 歲",
        "21-30 歲",
        "31-40 歲",
        "41-50 歲",
        "51-60 歲",
        "60+ 歲",
    ],
    include_lowest=True,
)
df3["卡片轉帳"] = (df3["PaymentMethod"] == "CardToCard").astype(int)
df3["現金"] = (df3["PaymentMethod"] == "Cash").astype(int)
df3["第三方支付"] = (df3["PaymentMethod"] == "Gateway").astype(int)
df3["電子錢包"] = (df3["PaymentMethod"] == "Wallet").astype(int)
df3 = (
    df3.loc[(df3["年齡層"].notna()) & (df3["PaymentMethod"].notna())]
    .groupby("年齡層", as_index=False, observed=True)
    .agg(
        訂單數=("OrderID", "nunique"),
        卡片轉帳=("卡片轉帳", "mean"),
        現金=("現金", "mean"),
        第三方支付=("第三方支付", "mean"),
        電子錢包=("電子錢包", "mean"),
    )
)
df3["卡片轉帳"] = (df3["卡片轉帳"] * 100).round(2)
df3["現金"] = (df3["現金"] * 100).round(2)
df3["第三方支付"] = (df3["第三方支付"] * 100).round(2)
df3["電子錢包"] = (df3["電子錢包"] * 100).round(2)
print(df3.to_string(index=False))
# ========================================
# 4. 各月份營收最高的 Top 5 商品，其年度營收排名為何?
# ========================================
df4 = pd.merge(orders, products, on="ProductID")
df4["年"] = df4["OrderDate"].dt.strftime("%Y")
df4["年月"] = df4["OrderDate"].dt.strftime("%Y-%m")
df4 = df4.loc[
    (df4["Quantity"].notna())
    & (df4["OrderDate"].notna())
    & (df4["Discount"].notna())
    & (df4["Status"] == "Completed")
].copy()
df4["營收"] = df4["UnitPrice"] * (1 - df4["Discount"]) * df4["Quantity"]
monthly_sales = (
    df4.groupby(["年", "年月", "ProductID", "ProductName"], as_index=False)
    .agg(每月營收=("營收", "sum"))
    .round(2)
)
monthly_sales["各月營收排名"] = (
    monthly_sales.groupby("年月")["每月營收"]
    .rank(method="min", ascending=False)
    .astype(int)
)
yearly_sales = (
    df4.groupby(["年", "ProductID", "ProductName"], as_index=False)
    .agg(每年營收=("營收", "sum"))
    .round(2)
)
yearly_sales["各年營收排名"] = (
    yearly_sales.groupby("年")["每年營收"]
    .rank(method="min", ascending=False)
    .astype(int)
)
df4 = pd.merge(monthly_sales, yearly_sales, on=["年", "ProductID", "ProductName"])

df4 = df4.loc[df4["各月營收排名"] <= 5].sort_values(["年月", "各月營收排名"])
print(df4.to_string(index=False))
# ========================================
# 5.不同客戶分類的營收、訂單量與平均訂單金額有何差異?
# ========================================
orders_customers = pd.merge(orders, customers, on="CustomerID")
df5 = pd.merge(orders_customers, products, on="ProductID")
df5["營收"] = df5["UnitPrice"] * (1 - df5["Discount"]) * df5["Quantity"]
df5 = (
    df5.loc[
        (df5["Quantity"].notna())
        & (df5["Discount"].notna())
        & (df5["Status"] == "Completed")
    ]
    .groupby("CustomerSegment", as_index=False)
    .agg(
        總營收=("營收", "sum"),
        訂單量=("OrderID", "nunique"),
        平均訂單金額=("營收", "mean"),
    )
    .sort_values("總營收", ascending=False)
)
df5["總營收"] = df5["總營收"].round(2)
df5["平均訂單金額"] = df5["平均訂單金額"].round(2)
print(df5.to_string(index=False))
# ========================================
# 6.不同商品類別的完成、取消與退貨訂單比例有何差異?
# ========================================
df6 = pd.merge(orders, products, on="ProductID")
df6["完成"] = (df6["Status"] == "Completed").astype(int)
df6["取消"] = (df6["Status"] == "Cancelled").astype(int)
df6["退貨"] = (df6["Status"] == "Returned").astype(int)
df6 = df6.groupby("Category", as_index=False).agg(
    完成訂單比例=("完成", "mean"),
    取消訂單比例=("取消", "mean"),
    退貨訂單比例=("退貨", "mean"),
)
df6["完成訂單比例"] = (df6["完成訂單比例"] * 100).round(2)
df6["取消訂單比例"] = (df6["取消訂單比例"] * 100).round(2)
df6["退貨訂單比例"] = (df6["退貨訂單比例"] * 100).round(2)
print(df6.to_string(index=False))
# ========================================
# 7. 各商品的平均購買年齡為何?
# ========================================
orders_customers = pd.merge(orders, customers, on="CustomerID")
df7 = pd.merge(orders_customers, products, on="ProductID")
df7 = (
    df7.loc[df7["Quantity"].notna()]
    .groupby(["ProductID", "ProductName"], as_index=False)
    .agg(平均年齡=("Age", "mean"))
)
df7["平均年齡"] = df7["平均年齡"].round(1)
print(df7.to_string(index=False))
# ========================================
# 8. 不同支付方式的付款成功、失敗與退款比例是否有差異?
# ========================================
df8 = pd.merge(orders, payments, on="OrderID")
df8["付款成功"] = (df8["PaymentStatus"] == "Paid").astype(int)
df8["付款失敗"] = (df8["PaymentStatus"] == "Failed").astype(int)
df8["退款"] = (df8["PaymentStatus"] == "Refunded").astype(int)
df8 = (
    df8.loc[df8["PaymentMethod"].notna()]
    .groupby("PaymentMethod", as_index=False)
    .agg(
        訂單數=("OrderID", "nunique"),
        付款成功率=("付款成功", "mean"),
        付款失敗率=("付款失敗", "mean"),
        退款率=("退款", "mean"),
    )
    .sort_values("訂單數", ascending=False)
)
df8 = df8.rename(columns={"PaymentMethod": "付款方式"})
df8["付款成功率"] = (df8["付款成功率"] * 100).round(2)
df8["付款失敗率"] = (df8["付款失敗率"] * 100).round(2)
df8["退款率"] = (df8["退款率"] * 100).round(2)
print(df8.to_string(index=False))
