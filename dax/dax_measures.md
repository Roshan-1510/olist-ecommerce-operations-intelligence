# Olist E-Commerce Operations Intelligence Dashboard — DAX Measures

## Executive Operations KPIs

### Delivered Orders
```DAX
Delivered Orders =

CALCULATE(
    DISTINCTCOUNT(fact_orders[order_id]),
    fact_orders[order_status] = "delivered"
)
```

---

### Late Delivered Orders Q1
```DAX
Late Delivered Orders Q1 =

CALCULATE(
    DISTINCTCOUNT(fact_orders[order_id]),

    fact_orders[order_status] = "delivered",

    fact_orders[order_delivered_customer_date]
        >
    fact_orders[order_estimated_delivery_date]
)
```

---

### Platform Late Delivery Rate %
```DAX
Platform Late Delivery Rate % =

DIVIDE(
    [Late Delivered Orders Q1],
    [Delivered Orders],
    0
)
```

---

### Average Delivery Delay Days
```DAX
Average Delivery Delay Days =

AVERAGEX(

    FILTER(
        fact_orders,

        fact_orders[order_delivered_customer_date]
            >
        fact_orders[order_estimated_delivery_date]
    ),

    DATEDIFF(
        fact_orders[order_estimated_delivery_date],
        fact_orders[order_delivered_customer_date],
        DAY
    )
)
```

---

### High-Risk Orders %
```DAX
High-Risk Orders % =

DIVIDE(
    [High Risk Orders],
    [Delivered Orders],
    0
)
```

---

## Logistics Intelligence KPIs

### Distance Band
```DAX
Distance Band =

SWITCH(
    TRUE(),

    fact_order_items[delivery_distance_km] <= 500,
        "0-500 km",

    fact_order_items[delivery_distance_km] <= 735,
        "501-735 km",

    fact_order_items[delivery_distance_km] <= 1000,
        "736-1000 km",

    fact_order_items[delivery_distance_km] <= 1500,
        "1001-1500 km",

    fact_order_items[delivery_distance_km] <= 2500,
        "1501-2500 km",

    "2501-4000 km"
)
```

---

### Orders Above 735km %
```DAX
Orders Above 735km % =

DIVIDE(

    CALCULATE(

        DISTINCTCOUNT(fact_orders[order_id]),

        FILTER(
            fact_order_items,
            fact_order_items[delivery_distance_km] > 735
        )

    ),

    DISTINCTCOUNT(fact_orders[order_id]),

    0
)
```

---

### Late Delivery Rate % Q4
```DAX
Late Delivery Rate % Q4 =

DIVIDE(
    [Late Delivered Orders Q1],
    [Delivered Orders],
    0
)
```

---

## Seller Management KPIs

### Seller Order Volume
```DAX
Seller Order Volume =

DISTINCTCOUNT(fact_order_items[order_id])
```

---

### Seller Average Review Score
```DAX
Seller Average Review Score =

AVERAGE(fact_reviews[review_score])
```

---

### Seller Carrier Deadline Miss %
```DAX
Seller Carrier Deadline Miss % =

DIVIDE(

    CALCULATE(
        COUNTROWS(fact_order_items),

        fact_order_items[order_delivered_carrier_date]
            >
        fact_order_items[shipping_limit_date]
    ),

    COUNTROWS(fact_order_items),

    0
)
```

---

### Seller Volume 75th Percentile
```DAX
Seller Volume 75th Percentile =

PERCENTILEX.INC(
    VALUES(dim_sellers[seller_id]),
    [Seller Order Volume],
    0.75
)
```

---

### Seller Risk Flag Q2
```DAX
Seller Risk Flag Q2 =

IF(

    [Seller Order Volume] > [Seller Volume 75th Percentile]

        &&

    [Seller Average Review Score] < 3,

    "High Risk",

    "Normal"
)
```

---

### High Risk Sellers
```DAX
High Risk Sellers =

CALCULATE(

    DISTINCTCOUNT(dim_sellers[seller_id]),

    FILTER(

        VALUES(dim_sellers[seller_id]),

        [Seller Risk Flag Q2] = "High Risk"
    )
)
```

---

## Customer Experience KPIs

### Average Review Score
```DAX
Average Review Score =

AVERAGE(fact_reviews[review_score])
```

---

### High Installment Orders
```DAX
High Installment Orders =

CALCULATE(

    DISTINCTCOUNT(fact_payments[order_id]),

    fact_payments[payment_installments] > 6
)
```

---

### High Installment Order %
```DAX
High Installment Order % =

DIVIDE(

    [High Installment Orders],

    DISTINCTCOUNT(fact_payments[order_id]),

    0
)
```

---

### Freight Risk Threshold
```DAX
Freight Risk Threshold =

CALCULATE(

    AVERAGE(fact_order_items[freight_to_price_ratio]),

    fact_reviews[review_score] > 4
)
```

---

### High Freight Risk Orders
```DAX
High Freight Risk Orders =

CALCULATE(

    DISTINCTCOUNT(fact_order_items[order_id]),

    FILTER(

        fact_order_items,

        fact_order_items[freight_to_price_ratio]
            >
        [Freight Risk Threshold]
    )
)
```

---

### High Freight Risk %
```DAX
High Freight Risk % =

DIVIDE(

    [High Freight Risk Orders],

    DISTINCTCOUNT(fact_order_items[order_id]),

    0
)
```

---

### Avg Freight Ratio
```DAX
Avg Freight Ratio =

AVERAGE(
    fact_order_items[freight_to_price_ratio]
)
```

---

## Risk & Dissatisfaction Metrics

### Low Review Rate %
```DAX
Low Review Rate % =

DIVIDE(

    CALCULATE(

        COUNT(fact_reviews[review_id]),

        fact_reviews[review_score] <= 2
    ),

    COUNT(fact_reviews[review_id])
)
```

---

### Cancellation Rate Category
```DAX
Cancellation Rate Category =

DIVIDE(

    CALCULATE(

        COUNT(fact_orders[order_id]),

        fact_orders[order_status] = "canceled"
    ),

    COUNT(fact_orders[order_id])
)
```

---

## Data Model Notes

- Star schema architecture implemented in Power BI
- MySQL used for data cleaning and transformation
- Delivery distance calculations engineered during preprocessing
- Freight-to-price ratio created as customer dissatisfaction proxy
- Seller operational risk modeled using dual-threshold logic
- Dashboard designed for stakeholder-specific operational intelligence

