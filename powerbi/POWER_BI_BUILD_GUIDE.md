# Power BI Build Guide — Olist E-Commerce Analytics

## 1. Import Data
`Home → Get Data → Text/CSV`, import the raw or processed tables:
`orders`, `customers`, `order_items`, `products`, `payments`, `reviews`, `sellers`.

## 2. Build Relationships (Model view)

```
orders[order_id]      1 → * order_items[order_id]
orders[customer_id]   1 → * customers[customer_id]
order_items[product_id] * → 1 products[product_id]
order_items[seller_id]  * → 1 sellers[seller_id]
orders[order_id]      1 → * payments[order_id]
orders[order_id]      1 → * reviews[order_id]
```

## 3. Core DAX Measures

```DAX
Total Orders =
DISTINCTCOUNT(orders[order_id])

Total Customers =
DISTINCTCOUNT(customers[customer_id])

Total Revenue =
SUMX(
    order_items,
    order_items[price] + order_items[freight_value]
)

Average Order Value =
DIVIDE([Total Revenue], [Total Orders])

Average Review Score =
AVERAGE(reviews[review_score])

Late Orders =
CALCULATE(
    [Total Orders],
    orders[order_delivered_customer_date] > orders[order_estimated_delivery_date]
)

Late Delivery % =
DIVIDE([Late Orders], [Total Orders])

Average Delivery Days =
AVERAGEX(
    orders,
    DATEDIFF(orders[order_purchase_timestamp], orders[order_delivered_customer_date], DAY)
)

MoM Revenue Growth % =
VAR CurrentRevenue = [Total Revenue]
VAR PreviousRevenue =
    CALCULATE([Total Revenue], DATEADD('Date'[Date], -1, MONTH))
RETURN
    DIVIDE(CurrentRevenue - PreviousRevenue, PreviousRevenue)
```

> Note: `MoM Revenue Growth %` requires a proper Date table marked as the model's date table.

## Dashboard Pages

### 1. Executive Overview

Purpose:
Provide a high-level view of business performance.

KPIs:
- Total Revenue
- Total Orders
- Average Order Value
- Customers
- Average Review Score
- Delivery metrics

### 2. Sales & Products

Focus:
- Revenue trends
- Product categories
- Top products
- Category performance
- Geographic sales performance

### 3. Customers & Delivery

Focus:
- Customer distribution
- Delivery performance
- Late deliveries
- Review scores
- State-level performance

## Data Model

Describe the relationships between:

- Orders
- Customers
- Order Items
- Products
- Sellers
- Payments
- Reviews
- Category Translation

## DAX

The report uses DAX measures for KPI calculations, aggregations,
time-based analysis, and dashboard metrics.

## Key Features

- Interactive slicers
- Cross-filtering
- KPI cards
- Time-series analysis
- Category analysis
- Geographic analysis
- Delivery analysis
- Customer satisfaction analysis