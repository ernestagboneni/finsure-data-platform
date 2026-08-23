;WITH  cte
AS     (SELECT policy_id
      ,underwriter_code
      ,policy_type
      ,risk_band
      ,region
      ,agent_id
      ,CASE 
        WHEN TRY_CONVERT(DATE, policy_start_date, 23) IS NOT NULL 
            THEN TRY_CONVERT(DATE, policy_start_date, 23)
        WHEN TRY_CONVERT(DATE, policy_start_date, 103) IS NOT NULL 
            THEN TRY_CONVERT(DATE, policy_start_date, 103)
        ELSE NULL 
       END AS policy_start_date
      ,CASE 
            WHEN TRY_CONVERT(DATE, policy_end_date, 23) IS NOT NULL 
                THEN TRY_CONVERT(DATE, policy_end_date, 23)
            WHEN TRY_CONVERT(DATE, policy_end_date, 103) IS NOT NULL 
                THEN TRY_CONVERT(DATE, policy_end_date, 103)
            ELSE NULL 
        END AS policy_end_date
      ,payment_frequency
      ,TRY_CAST(
        REPLACE(
            REPLACE(
                REPLACE(premium_amount, 'Â', ''), 
            '£', ''), 
        ',', '') 
        AS DECIMAL(18,2)) AS premium_amount
      ,TRY_CAST(warehouse_premium_gbp AS DECIMAL(18,2)) AS warehouse_premium_gbp
      ,TRY_CAST(premium_variance_gbp AS DECIMAL(18,2)) AS premium_variance_gbp
      ,etl_status
      ,etl_processed_week
      ,source_system
      ,data_quality_flag
      ,ROW_NUMBER() OVER (PARTITION BY policy_id ORDER BY policy_id) AS rn
        FROM   stg.Policies
     )

    SELECT *
    FROM   cte
    WHERE  rn = 1;