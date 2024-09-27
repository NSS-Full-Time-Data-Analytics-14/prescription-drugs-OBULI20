--1. How many npi numbers appear in the prescriber table but not in the prescription table?
select count(*) prescription_npi
from ( 
select distinct npi from public.prescriber
except 
select distinct npi from public.prescription)
--2.    a. Find the top five drugs (generic_name) prescribed by prescribers with 
--the specialty of Family Practice.
select d.generic_name,count(p.drug_name) from public.prescription p
inner join public.drug d using(drug_name)
inner join public.prescriber pr using(npi)
where pr.specialty_description ilike 'Family Practice' 
group by 1
order by count(1) desc
limit 5;
--  b. Find the top five drugs (generic_name) prescribed by prescribers with 
--the specialty of Cardiology.
select d.generic_name from public.prescription p
inner join public.drug d using(drug_name)
inner join public.prescriber pr using(npi)
where pr.specialty_description ilike 'Cardiology' 
group by 1
order by count(1) desc
limit 5;
-- c. Which drugs are in the top five prescribed by Family Practice prescribers
--and Cardiologists? 
select d.generic_name from public.prescription p
inner join public.drug d using(drug_name)
inner join public.prescriber pr using(npi)
where pr.specialty_description in ('Family Practice','Cardiology')
group by p.drug_name,1
order by count(1) desc
limit 5;
--Combine what you did for parts a and b into a single query to answer this question.

--3. Your goal in this question is to generate a list of the top prescribers in 
--each of the major metropolitan areas of Tennessee.
-- a. First, write a query that finds the top 5 prescribers in Nashville 
--in terms of the total number of claims (total_claim_count) across all drugs.
--Report the npi, the total number of claims, and include a column showing the city.
select npi,sum(total_claim_count) total_number_of_claims, nppes_provider_city from prescription
inner join prescriber using(npi)
where  nppes_provider_city ilike 'NASHVILLE'
group by 1,3
order by 2 desc
limit 5
-- b. Now, report the same for Memphis.
select npi,sum(total_claim_count) total_number_of_claims, nppes_provider_city from prescription
inner join prescriber using(npi)
where  nppes_provider_city ilike 'memphis'
group by 1,3
order by 2 desc
limit 5
--c. Combine your results from a and b, along with the results for Knoxville and Chattanooga.

((select npi,sum(total_claim_count) total_number_of_claims, nppes_provider_city from prescription
inner join prescriber using(npi)
where  nppes_provider_city ilike 'NASHVILLE'
group by 1,3
order by 2 desc
limit 5)
UNION 
(select npi,sum(total_claim_count) total_number_of_claims, nppes_provider_city from prescription
inner join prescriber using(npi)
where  nppes_provider_city ilike 'memphis'
group by 1,3
order by 2 desc
limit 5))
UNION
((select npi,sum(total_claim_count) total_number_of_claims, nppes_provider_city from prescription
inner join prescriber using(npi)
where  nppes_provider_city ilike 'CHATTANOOGA'
group by 1,3
order by 2 desc
limit 5)
UNION 
(select npi,sum(total_claim_count) total_number_of_claims, nppes_provider_city from prescription
inner join prescriber using(npi)
where  nppes_provider_city ilike 'KNOXVILLE'
group by 1,3
order by 2 desc
limit 5))
ORDER BY 3,2 DESC;

--4. Find all counties which had an above-average number of overdose deaths. 
--Report the county name and number of overdose deaths.
SELECT county,sum(overdose_deaths) over_deaths
FROM public.overdose_deaths
INNER JOIN public.fips_county on 
overdose_deaths.fipscounty=fips_county.fipscounty::int 
WHERE overdose_deaths>
(SELECT AVG(overdose_deaths) FROM public.overdose_deaths)
group by county
order by over_deaths desc;
select * from public.fips_county
--5.a. Write a query that finds the total population of Tennessee.
select sum(population) Tennessee_population  from public.population
where fipscounty in ( 
select fipscounty from public.fips_county where state ilike 'TN')

  
--b. Build off of the query that you wrote in part a to write a query 
--that returns for each county that county's name, its population,
--and the percentage of the total population of Tennessee that is contained in that county.

with TN_pop as 
(select fipscounty,sum(population) population  from public.population
INNER JOIN fips_county using (fipscounty)
where state ilike 'TN'
group by fipscounty )

select county,sum(population) county_population,
(round(100*(sum(population)/
(select sum(population) TN_population  from public.population
INNER JOIN fips_county using (fipscounty)
where state = 'TN') ),2))||' %' "population_%_onTN"
from public.fips_county
inner join TN_pop using(fipscounty)
group by county order by 2 desc;




