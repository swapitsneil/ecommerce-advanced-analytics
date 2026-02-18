# Ecommerce Advanced Analytics (SQL Project)

## Project Overview

This project performs end-to-end business analysis on a real-world Brazilian e-commerce dataset using MySQL.

The goal is to simulate the responsibilities of a remote data analyst by:

- Designing a relational database schema  
- Performing data cleaning and validation  
- Writing analytical SQL queries for business insights  
- Implementing advanced SQL techniques (CTEs, window functions, views, indexing)  
- Evaluating operational performance and customer behaviour  

This project focuses purely on SQL analytics quality and structured problem-solving.

---

## Dataset

Source: Olist Brazilian E-commerce Dataset (Kaggle)

Dataset Link:  
https://www.kaggle.com/code/anshumoudgil/olist-ecommerce-analytics-quasi-poisson-poly-regs/input

The dataset includes:

- Customers
- Orders
- Order Items
- Payments
- Reviews
- Products
- Sellers
- Geolocation
- Category translation

Time Period Covered:  
September 2016 – August 2018

---

## Tools Used

- MySQL 8.0
- MySQL Workbench
- Window Functions
- Common Table Expressions (CTEs)
- Views
- Index Optimization
- Execution Plan Analysis (EXPLAIN)

---

## Database Design

The schema includes:

- Proper primary and foreign key constraints
- Order-level aggregation views
- Customer lifetime aggregation views
- Indexes to optimize joins and time-based queries

Key optimization indexes added:

- orders(order_purchase_timestamp)
- orders(customer_id)
- order_items(order_id)
- order_items(product_id)
- order_reviews(order_id)

Execution plans were analyzed using EXPLAIN to validate index usage.

---

## Data Cleaning & Validation

The following checks were performed:

- NULL value validation (dates, prices, categories)
- Duplicate review detection
- Price and freight range validation
- Datetime normalization using STR_TO_DATE with millisecond handling
- Filtering NULL delivery dates in operational metrics
- Order-level DISTINCT logic to prevent inflation from multi-item joins

---

## Core Business KPIs

### Revenue & Growth

- Total Revenue (Gross Merchandise Value)
- Monthly Revenue Trend
- Month-over-Month Growth %
- Monthly Order Volume
- Average Order Value

Insight:
Revenue growth is primarily driven by customer acquisition rather than repeat purchasing behavior.

---

### Customer Analytics

- Repeat Purchase Rate (~3%)
- Customer Lifetime Value (CLV)
- Revenue Contribution of Top 10% Customers (~37%)
- Customer Acquisition Trend
- RFM Base Segmentation (Recency, Frequency, Monetary)

Insight:
Revenue is highly concentrated among top customers, while overall retention remains weak.

---

### Operational Performance

- Late Delivery Rate (~8%)
- Late vs On-Time Review Impact (4.29 → 2.57 rating drop)
- Average Delivery Days
- Order Funnel (Purchase → Approved → Shipped → Delivered → Canceled)
- Cancellation Rate by Product Category (order-level correct logic)

Insight:
Delivery delays significantly reduce customer satisfaction and represent operational risk.

---

### Product & Seller Insights

- Top Revenue Categories
- Category Rating vs Revenue Comparison
- Top Sellers by Revenue
- Sellers with Low Ratings
- Heavy vs Light Product Delivery Impact

Insight:
High-revenue categories maintain strong ratings, indicating product-market fit, but operational improvements are needed to sustain growth.

---

## Advanced SQL Techniques Used

- Common Table Expressions (CTEs)
- Window Functions (ROW_NUMBER, NTILE, LAG)
- Revenue concentration analysis
- Cohort-style monthly customer grouping
- Order-level distinct aggregations
- Performance optimization with indexing
- View-based analytical layer (vw_order_enriched, vw_customer_lifetime)

---

## Views Created

### vw_order_enriched
Provides order-level aggregated dataset for analytical queries.

### vw_customer_lifetime
Provides customer-level aggregation including:
- Total Orders
- Lifetime Value
- First Order Date
- Last Order Date

---

## Key Business Insights

- Revenue growth is strong but driven primarily by new customers.
- Repeat purchase rate is approximately 3%, indicating low retention.
- Top 10% customers contribute ~37% of total revenue.
- Late deliveries (~8%) reduce average review score from 4.29 to 2.57.
- Revenue peaked in late 2017 during high acquisition periods.
- Operational focus should shift toward improving delivery reliability and retention strategies.

---

## Performance Considerations

- Indexes were added to optimize join-heavy queries.
- Execution plans were validated using EXPLAIN.
- DISTINCT logic was applied where necessary to prevent row inflation.
- NULL delivery dates handled consistently in operational metrics.

---

## Future Enhancements

- Full RFM segmentation with quintile scoring and labeled customer segments.
- Power BI dashboard for executive visualization.
- Retention cohort matrix with month-over-month survival analysis.
- Predictive modeling for churn and revenue forecasting.

---

## Repository Structure

```
ecommerce-advanced-analytics/
│
├── ecommerce_analytics.sql
├── README.md
└── (Power BI dashboard - upcoming)
```

---

## Project Objective

This project demonstrates the ability to:

- Translate raw transactional data into structured business insights
- Write production-ready SQL
- Apply performance optimization techniques
- Think from both analytical and operational perspectives

This simulates real-world responsibilities of a remote data analyst role.

