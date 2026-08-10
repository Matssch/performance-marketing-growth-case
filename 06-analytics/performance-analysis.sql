/*
============================================================
PERFORMANCE MARKETING GROWTH CASE
============================================================

Company:
Anonymised Dutch mobility company

Purpose:
Use synthetic acquisition, website and lifecycle data to answer
practical growth questions across the full customer journey.

The analysis covers:

01. Channel performance
02. Conversion rate by channel
03. Performance by customer segment
04. Channel performance by segment
05. Monthly performance trend
06. Website funnel performance
07. Landing page performance
08. Activation by segment
09. Month-over-month CPA
10. Incremental / marginal CPA
11. CRO opportunity by landing page
12. Activation and retention by segment
13. Customer value by segment
14. Acquisition economics by segment

All data used in this analysis is synthetic.

It recreates the structure and scale of the real growth problem
without exposing confidential company or customer information.

Tables used:

campaign_performance
- month
- channel
- segment
- spend
- clicks
- customers

landing_page_performance
- month
- landing_page
- sessions
- journey_starts
- conversions
- customers

customer_lifecycle
- month
- segment
- new_customers
- activated_customers
- retained_90d
- avg_customer_value
*/


/*
============================================================
01. CHANNEL PERFORMANCE
============================================================

Question:
Which acquisition channels create the most customers,
and what does that cost?

This gives the first high-level view of the acquisition mix.
*/

SELECT
    channel,

    SUM(spend) AS total_spend,
    SUM(clicks) AS total_clicks,
    SUM(customers) AS total_customers,

    ROUND(
        SUM(spend) / NULLIF(SUM(clicks), 0),
        2
    ) AS cpc,

    ROUND(
        SUM(spend) / NULLIF(SUM(customers), 0),
        2
    ) AS cpa

FROM campaign_performance

GROUP BY channel

ORDER BY total_customers DESC;


/*
============================================================
02. CONVERSION RATE BY CHANNEL
============================================================

Question:
Are differences in CPA being driven by traffic cost
or by conversion performance?

This helps separate CPC problems from conversion problems.
*/

SELECT
    channel,

    SUM(clicks) AS total_clicks,
    SUM(customers) AS total_customers,

    ROUND(
        100.0 * SUM(customers)
        / NULLIF(SUM(clicks), 0),
        2
    ) AS click_to_customer_rate,

    ROUND(
        SUM(spend)
        / NULLIF(SUM(clicks), 0),
        2
    ) AS cpc,

    ROUND(
        SUM(spend)
        / NULLIF(SUM(customers), 0),
        2
    ) AS cpa

FROM campaign_performance

GROUP BY channel

ORDER BY cpa ASC;


/*
============================================================
03. PERFORMANCE BY CUSTOMER SEGMENT
============================================================

Question:
Do different customer segments have different
acquisition economics?

A blended CPA can hide major differences between
small, mid-sized and larger customers.
*/

SELECT
    segment,

    SUM(spend) AS total_spend,
    SUM(clicks) AS total_clicks,
    SUM(customers) AS total_customers,

    ROUND(
        SUM(spend)
        / NULLIF(SUM(customers), 0),
        2
    ) AS cpa,

    ROUND(
        100.0 * SUM(customers)
        / NULLIF(SUM(clicks), 0),
        2
    ) AS conversion_rate

FROM campaign_performance

GROUP BY segment

ORDER BY cpa ASC;


/*
============================================================
04. CHANNEL PERFORMANCE BY SEGMENT
============================================================

Question:
Which channel works best for which customer segment?

The strongest channel overall may not be the strongest
channel for every type of customer.
*/

SELECT
    channel,
    segment,

    SUM(spend) AS total_spend,
    SUM(clicks) AS total_clicks,
    SUM(customers) AS total_customers,

    ROUND(
        SUM(spend)
        / NULLIF(SUM(customers), 0),
        2
    ) AS cpa,

    ROUND(
        100.0 * SUM(customers)
        / NULLIF(SUM(clicks), 0),
        2
    ) AS conversion_rate

FROM campaign_performance

GROUP BY
    channel,
    segment

ORDER BY
    segment,
    cpa ASC;


/*
============================================================
05. MONTHLY PERFORMANCE TREND
============================================================

Question:
How are acquisition efficiency and customer volume
changing over time?

One month alone does not tell me whether performance
is actually improving.
*/

