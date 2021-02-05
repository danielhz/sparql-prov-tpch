explain analyze
select *
from
  (
    select
	    nation,
	    o_year,
	    sum(amount) as sum_profit
    from
	    (
		    select
			    n_name as nation,
			    extract(year from o_orderdate) as o_year,
			    l_extendedprice * (1 - l_discount) - ps_supplycost * l_quantity as amount
		    from
			    part,
			    supplier,
			    lineitem,
			    partsupp,
			    orders,
			    nation
		    where
			    s_suppkey = l_suppkey
			    and ps_suppkey = l_suppkey
			    and ps_partkey = l_partkey
			    and p_partkey = l_partkey
			    and o_orderkey = l_orderkey
			    and s_nationkey = n_nationkey
			    and p_name like '%thistle%'
	    ) as profit
    group by
	    nation,
	    o_year
  ) AS q1
  NATURAL JOIN
  (
    select
	    n_name as nation,
	    extract(year from o_orderdate) as o_year,
	    part AS p_sum_summand_product_factor_1_statement,
	    supplier AS p_sum_summand_product_factor_2_statement,
	    lineitem AS p_sum_summand_product_factor_3_statement,
	    partsupp AS p_sum_summand_product_factor_4_statement,
	    orders AS p_sum_summand_product_factor_5_statement,
	    nation AS p_sum_summand_product_factor_6_statement,
	    '' AS p_sum_summand_product,
	    '' AS p_sum
    from
	    part,
	    supplier,
	    lineitem,
	    partsupp,
	    orders,
	    nation
    where
	    s_suppkey = l_suppkey
	    and ps_suppkey = l_suppkey
	    and ps_partkey = l_partkey
	    and p_partkey = l_partkey
	    and o_orderkey = l_orderkey
	    and s_nationkey = n_nationkey
	    and p_name like '%thistle%'
  ) AS q2;
