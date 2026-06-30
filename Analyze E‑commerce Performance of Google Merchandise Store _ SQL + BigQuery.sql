-- Top 10 sản phẩm có doanh thu cao nhất
SELECT
  p.v2ProductName AS product_name,
  SUM(p.productRevenue) / 1000000 AS total_revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
     UNNEST(t.hits) AS h,
     UNNEST(h.product) AS p
WHERE p.productRevenue IS NOT NULL
GROUP BY product_name
ORDER BY total_revenue DESC
LIMIT 10;

---Query 02: Doanh thu theo loại sản phẩm
SELECT
  p.v2ProductCategory AS product_category,
  SUM(p.productRevenue) / 1000000 AS total_revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
     UNNEST(t.hits) AS h,
     UNNEST(h.product) AS p
WHERE totals.transactions >= 1
  AND p.productRevenue IS NOT NULL
GROUP BY product_category
ORDER BY total_revenue DESC;

---Query 03: Doanh thu theo quốc gia
SELECT
  t.geoNetwork.country AS country,
  SUM(p.productRevenue) / 1000000 AS total_revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
     UNNEST(t.hits) AS h,
     UNNEST(h.product) AS p
WHERE totals.transactions >= 1
  AND p.productRevenue IS NOT NULL
GROUP BY country
ORDER BY total_revenue DESC;

---Query 04: Doanh thu theo nguồn traffic
SELECT
  t.trafficSource.medium AS traffic_medium,
  SUM(p.productRevenue) / 1000000 AS total_revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
     UNNEST(t.hits) AS h,
     UNNEST(h.product) AS p
WHERE totals.transactions >= 1
  AND p.productRevenue IS NOT NULL
GROUP BY traffic_medium
ORDER BY total_revenue DESC;
select *  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*`

---Query 05: Sản phẩm được mua nhiều nhất (theo số lượng, không giới hạn)
SELECT
  p.v2ProductName AS product_name,
  SUM(p.productQuantity) AS total_quantity
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
     UNNEST(t.hits) AS h,
     UNNEST(h.product) AS p
WHERE  p.productRevenue IS NOT NULL
GROUP BY product_name
ORDER BY total_quantity DESC;

---Query 06: Doanh thu theo từng tháng
SELECT
  EXTRACT(YEAR FROM PARSE_DATE('%Y%m%d', t.date)) AS year,
  EXTRACT(MONTH FROM PARSE_DATE('%Y%m%d', t.date)) AS month,
  SUM(p.productRevenue) / 1000000 AS total_revenue
FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
     UNNEST(t.hits) AS h,
     UNNEST(h.product) AS p
WHERE totals.transactions >= 1
  AND p.productRevenue IS NOT NULL
GROUP BY year, month
ORDER BY year, month;

----Query 07: Tỷ lệ đóng góp doanh thu theo thiết bị
WITH rev AS (
  SELECT
    t.device.deviceCategory AS device,
    SUM(p.productRevenue) / 1000000 AS revenue_by_device
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
       UNNEST(t.hits) AS h,
       UNNEST(h.product) AS p
  WHERE totals.transactions IS NOT NULL
    AND p.productRevenue IS NOT NULL
  GROUP BY device
),
total AS (
  SELECT SUM(p.productRevenue) / 1000000 AS total_revenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
       UNNEST(t.hits) AS h,
       UNNEST(h.product) AS p
  WHERE totals.transactions IS NOT NULL
    AND p.productRevenue IS NOT NULL
)
SELECT
  r.device,
  r.revenue_by_device,
  t.total_revenue,
  ROUND(r.revenue_by_device / t.total_revenue * 100, 2) AS ratio
FROM rev r CROSS JOIN total t
ORDER BY ratio DESC;

---Query 08: Liệt kê các sản phẩm khác mà khách hàng đã mua cùng với sản phẩm "YouTube Men's Vintage Henley" trong tháng 7/2017, kèm số lượng mua.

WITH List_buyer AS( SELECT distinct fullVisitorId
FROM
  `bigquery-public-data.google_analytics_sample.ga_sessions_*` , unnest(hits) as hits, unnest(hits.product) as product
WHERE product.productRevenue IS NOT NULL and totals.transactions>=1 and _table_suffix between '20170701' and '20170731' and product.v2ProductName = "YouTube Men's Vintage Henley"
)


SELECT distinct product.v2ProductName as other_purchased_products, sum(product.productQuantity) as quantity
FROM
  `bigquery-public-data.google_analytics_sample.ga_sessions_*`t ,unnest(hits) as hits, unnest(hits.product) as product
  join List_buyer l
  ON t.fullVisitorId = l.fullVisitorId
WHERE product.productRevenue IS NOT NULL and totals.transactions>=1 and _table_suffix between '20170701' and '20170731' and product.v2ProductName <> "YouTube Men's Vintage Henley"
GROUP BY other_purchased_products
ORDER BY quantity DESC;

--Query 9: Đếm số view sản phẩm (2), add to cart (3), purchase (6 + productRevenue) theo tháng. Tính tỷ lệ add_to_cart_rate và purchase_rate dựa trên số view.

WITH base AS (
  SELECT
    FORMAT_DATE('%Y%m', PARSE_DATE('%Y%m%d', t.date)) AS month,
    h.eCommerceAction.action_type AS action_type,
    p.productRevenue
  FROM `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
       UNNEST(t.hits) AS h,
       UNNEST(h.product) AS p
  WHERE _TABLE_SUFFIX BETWEEN '20170101' AND '20170331'
    AND h.eCommerceAction.action_type IS NOT NULL
),
views AS (
  SELECT
    month,
    COUNTIF(action_type = '2') AS num_product_view
  FROM base
  GROUP BY month
),
adds AS (
  SELECT
    month,
    COUNTIF(action_type = '3') AS num_addtocart
  FROM base
  GROUP BY month
),
purchases AS (
  SELECT
    month,
    COUNTIF(action_type = '6' AND productRevenue IS NOT NULL) AS num_purchase
  FROM base
  GROUP BY month
)
SELECT
  v.month,
  v.num_product_view,
  a.num_addtocart,
  p.num_purchase,
  ROUND(a.num_addtocart / v.num_product_view * 100, 2) AS add_to_cart_rate,
  ROUND(p.num_purchase / v.num_product_view * 100, 2) AS purchase_rate
FROM views v
JOIN adds a USING(month)
JOIN purchases p USING(month)
ORDER BY v.month;

QUERY 10:Tính doanh thu theo tuần từ 05–07/2017 (chỉ lấy productRevenue NOT NULL). Dùng Window Function để tính cumulative revenue.
Chia doanh thu cho 1,000,000 để ngắn gọn.
WITH base AS (
  SELECT
    PARSE_DATE('%Y%m%d', t.date) AS date,
    p.productRevenue as product
  FROM
    `bigquery-public-data.google_analytics_sample.ga_sessions_*` AS t,
    UNNEST(t.hits) AS h,
    UNNEST(h.product) AS p
  WHERE
    _TABLE_SUFFIX BETWEEN '20170501' AND '20170731'
    AND h.eCommerceAction.action_type = '6'
    AND product IS NOT NULL
),
weekly AS (
  SELECT
    FORMAT_DATE('%Y%W', date) AS week,
     SUM(product)/1000000 AS weekly_revenue
  FROM base
  GROUP BY week
)
SELECT
  week,
  FORMAT("%'.2f", weekly_revenue) AS weekly_revenue,
  FORMAT("%'.2f", SUM(weekly_revenue) OVER (ORDER BY week)) AS cumulative_revenue
FROM weekly
ORDER BY week;