SELECT
    month,

    SUM(spend) AS total_spend,
    SUM(clicks) AS total_clicks,
    SUM(customers) AS total_customers,

    ROUND(
        SUM(spend)
        / NULLIF(SUM(customers), 0),
        2
    ) AS cpa,

    ROUND(
        100.0 * SUM(customers)
        / NULLIF(SUM(clicks), 0),
        2
    ) AS conversion_rate

FROM campaign_performance

GROUP BY month

ORDER BY month;


/*
============================================================
06. WEBSITE FUNNEL PERFORMANCE
============================================================

Question:
Where are we losing users after they arrive
on the website?

This moves the analysis beyond the advertising platform.
*/

SELECT
    month,

    SUM(sessions) AS sessions,
    SUM(journey_starts) AS journey_starts,
    SUM(conversions) AS conversions,
    SUM(customers) AS customers,

    ROUND(
        100.0 * SUM(journey_starts)
        / NULLIF(SUM(sessions), 0),
        2
    ) AS session_to_start_rate,

    ROUND(
        100.0 * SUM(conversions)
        / NULLIF(SUM(journey_starts), 0),
        2
    ) AS journey_completion_rate,

    ROUND(
        100.0 * SUM(customers)
        / NULLIF(SUM(sessions), 0),
        2
    ) AS session_to_customer_rate

FROM landing_page_performance

GROUP BY month

ORDER BY month;


/*
============================================================
07. LANDING PAGE PERFORMANCE
============================================================

Question:
Which landing pages convert traffic into customers
most efficiently?

Low-volume pages are excluded to avoid making decisions
based on tiny sample sizes.
*/

SELECT
    landing_page,

    SUM(sessions) AS sessions,
    SUM(customers) AS customers,

    ROUND(
        100.0 * SUM(customers)
        / NULLIF(SUM(sessions), 0),
        2
    ) AS conversion_rate

FROM landing_page_performance

GROUP BY landing_page

HAVING SUM(sessions) >= 500

ORDER BY conversion_rate DESC;


/*
============================================================
08. ACTIVATION BY SEGMENT
============================================================

Question:
Are the customers we acquire actually becoming
active customers?

A cheap acquisition is less valuable if the customer
does not successfully activate.
*/

SELECT
    segment,

    SUM(new_customers) AS new_customers,
    SUM(activated_customers) AS activated_customers,

    ROUND(
        100.0 * SUM(activated_customers)
        / NULLIF(SUM(new_customers), 0),
        2
    ) AS activation_rate

FROM customer_lifecycle

GROUP BY segment

ORDER BY activation_rate DESC;


/*
============================================================
09. MONTH-OVER-MONTH CPA
============================================================

Question:
How quickly is CPA changing?

LAG allows the current month's CPA to be compared
with the previous month.
*/

WITH monthly_performance AS (

    SELECT
        month,

        SUM(spend) AS spend,
        SUM(customers) AS customers,

        ROUND(
            SUM(spend)
            / NULLIF(SUM(customers), 0),
            2
        ) AS cpa

    FROM campaign_performance

    GROUP BY month
)

SELECT
    month,
    spend,
    customers,
    cpa,

    LAG(cpa) OVER (
        ORDER BY month
    ) AS previous_month_cpa,

    ROUND(
        100.0
        * (
            cpa
            - LAG(cpa) OVER (ORDER BY month)
        )
        / NULLIF(
            LAG(cpa) OVER (ORDER BY month),
            0
        ),
        2
    ) AS cpa_change_percent

FROM monthly_performance

ORDER BY month;


/*
============================================================
10. INCREMENTAL / MARGINAL CPA
============================================================

Question:
What did additional spend generate compared with
the previous month?

This is a simplified proxy for marginal acquisition cost.

It should be interpreted carefully because other variables
can also change between periods.
*/

WITH monthly_channel_performance AS (

    SELECT
        month,
        channel,

        SUM(spend) AS spend,
        SUM(customers) AS customers

    FROM campaign_performance

    GROUP BY
        month,
        channel
),

changes AS (

    SELECT
        month,
        channel,
        spend,
        customers,

        spend
        - LAG(spend) OVER (
            PARTITION BY channel
            ORDER BY month
        ) AS additional_spend,

        customers
        - LAG(customers) OVER (
            PARTITION BY channel
            ORDER BY month
        ) AS additional_customers

    FROM monthly_channel_performance
)

