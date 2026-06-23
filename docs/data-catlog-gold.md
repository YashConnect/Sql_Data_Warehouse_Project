# 📘 Gold Layer Data Catalog

The **Gold Layer** contains curated, business‑ready tables designed for analytics and reporting.  
It includes **dimension tables** (entities like customers and products) and **fact tables** (transactions such as sales).  
This layer follows a **star schema** design: fact tables reference dimension tables via surrogate keys.

---

## 🧑‍🤝‍🧑 Dimension: `Gold.dim_customers`

**Purpose:** Standardized customer information for reporting and analysis.

| Column Name       | Business Meaning                                                                 | Example                |
|-------------------|----------------------------------------------------------------------------------|------------------------|
| `customer_key`    | Surrogate key for joining with fact tables.                                      | `101`                  |
| `customer_id`     | CRM system’s natural customer identifier.                                        | `CST12345`             |
| `customer_number` | Internal reference number for the customer.                                      | `CN56789`              |
| `first_name`      | Customer’s first name.                                                           | `John`                 |
| `last_name`       | Customer’s last name.                                                            | `Doe`                  |
| `country`         | Country of residence (from ERP location).                                        | `India`                |
| `marital_status`  | Customer’s marital status.                                                       | `Married`              |
| `gender`          | Gender, cleaned from CRM/ERP. Defaults to `N/A` if missing.                      | `Male`                 |
| `birthday`        | Date of birth.                                                                  | `1985-07-12`           |
| `create_date`     | Date the customer record was created in CRM.                                     | `2020-01-15`           |

---

## 📦 Dimension: `Gold.dim_products`

**Purpose:** Product master data enriched with category information.

| Column Name       | Business Meaning                                                                 | Example                |
|-------------------|----------------------------------------------------------------------------------|------------------------|
| `product_key`     | Surrogate key for joining with fact tables.                                      | `501`                  |
| `product_id`      | Natural product identifier from CRM.                                             | `PRD1001`              |
| `product_number`  | Internal product reference number.                                               | `PN2002`               |
| `product_name`    | Name of the product.                                                             | `Laptop Model X`       |
| `category_id`     | Identifier for product category.                                                 | `CAT12`                |
| `category`        | Product category grouping.                                                       | `Electronics`          |
| `subcategory`     | Product subcategory.                                                             | `Laptops`              |
| `maintenance_flag`| Indicates if product requires maintenance.                                       | `Yes`                  |
| `product_cost`    | Cost of the product.                                                             | `750.00`               |
| `product_line`    | Product line grouping (e.g., Consumer vs Enterprise).                            | `Consumer Devices`     |
| `start_date`      | Date product was introduced.                                                     | `2021-03-01`           |

---

## 💰 Fact: `Gold.fact_sales`

**Purpose:** Transactional sales data linking customers and products.

| Column Name       | Business Meaning                                                                 | Example                |
|-------------------|----------------------------------------------------------------------------------|------------------------|
| `order_number`    | Unique sales order number.                                                       | `ORD7890`              |
| `product_key`     | Foreign key referencing `Gold.dim_products`.                                     | `501`                  |
| `customer_key`    | Foreign key referencing `Gold.dim_customers`.                                    | `101`                  |
| `order_date`      | Date when the order was placed.                                                  | `2022-05-10`           |
| `shipping_date`   | Date when the order was shipped.                                                 | `2022-05-12`           |
| `due_date`        | Expected delivery date.                                                          | `2022-05-15`           |
| `sales_amount`    | Total sales amount for the order.                                                | `1500.00`              |
| `quantity`        | Number of units sold.                                                            | `2`                    |
| `unit_price`      | Price per unit.                                                                  | `750.00`               |

---

## 🔑 Notes
- **Surrogate Keys** (`customer_key`, `product_key`) ensure consistent joins across fact and dimension tables.
- **Business Keys** (`customer_id`, `product_id`) come directly from source systems (CRM/ERP).
- **Fact tables** reference dimension surrogate keys to support star schema design.
- This layer is intended for **business reporting** such as revenue analysis, customer segmentation, and product performance.

---

## 📊 Example Business Questions
- *Customer Analysis:* “Which countries have the highest number of new customers created in 2020?”  
- *Product Analysis:* “What is the average cost of products in the Electronics category?”  
- *Sales Analysis:* “What is the total sales amount by product line and customer country?”  

---

