--1.a. Which prescriber had the highest total number of claims (totaled over all drugs)? 
--Report the npi and the total number of claims.
select  distinct npi,sum(total_claim_count) as total_claims
from public.prescription 
group by npi
order by total_claims desc
limit 1;
--b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.
select distinct pn.npi,p.nppes_provider_first_name,p.nppes_provider_last_org_name,
specialty_description,sum(pn.total_claim_count) total_claims from public.prescription pn
inner join prescriber p using(npi)
group by 1,2,3,4
order by total_claims desc
limit 1;
--2.a. Which specialty had the most total number of claims (totaled over all drugs)?
select specialty_description,sum(total_claim_count) total_claims from prescription
inner join prescriber using(npi)
group by prescriber.specialty_description;

--b. Which specialty had the most total number of claims for opioids?
select specialty_description,sum(total_claim_count) total_claims
from prescription
inner join prescriber using(npi)
inner join drug using (drug_name)
where drug.opioid_drug_flag ilike 'Y'
group by prescriber.specialty_description
order by 2 desc;

--c. **Challenge Question:** 
--Are there any specialties that appear in the prescriber table that have 
--no associated prescriptions in the prescription table?
(select specialty_description from prescriber)
except(select specialty_description from prescriber
inner join prescription using(npi));

-- d. **Difficult Bonus:** *
--Do not attempt until you have solved all other problems!* 
--For each specialty, report the percentage of total claims
--by that specialty which are for opioids.
--Which specialties have a high percentage of opioids?
select specialty_description,
sum(case when opioid_drug_flag='Y' then total_claim_count else 0 end) as opioid_total_claims,
sum(total_claim_count) total_claims,
concat(round((sum(case when opioid_drug_flag='Y' then total_claim_count else 0 end))/
sum(total_claim_count)*100,2),' %') opioid_percentage
from prescription
inner join prescriber using(npi)
inner join drug using (drug_name)
group by prescriber.specialty_description;

--3.a. Which drug (generic_name) had the highest total drug cost?
select d.generic_name ,p.total_drug_cost
from prescription p
inner join drug d on p.drug_name=d.drug_name
where p.total_drug_cost=(select max(total_drug_cost) from prescription);

--b. Which drug (generic_name) has the hightest total cost per day?
--**Bonus: Round your cost per day column to 2 decimal places. 
--Google ROUND to see how this works.**

select d.generic_name,
round(sum(p.total_drug_cost)/sum(p.total_day_supply),2) cost_per_day
from prescription p
inner join drug d on p.drug_name=d.drug_name
group by d.generic_name
order by 2 desc
limit 1;
--4.a. For each drug in the drug table, return the drug name 
--and then a column named 'drug_type' which says 'opioid' for drugs
--which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs 
--which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. 
--**Hint:** You may want to use a CASE expression for this. 
--See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/
select distinct drug_name,
(case
	when opioid_drug_flag ilike 'Y'  then 'opioid'
	when antibiotic_drug_flag ilike 'Y' then 'antibiotic'
	else 'neither'
	end) as drug_type
from drug;
--b. Building off of the query you wrote for part a, determine whether
--more was spent (total_drug_cost) on opioids or on antibiotics.
--Hint: Format the total costs as MONEY for easier comparision.
wiselect  drug_type, sum(total_drug_cost)::money  total_drug__cost 
from (select  distinct drug_name,(case
	when opioid_drug_flag ilike 'Y'  then 'opioid'
	when antibiotic_drug_flag ilike 'Y' then 'antibiotic'
	else 'neither'
	end) as drug_type,total_drug_cost
from drug
inner join prescription p using(drug_name))
where drug_type ilike 'opioid' or drug_type ilike 'antibiotic'
group by drug_type
order by total_drug__cost desc;
--5.a. How many CBSAs are in Tennessee? **Warning:**
--The cbsa table contains information for all sta tes, not just Tennessee.
select count(distinct cbsa) as "TN_cbsa_count" 
from cbsa 
inner join public.fips_county using(fipscounty)
where state='TN';
--b. Which cbsa has the largest combined population? 
--Which has the smallest? Report the CBSA name and total population.
(select cbsaname,sum(population) total_population, 'Largest Population' 
as Population_type from cbsa
inner join population using(fipscounty)
inner join fips_county using(fipscounty)
group by cbsaname
order by 2 desc limit 1)
union
(select cbsaname,sum(population) total_population, 'Smallest Population'
as Population_type from cbsa
inner join population using(fipscounty)
inner join fips_county using(fipscounty)
group by cbsaname
order by 2 limit 1);
--c. What is the largest (in terms of population) county 
--which is not included in a CBSA? Report the county name and population.
select  distinct f.county, 
sum(case 
	when f.fipscounty not in (select fipscounty from cbsa) then p.population
	else 0 end)
	as total_population
