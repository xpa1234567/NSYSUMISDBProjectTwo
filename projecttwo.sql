-- 1.不同季節(transaction_date，以月份區分春天3-5月/夏天6-8月/秋天9-11月/冬天12-2月)，咖啡(product_category=Coffee)的銷售量(transaction_qty)
-- Original SQL：
 SELECT
  SEASON,
  SUM(TOTAL_QTY)
FROM (
  SELECT
    (
      SELECT 
        CASE 
          WHEN TO_NUMBER(TO_CHAR(sd_inner.TRANSACTION_DATE, 'MM')) BETWEEN 3 AND 5 THEN '春季'
          WHEN TO_NUMBER(TO_CHAR(sd_inner.TRANSACTION_DATE, 'MM')) BETWEEN 6 AND 8 THEN '夏季'
          WHEN TO_NUMBER(TO_CHAR(sd_inner.TRANSACTION_DATE, 'MM')) BETWEEN 9 AND 11 THEN '秋季'
          WHEN TO_NUMBER(TO_CHAR(sd_inner.TRANSACTION_DATE, 'MM')) = 12 OR TO_NUMBER(TO_CHAR(sd_inner.TRANSACTION_DATE, 'MM')) BETWEEN 1 AND 2 THEN '冬季'
        END
      FROM COFFEETWO sd_inner
      WHERE sd_inner.TRANSACTION_ID = sd_outer.TRANSACTION_ID
    ) AS SEASON,
    sd_outer.TRANSACTION_QTY AS TOTAL_QTY
  FROM COFFEETWO sd_outer
  WHERE sd_outer.PRODUCT_CATEGORY = 'Coffee'
) sub
GROUP BY SEASON;

-- Optimize SQL：
SELECT
  SEASON,
  SUM(TRANSACTION_QTY) AS TOTAL_QTY
FROM (
  SELECT
    TRANSACTION_QTY,
    CASE
      WHEN EXTRACT(MONTH FROM TRANSACTION_DATE) IN (3, 4, 5) THEN '春季'
      WHEN EXTRACT(MONTH FROM TRANSACTION_DATE) IN (6, 7, 8) THEN '夏季'
      WHEN EXTRACT(MONTH FROM TRANSACTION_DATE) IN (9, 10, 11) THEN '秋季'
      WHEN EXTRACT(MONTH FROM TRANSACTION_DATE) IN (12, 1, 2) THEN '冬季'
    END AS SEASON
  FROM COFFEETWO
  WHERE PRODUCT_CATEGORY = 'Coffee'
) sub
GROUP BY SEASON
ORDER BY SEASON;



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