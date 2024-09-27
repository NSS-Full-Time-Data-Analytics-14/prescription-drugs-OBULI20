--1. Write a query which returns the total number of claims for these two groups. 
--Your output should look like this: 

specialty_description         |total_claims|
------------------------------|------------|
Interventional Pain Management|       55906|
Pain Management               |       70853|

select specialty_description,sum(total_claim_count) total_claims
from prescription
inner join prescriber using(npi)
where specialty_description ilike '%Pain Management%'
group by specialty_description;


--2. Now, let's say that we want our output to also include the total number
--of claims between these two groups. Combine two queries with the UNION keyword 
--to accomplish this. Your output should look like this:

specialty_description         |total_claims|
------------------------------|------------|
                              |      126759|
Interventional Pain Management|       55906|
Pain Management               |       70853|


(select specialty_description,sum(total_claim_count) total_claims
from prescription
inner join prescriber using(npi)
where specialty_description ilike '%PAin Management%'
group by specialty_description)
union 
(select '',sum(case when specialty_description ilike '%PAin Management%' 
then total_claim_count  end) as total_claims
from prescription
inner join prescriber using(npi)) 
order by specialty_description;

--3. Now, instead of using UNION, make use of GROUPING SETS 
--(https://www.postgresql.org/docs/10/queries-table-expressions.html#QUERIES-GROUPING-SETS) 
--to achieve the same output.
select coalesce(specialty_description,'') specialty_description, sum(total_claim_count) total_claims
from prescription
inner join prescriber using(npi)
where specialty_description ilike '%PAin Management%'
group by 
grouping sets ((specialty_description),());

---or---
select coalesce(specialty_description,'') specialty_description, sum(total_claims) total_claims
from (select specialty_description,sum(total_claim_count) total_claims
from prescription
inner join prescriber using(npi)
where specialty_description ilike '%PAin Management%'
group by specialty_description) as claims
group by  grouping sets ((specialty_description,total_claims),())
order by specialty_description nulls first;
--4. In addition to comparing the total number of prescriptions by specialty, 
--let's also bring in information about the number of opioid vs. non-opioid claims
--by these two specialties. Modify your query (still making use of GROUPING SETS so
--that your output also shows the total number of opioid claims vs. non-opioid claims
--by these two specialites:

specialty_description         |opioid_drug_flag|total_claims|
------------------------------|----------------|------------|
                              |                |      129726|
                              |Y               |       76143|
                              |N               |       53583|
Pain Management               |                |       72487|
Interventional Pain Management|                |       57239|

select coalesce(specialty_description,'') specialty_description,coalesce(opioid_drug_flag,'') opioid_drug_flag, 
sum(total_claim_count) total_claims
from prescription
inner join prescriber using(npi)
inner join drug using (drug_name)
where specialty_description ilike '%PAin Management%'
group by 
grouping sets ((specialty_description),(opioid_drug_flag),())
order by specialty_description nulls first;

--5. Modify your query by replacing the GROUPING SETS with ROLLUP(opioid_drug_flag, 
--specialty_description). How is the result different from the output from 
--the previous query?
select coalesce(specialty_description,''),coalesce(opioid_drug_flag,'')  opioid_drug_flag, 
sum(total_claim_count) total_claims
from prescription
inner join prescriber using(npi)
inner join drug using (drug_name)
where specialty_description ilike '%PAin Management%'
group by
rollup (opioid_drug_flag,specialty_description)
order by specialty_description nulls first,opioid_drug_flag nulls first;

--6. Switch the order of the variables inside the ROLLUP. 
--That is, use ROLLUP(specialty_description, opioid_drug_flag). 
--How does this change the result?
select coalesce(specialty_description,''),coalesce(opioid_drug_flag,'')  opioid_drug_flag, 
sum(total_claim_count) total_claims
from prescription
inner join prescriber using(npi)
inner join drug using (drug_name)
where specialty_description ilike '%PAin Management%'
group by
rollup (specialty_description,opioid_drug_flag)
order by specialty_description nulls first,opioid_drug_flag nulls first;

--7. Finally, change your query to use the CUBE function instead of ROLLUP. 
--How does this impact the output?
select coalesce(specialty_description,'') specialty_description,
coalesce(opioid_drug_flag,'')  opioid_drug_flag, 
sum(total_claim_count) total_claims
from prescription
inner join prescriber using(npi)
inner join drug using (drug_name)
where specialty_description ilike '%PAin Management%'
group by opioid_drug_flag,
cube (specialty_description)
--8. In this question, your goal is to create a pivot table showing for each 
--of the 4 largest cities in Tennessee (Nashville, Memphis, Knoxville, and Chattanooga), 
--the total claim count for each of six common types of opioids: 
--Hydrocodone, Oxycodone, Oxymorphone, Morphine, Codeine, and Fentanyl. 
--For the purpose of this question, we will put a drug into one of the six listed 
--categories if it has the category name as part of its generic name.
--For example, we could count both of "ACETAMINOPHEN WITH CODEINE" and 
--"CODEINE SULFATE" as being "CODEINE" for the purposes of this question.

The end result of this question should be a table formatted like this:

city       |codeine|fentanyl|hyrdocodone|morphine|oxycodone|oxymorphone|
-----------|-------|--------|-----------|--------|---------|-----------|
CHATTANOOGA|   1323|    3689|      68315|   12126|    49519|       1317|
KNOXVILLE  |   2744|    4811|      78529|   20946|    84730|       9186|
MEMPHIS    |   4697|    3666|      68036|    4898|    38295|        189|
NASHVILLE  |   2043|    6119|      88669|   13572|    62859|       1261|
SELECT *
FROM crosstab(
    $$
    SELECT 
        nppes_provider_city AS city,
        CASE 
            WHEN generic_name ILIKE '%codeine%' THEN 'codeine'
            WHEN generic_name ILIKE '%fentanyl%' THEN 'fentanyl'
            WHEN generic_name ILIKE '%hydrocodone%' THEN 'hydrocodone'
            WHEN generic_name ILIKE '%morphine%' THEN 'morphine'
            WHEN generic_name ILIKE '%oxycodone%' THEN 'oxycodone'
            WHEN generic_name ILIKE '%oxymorphone%' THEN 'oxymorphone' 
        END AS drug_category,
        SUM(total_claim_count)::int AS total_claims
    FROM 
        prescription
	INNER JOIN 
        prescriber USING (npi)
    INNER JOIN 
        drug USING (drug_name)
    WHERE 
        nppes_provider_city in ('NASHVILLE','MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
    GROUP BY 
        city, drug_category
    ORDER BY 
        city
    $$
) AS well_done(
    city TEXT,
    codeine INT,
    fentanyl INT,
    hydrocodone INT,
    morphine INT,
    oxycodone INT,
    oxymorphone INT
);
select pr.nppes_provider_city city,
	  sum(case when p.drug_name ilike '%codeine%' then p.total_claim_count end) as "codeine",
     sum(case when p.drug_name ilike '%fentanyl%' then  p.total_claim_count end) as "fentanyl",
     sum(case when p.drug_name ilike '%hydrocodone%' then coalesce(p.total_claim_count,0) end) as "hydrocodone",
	 sum(case when p.drug_name ilike '%morphine%' then p.total_claim_count end ) as "morphine",
	 sum(case when p.drug_name ilike '%oxycodone%' then coalesce(p.total_claim_count,0) end ) as  "oxycodone",
     sum(case when p.drug_name ilike '%oxymorphone%' then p.total_claim_count end) as  "oxymorphone"
from prescriber pr
left join prescription p using (npi)
where pr.nppes_provider_city in ('NASHVILLE', 'MEMPHIS', 'KNOXVILLE','CHATTANOOGA')
group by (city)
order by city;

--For this question, you should look into use the crosstab function,
--which is part of the tablefunc extension (https://www.postgresql.org/docs/9.5/tablefunc.html).
--In order to use this function, you must (one time per database) run the command
--CREATE EXTENSION tablefunc;

--Hint #1: First write a query which will label each drug in the drug table using the
--six categories listed above.
--Hint #2: In order to use the crosstab function, you need to first write a query which
--will produce a table with one row_name column, one category column, and one value column. 
--So in this case, you need to have a city column, a drug label column, and a total claim count column.
--Hint #3: The sql statement that goes inside of crosstab must be surrounded by single quotes.
--If the query that you are using also uses single quotes, you'll need to escape them by turning
--them into double-single quotes.
CREATE EXTENSION tablefunc;
SELECT *
FROM crosstab(
    $$
    SELECT 
        nppes_provider_city AS city,
        CASE 
            WHEN drug_name ILIKE '%codeine%' THEN 'codeine'
            WHEN drug_name ILIKE '%fentanyl%' THEN 'fentanyl'
            WHEN drug_name ILIKE '%hydrocodone%' THEN 'hydrocodone'
            WHEN drug_name ILIKE '%morphine%' THEN 'morphine'
            WHEN drug_name ILIKE '%oxycodone%' THEN 'oxycodone'
            WHEN drug_name ILIKE '%oxymorphone%' THEN 'oxymorphone' 
        END AS drug_category,
        SUM(total_claim_count)::int AS total_claims
    FROM 
        prescription
    INNER JOIN 
        prescriber USING (npi)
    INNER JOIN 
        drug USING (drug_name)
    WHERE 
        nppes_provider_city in ('NASHVILLE','MEMPHIS', 'KNOXVILLE', 'CHATTANOOGA')
    GROUP BY 
        city, drug_category
    ORDER BY 
        city
    $$
) AS well_done(
    city TEXT,
    codeine INT,
    fentanyl INT,
    hydrocodone INT,
    morphine INT,
    oxycodone INT,
    oxymorphone INT
);

