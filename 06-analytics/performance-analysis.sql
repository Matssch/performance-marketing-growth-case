-- All campaign data used in this analysis is synthetic.
-- It recreates the structure and scale of the real growth problem
-- without exposing confidential company information.

/*
Performance Marketing Growth Case
---------------------------------
Company: anonymised Dutch mobility company

Purpose:
Use marketing and funnel data to answer practical growth questions.

The queries focus on:
- Channel performance
- CPA
- Customer conversion
- Segment performance
- Funnel efficiency
- Performance trends
- Incremental acquisition efficiency

The underlying dataset will be synthetic and based on the structure
of the real growth problem. No confidential company data is used.
*/


/*
--------------------------------------------------
01. CHANNEL PERFORMANCE
--------------------------------------------------

Question:
Which acquisition channels are creating the most customers,
and what does that cost?

This is the first view I would use to understand the acquisition mix.
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
