UPDATE warehouse.PremiumFact
SET premium_amount_gbp = (premium_amount_gbp - premium_amount_gbp * 0.065)
FROM warehouse.PremiumFact pf
INNER JOIN FSA_Staging.stg.Policies p ON pf.policy_id = p.policy_id
WHERE p.underwriter_code = 'MER'

;with PolicyPremiums as (
	select p.policy_id, pf.premium_amount_gbp as warehouse_premium_amount, 
		p.premium_amount_numeric as premium_amount, 
		p.premium_amount_numeric - pf.premium_amount_gbp as variance
	from warehouse.PremiumFact pf
	inner join FSA_Staging.stg.Policies p on pf.policy_id = p.policy_id
	where p.underwriter_code = 'MER'
	and pf.load_timestamp >= '2024-01-01'
)
	select count(*), sum(variance) as total_variance, avg(variance) as average_variance
	from PolicyPremiums
	where variance >= 500