SELECT
    month,
    channel,
    spend,
    customers,
    additional_spend,
    additional_customers,

    ROUND(
        additional_spend
        / NULLIF(additional_customers, 0),
        2
    ) AS incremental_cpa

FROM changes

WHERE
    additional_spend > 0
    AND additional_customers > 0

ORDER BY
    channel,
    month;


/*
============================================================
11. CRO OPPORTUNITY BY LANDING PAGE
============================================================

Question:
Which landing pages combine enough traffic with enough
potential conversion upside to deserve attention?

A low conversion rate alone does not make a page
the highest CRO priority.
*/

SELECT
    landing_page,

    SUM(sessions) AS sessions,
    SUM(customers) AS customers,

    ROUND(
        100.0 * SUM(customers)
        / NULLIF(SUM(sessions), 0),
        2
    ) AS conversion_rate,

    ROUND(
        SUM(sessions) * 0.01,
        0
    ) AS customers_from_1pp_cvr_improvement

FROM landing_page_performance

GROUP BY landing_page

ORDER BY customers_from_1pp_cvr_improvement DESC;


/*
============================================================
12. ACTIVATION AND RETENTION BY SEGMENT
============================================================

Question:
Are the customers we acquire becoming active
and staying active?

This adds a customer-quality layer to the acquisition data.
*/

SELECT
    segment,

    SUM(new_customers) AS new_customers,
    SUM(activated_customers) AS activated_customers,
    SUM(retained_90d) AS retained_customers,

    ROUND(
        100.0 * SUM(activated_customers)
        / NULLIF(SUM(new_customers), 0),
        2
    ) AS activation_rate,

    ROUND(
        100.0 * SUM(retained_90d)
        / NULLIF(SUM(new_customers), 0),
        2
    ) AS retention_90d_rate

FROM customer_lifecycle

GROUP BY segment

ORDER BY retention_90d_rate DESC;


/*
============================================================
13. CUSTOMER VALUE BY SEGMENT
============================================================

Question:
Does a higher acquisition cost make sense when
customer value is also higher?

This starts connecting acquisition performance with
downstream customer economics.
*/

SELECT
    segment,

    ROUND(
        AVG(avg_customer_value),
        2
    ) AS avg_customer_value,

    ROUND(
        100.0 * SUM(activated_customers)
        / NULLIF(SUM(new_customers), 0),
        2
    ) AS activation_rate,

    ROUND(
        100.0 * SUM(retained_90d)
        / NULLIF(SUM(new_customers), 0),
        2
    ) AS retention_rate

FROM customer_lifecycle

GROUP BY segment

ORDER BY avg_customer_value DESC;


/*
============================================================
14. ACQUISITION ECONOMICS BY SEGMENT
============================================================

Question:
Which segment creates the strongest balance between
acquisition cost and customer value?

This combines acquisition and lifecycle data.

It demonstrates why CPA should not be evaluated
without understanding the customer acquired.
*/

WITH acquisition AS (

    SELECT
        segment,

        SUM(spend) AS spend,
        SUM(customers) AS customers,

        ROUND(
            SUM(spend)
            / NULLIF(SUM(customers), 0),
            2
        ) AS cpa

    FROM campaign_performance

    GROUP BY segment
),

lifecycle AS (

    SELECT
        segment,

        AVG(avg_customer_value) AS avg_customer_value,

        100.0 * SUM(activated_customers)
        / NULLIF(SUM(new_customers), 0) AS activation_rate,

        100.0 * SUM(retained_90d)
        / NULLIF(SUM(new_customers), 0) AS retention_rate

    FROM customer_lifecycle

    GROUP BY segment
)

SELECT
    a.segment,

    a.cpa,

    ROUND(
        l.avg_customer_value,
        2
    ) AS avg_customer_value,

    ROUND(
        l.activation_rate,
        2
    ) AS activation_rate,

    ROUND(
        l.retention_rate,
        2
    ) AS retention_rate,

    ROUND(
        l.avg_customer_value
        / NULLIF(a.cpa, 0),
        2
    ) AS customer_value_to_cpa_ratio

FROM acquisition a

LEFT JOIN lifecycle l
    ON a.segment = l.segment

ORDER BY customer_value_to_cpa_ratio DESC;