from fips_county f
inner join population p using(fipscounty)
group by f.county
order by total_population desc nulls last;
--6.a. Find all rows in the prescription table where total_claims
--is at least 3000. Report the drug_name and the total_claim_count.
select drug_name,total_claim_count from prescription 
where total_claim_count>=3000;

--b.For each instance that you found in part a, 
--add a column that indicates whether the drug is an opioid.
select drug_name,total_claim_count,
 (case when opioid_drug_flag ilike 'Y' then 'Opiod'
 else 'Not-Opioid' 
 end )as drug_type 
 from prescription 
 inner join drug using(drug_name)
where total_claim_count>=3000;
--c.Add another column to you answer from the previous part which gives 
--the prescriber first and last name associated with each row.
select drug_name,total_claim_count,
 (case when opioid_drug_flag ilike 'Y' then 'Opiod'
 else 'Not-Opioid' 
 end )as drug_type,
 nppes_provider_first_name||' '||nppes_provider_last_org_name fullname
 from prescription 
 inner join drug using(drug_name)
 inner join prescriber using(npi)
where total_claim_count>=3000;

--7.The goal of this exercise is to generate a full list of all pain management
--specialists in Nashville and the number of claims they had for each opioid. 
--**Hint:** The results from all 3 parts will have 637 rows.
select nppes_provider_first_name, nppes_provider_last_org_name,
drug.drug_name,
sum(total_claim_count)  total_claims
from public.prescription
inner join prescriber using(npi)
cross join drug 
where specialty_description ilike 'pain management' 
and nppes_provider_city ilike 'Nashville' and opioid_drug_flag ilike 'Y'
group by 1,2,drug.drug_name
--a. First, create a list of all npi/drug_name combinations for pain management 
--specialists (specialty_description = 'Pain Management) in the city of Nashville
--(nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y').
--**Warning:** Double-check your query before running it. 
--You will only need to use the prescriber and drug tables since you don't
--need the claims numbers yet.
select npi,drug.drug_name from prescriber
cross join  drug  
where specialty_description ilike 'pain management' 
and nppes_provider_city ilike 'NASHVILLE' and opioid_drug_flag ilike 'Y'
group by npi,drug.drug_name;

--b. Next, report the number of claims per drug per prescriber. 
--Be sure to include all combinations, whether or not the prescriber had any claims.
--You should report the npi, the drug name, and the number of claims (total_claim_count).
select npi,drug.drug_name,
sum(total_claim_count) total_claims
from prescriber
cross join  drug 
inner join prescription using(npi)
where specialty_description ilike 'pain management' 
and nppes_provider_city ilike 'NASHVILLE' and opioid_drug_flag ilike 'Y'
group by npi,drug.drug_name;
--c. Finally, if you have not done so already, fill in any missing values for 
--total_claim_count with 0. Hint - Google the COALESCE function.
select npi,drug.drug_name,sum(coalesce(total_claim_count,0)) total_claims
from prescription
cross join  drug 
inner join prescriber using(npi)
where specialty_description ilike 'pain management' 
and nppes_provider_city ilike 'Nashville' and opioid_drug_flag ilike 'Y'
group by npi,drug.drug_name
order by total_claims;




