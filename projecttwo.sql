-- 1.不同營業時間點(transaction_time，以時間點區分早上6-11點/中午11-16點/晚上16-21點)，咖啡(product_category=Coffee)的銷售量(transaction_qty)
-- Original SQL：
SELECT CASE
         WHEN transaction_time BETWEEN 6 AND 10 THEN '早上 6-11'
         WHEN transaction_time BETWEEN 11 AND 15 THEN '中午 11-16'
         WHEN transaction_time BETWEEN 16 AND 20 THEN '晚上 16-21'
       END                  AS TIME_PERIOD,
       SUM(transaction_qty) AS TOTAL_QTY
FROM   coffeetwo
WHERE  product_category = 'Coffee'
GROUP  BY CASE
            WHEN transaction_time BETWEEN 6 AND 10 THEN '早上 6-11'
            WHEN transaction_time BETWEEN 11 AND 15 THEN '中午 11-16'
            WHEN transaction_time BETWEEN 16 AND 20 THEN '晚上 16-21'
          END;
-- Optimize SQL：
SELECT
  TIME_PERIOD,
  SUM(TOTAL_QTY) AS TOTAL_QTY
FROM (
  SELECT
    CASE
      WHEN transaction_time BETWEEN 6 AND 10 THEN '早上 6-11'
      WHEN transaction_time BETWEEN 11 AND 15 THEN '中午 11-16'
      WHEN transaction_time BETWEEN 16 AND 20 THEN '晚上 16-21'
    END AS TIME_PERIOD,
    transaction_qty AS TOTAL_QTY
  FROM coffeetwo
  WHERE product_category = 'Coffee'
)
GROUP BY TIME_PERIOD



-- 2.不同店面(store_location)排行前三名產品大類別(Product_category)的銷售量(transaction_qty)
-- Original SQL：
SELECT s.store_location,
       s.product_category,
       s.total_qty
FROM   (SELECT sd1.store_location,
               sd1.product_category,
               sd1.total_qty,
               (SELECT Count(*)
                FROM   (SELECT store_location,
                               product_category,
                               SUM(transaction_qty) AS TOTAL_QTY
                        FROM   coffeetwo
                        GROUP  BY store_location,
                                  product_category) sd2
                WHERE  sd2.store_location = sd1.store_location
                       AND sd2.total_qty > sd1.total_qty)
               + 1 AS RANK
        FROM   (SELECT store_location,
                       product_category,
                       SUM(transaction_qty) AS TOTAL_QTY
                FROM   coffeetwo
                GROUP  BY store_location,
                          product_category) sd1) s
WHERE  s.rank <= 3
ORDER  BY s.store_location,
          s.total_qty DESC;


-- Optimize SQL：
SELECT store_location, product_category, total_qty
FROM (
    SELECT store_location, product_category, SUM(transaction_qty) AS total_qty,
           RANK() OVER (PARTITION BY store_location ORDER BY SUM(transaction_qty) DESC) AS rank
    FROM coffeetwo
    GROUP BY store_location, product_category
)
WHERE rank <= 3
ORDER BY store_location, total_qty DESC;


-- 3.不同月份(transaction_date)中，不同品項(product_category)的銷售額(SUM(unit_price * transaction_qty))
-- Original SQL：
SELECT To_char(transaction_date, 'YYYY-MM') AS MONTH,
       product_category,
       SUM(unit_price * transaction_qty)    AS TOTAL_SALES
FROM   coffeetwo
GROUP  BY To_char(transaction_date, 'YYYY-MM'),
          product_category
ORDER  BY month,
          product_category; 


-- Optimize SQL：
SELECT TRUNC(transaction_date, 'MM') AS MONTH,
       product_category,
       SUM(unit_price * transaction_qty)    AS TOTAL_SALES
FROM   coffeetwo
WHERE  transaction_date >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -12)
GROUP  BY TRUNC(transaction_date, 'MM'),
          product_category
ORDER  BY MONTH,
          product_category;