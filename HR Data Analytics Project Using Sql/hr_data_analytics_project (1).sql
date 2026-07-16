CREATE TABLE hr_data (
    emp_id INT PRIMARY KEY,
    age INT,
    attrition VARCHAR(3),
    business_travel VARCHAR(50),
    daily_rate INT,
    department VARCHAR(50),
    distance_from_home INT,
    education INT,
    education_field VARCHAR(50),
    employee_count INT,
    employee_number INT,
    environment_satisfaction INT,
    gender VARCHAR(10),
    hourly_rate INT,
    job_involvement INT,
    job_level INT,
    job_role VARCHAR(50),
    job_satisfaction INT,
    marital_status VARCHAR(20),
    monthly_income INT,
    monthly_rate INT,
    num_companies_worked INT,
    over18 VARCHAR(1),
    over_time VARCHAR(3),
    percent_salary_hike INT,
    performance_rating INT,
    relationship_satisfaction INT,
    standard_hours INT,
    stock_option_level INT,
    total_working_years INT,
    training_times_last_year INT,
    work_life_balance INT,
    years_at_company INT,
    years_in_current_role INT,
    years_since_last_promotion INT,
    years_with_curr_manager INT
);

-- 1. Total Number of Employees
SELECT COUNT(*) AS total_employees FROM hr_data;

-- 2. Number of Employees by Department
SELECT department, COUNT(*) AS num_employees
FROM hr_data
GROUP BY department
ORDER BY num_employees DESC;

-- 3. Number of Employees by Job Role
SELECT job_role, COUNT(*) AS num_employees
FROM hr_data
GROUP BY job_role
ORDER BY num_employees DESC;

-- 4. Number of Employees by Gender
SELECT gender, COUNT(*) AS num_employees
FROM hr_data
GROUP BY gender;

-- 5. Average Age of Employees
SELECT AVG(age) AS average_age FROM hr_data;

-- 6. Distribution of Employees by Age Group
SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 55 THEN '46-55'
        ELSE '56+' 
    END AS age_group,
    COUNT(*) AS num_employees
FROM hr_data
GROUP BY age_group
ORDER BY age_group;

-- 7. Overall Attrition Count (Yes vs. No)
SELECT attrition, COUNT(*) AS attrition_count
FROM hr_data
GROUP BY attrition;

-- 8. Overall Attrition Rate (%)
SELECT 
    (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate_percentage
FROM hr_data;

-- 9. Attrition Rate by Department
SELECT department, 
       SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY department
ORDER BY attrition_rate DESC;

-- 10. Attrition Rate by Job Role
SELECT job_role, 
       SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY job_role
ORDER BY attrition_rate DESC;

-- 11. Attrition Rate by Gender
SELECT gender, 
       SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY gender;

-- 12. Attrition Rate by Age Group
SELECT 
    CASE 
        WHEN age BETWEEN 18 AND 25 THEN '18-25'
        WHEN age BETWEEN 26 AND 35 THEN '26-35'
        WHEN age BETWEEN 36 AND 45 THEN '36-45'
        WHEN age BETWEEN 46 AND 55 THEN '46-55'
        ELSE '56+' 
    END AS age_group,
    SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
    (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY age_group
ORDER BY age_group;

-- 13. Attrition Rate by Marital Status
SELECT marital_status, 
       SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY marital_status;

-- 14. Average Monthly Income across all employees
SELECT AVG(monthly_income) AS avg_monthly_income FROM hr_data;

-- 15. Average Monthly Income by Department
SELECT department, AVG(monthly_income) AS avg_income
FROM hr_data
GROUP BY department
ORDER BY avg_income DESC;

-- 16. Average Monthly Income by Job Role
SELECT job_role, AVG(monthly_income) AS avg_income
FROM hr_data
GROUP BY job_role
ORDER BY avg_income DESC;

-- 17. Average Monthly Income by Gender
SELECT gender, AVG(monthly_income) AS avg_income
FROM hr_data
GROUP BY gender;

-- 18. Average Monthly Income for Employees who Left (Attrition = Yes)
SELECT AVG(monthly_income) AS avg_income_attrition_yes
FROM hr_data
WHERE attrition = 'Yes';

-- 19. Average Monthly Income for Current Employees (Attrition = No)
SELECT AVG(monthly_income) AS avg_income_attrition_no
FROM hr_data
WHERE attrition = 'No';

-- 20. Average Monthly Income by Education Field
SELECT education_field, AVG(monthly_income) AS avg_income
FROM hr_data
GROUP BY education_field
ORDER BY avg_income DESC;

-- 21. Overall Average Job Satisfaction (Scale 1-4)
SELECT AVG(job_satisfaction) AS avg_job_satisfaction FROM hr_data;

-- 22. Average Job Satisfaction by Department
SELECT department, AVG(job_satisfaction) AS avg_satisfaction
FROM hr_data
GROUP BY department
ORDER BY avg_satisfaction DESC;

-- 23. Average Job Satisfaction by Job Role
SELECT job_role, AVG(job_satisfaction) AS avg_satisfaction
FROM hr_data
GROUP BY job_role
ORDER BY avg_satisfaction DESC;

-- 24. Average Job Satisfaction for Employees who Left
SELECT AVG(job_satisfaction) AS avg_satisfaction_attrition_yes
FROM hr_data
WHERE attrition = 'Yes';

-- 25. Average Job Satisfaction for Current Employees
SELECT AVG(job_satisfaction) AS avg_satisfaction_attrition_no
FROM hr_data
WHERE attrition = 'No';

-- 26. Overall Average Environment Satisfaction
SELECT AVG(environment_satisfaction) AS avg_env_satisfaction FROM hr_data;

-- 27. Average Environment Satisfaction by Department
SELECT department, AVG(environment_satisfaction) AS avg_env_satisfaction
FROM hr_data
GROUP BY department
ORDER BY avg_env_satisfaction DESC;

-- 28. Average Environment Satisfaction for Employees who Left
SELECT AVG(environment_satisfaction) AS avg_env_sat_attrition_yes
FROM hr_data
WHERE attrition = 'Yes';

-- 29. Overall Average Work-Life Balance
SELECT AVG(work_life_balance) AS avg_work_life_balance FROM hr_data;

-- 30. Average Work-Life Balance for Employees who Left
SELECT AVG(work_life_balance) AS avg_wlb_attrition_yes
FROM hr_data
WHERE attrition = 'Yes';

-- 31. Distribution of Overtime Workers
SELECT over_time, COUNT(*) AS num_employees
FROM hr_data
GROUP BY over_time;

-- 32. Attrition Rate by Overtime Status
SELECT over_time, 
       SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY over_time;

-- 33. Distribution of Business Travel Frequency
SELECT business_travel, COUNT(*) AS num_employees
FROM hr_data
GROUP BY business_travel;

-- 34. Attrition Rate by Business Travel Frequency
SELECT business_travel, 
       SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY business_travel;

-- 35. Average Distance from Home for all employees
SELECT AVG(distance_from_home) AS avg_distance FROM hr_data;

-- 36. Average Distance from Home for Employees who Left
SELECT AVG(distance_from_home) AS avg_distance_attrition_yes
FROM hr_data
WHERE attrition = 'Yes';

-- 37. Average Distance from Home for Current Employees
SELECT AVG(distance_from_home) AS avg_distance_attrition_no
FROM hr_data
WHERE attrition = 'No';

-- 38. Average Years at Company
SELECT AVG(years_at_company) AS avg_years_at_company FROM hr_data;

-- 39. Average Years at Company for Employees who Left
SELECT AVG(years_at_company) AS avg_years_attrition_yes
FROM hr_data
WHERE attrition = 'Yes';

-- 40. Average Years in Current Role
SELECT AVG(years_in_current_role) AS avg_years_in_role FROM hr_data;

-- 41. Average Years Since Last Promotion
SELECT AVG(years_since_last_promotion) AS avg_years_since_promotion FROM hr_data;

-- 42. Average Years with Current Manager
SELECT AVG(years_with_curr_manager) AS avg_years_with_manager FROM hr_data;

-- 43. Average Tenure (Years at Company) by Department
SELECT department, AVG(years_at_company) AS avg_tenure
FROM hr_data
GROUP BY department
ORDER BY avg_tenure DESC;

-- 44. Average Salary Hike Percentage
SELECT AVG(percent_salary_hike) AS avg_salary_hike FROM hr_data;

-- 45. Average Salary Hike by Department
SELECT department, AVG(percent_salary_hike) AS avg_hike
FROM hr_data
GROUP BY department
ORDER BY avg_hike DESC;

-- 46. Average Salary Hike by Job Role
SELECT job_role, AVG(percent_salary_hike) AS avg_hike
FROM hr_data
GROUP BY job_role
ORDER BY avg_hike DESC;

-- 47. Average Salary Hike for Employees who Left
SELECT AVG(percent_salary_hike) AS avg_hike_attrition_yes
FROM hr_data
WHERE attrition = 'Yes';

-- 48. Distribution of Performance Ratings
SELECT performance_rating, COUNT(*) AS num_employees
FROM hr_data
GROUP BY performance_rating;

-- 49. Attrition Rate by Performance Rating
SELECT performance_rating, 
       SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_count,
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY performance_rating;

-- 50. Average Training Times Last Year
SELECT AVG(training_times_last_year) AS avg_training_times FROM hr_data;

-- 51. Average Training Times by Department
SELECT department, AVG(training_times_last_year) AS avg_training
FROM hr_data
GROUP BY department
ORDER BY avg_training DESC;

-- 52. Employee Count by Education Field
SELECT education_field, COUNT(*) AS num_employees
FROM hr_data
GROUP BY education_field
ORDER BY num_employees DESC;

-- 53. Employee Count by Education Level
SELECT education, COUNT(*) AS num_employees
FROM hr_data
GROUP BY education
ORDER BY education;

-- 54. Employee Count by Number of Companies Worked Prior
SELECT num_companies_worked, COUNT(*) AS num_employees
FROM hr_data
GROUP BY num_companies_worked
ORDER BY num_companies_worked;

-- 55. Employee Count by Stock Option Level
SELECT stock_option_level, COUNT(*) AS num_employees
FROM hr_data
GROUP BY stock_option_level
ORDER BY stock_option_level;

-- 56. Average Monthly Income by Education Level
SELECT AVG(monthly_income) AS avg_income, education
FROM hr_data
GROUP BY education
ORDER BY education;

-- 57. Employee Count by Job Level
SELECT job_level, COUNT(*) AS num_employees
FROM hr_data
GROUP BY job_level
ORDER BY job_level;

-- 58. Average Monthly Income by Job Level
SELECT job_level, AVG(monthly_income) AS avg_income
FROM hr_data
GROUP BY job_level
ORDER BY job_level;

-- 59. Headcount by Department and Job Role
SELECT department, job_role, COUNT(*) AS headcount
FROM hr_data
GROUP BY department, job_role
ORDER BY department, headcount DESC;

-- 60. Headcount by Gender and Department
SELECT gender, department, COUNT(*) AS headcount
FROM hr_data
GROUP BY gender, department
ORDER BY department, gender;

-- 61. Attrition Rate by Distance from Home Categories
SELECT 
    CASE 
        WHEN distance_from_home <= 10 THEN 'Near (0-10km)'
        WHEN distance_from_home BETWEEN 11 AND 20 THEN 'Medium (11-20km)'
        ELSE 'Far (>20km)' 
    END AS distance_category,
    COUNT(*) AS num_employees,
    (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY distance_category;

-- 62. Income Range (Min, Max, Avg) by Job Role
SELECT job_role, 
       MIN(monthly_income) AS min_income,
       MAX(monthly_income) AS max_income,
       AVG(monthly_income) AS avg_income
FROM hr_data
GROUP BY job_role;

-- 63. Age Range (Min, Max, Avg) by Department
SELECT department, 
       MIN(age) AS min_age,
       MAX(age) AS max_age,
       AVG(age) AS avg_age
FROM hr_data
GROUP BY department;

-- 64. Attrition Rate by Tenure (Years at Company) Groups
SELECT 
    CASE 
        WHEN years_at_company <= 2 THEN '0-2 Years'
        WHEN years_at_company BETWEEN 3 AND 5 THEN '3-5 Years'
        WHEN years_at_company BETWEEN 6 AND 10 THEN '6-10 Years'
        ELSE '10+ Years' 
    END AS tenure_group,
    (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY tenure_group
ORDER BY tenure_group;

-- 65. Employee Count by Job Involvement Level
SELECT job_involvement, COUNT(*) AS num_employees
FROM hr_data
GROUP BY job_involvement;

-- 66. Attrition Rate by Job Involvement Level
SELECT job_involvement, 
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY job_involvement;

-- 67. Employee Count by Relationship Satisfaction Level
SELECT relationship_satisfaction, COUNT(*) AS num_employees
FROM hr_data
GROUP BY relationship_satisfaction;

-- 68. Attrition Rate by Relationship Satisfaction Level
SELECT relationship_satisfaction, 
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY relationship_satisfaction;

-- 69. Combined Satisfaction Metrics (Job, Env, Rel) by Department
SELECT department, 
       AVG(job_satisfaction) AS avg_job_sat,
       AVG(environment_satisfaction) AS avg_env_sat,
       AVG(relationship_satisfaction) AS avg_rel_sat
FROM hr_data
GROUP BY department;

-- 70. Attrition Rate by Salary Hike Tiers
SELECT 
    CASE 
        WHEN percent_salary_hike <= 13 THEN 'Low (11-13%)'
        WHEN percent_salary_hike BETWEEN 14 AND 18 THEN 'Medium (14-18%)'
        ELSE 'High (19-25%)' 
    END AS hike_tier,
    COUNT(*) AS employee_count,
    (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY hike_tier;

-- 71. Overtime Distribution across Departments
SELECT over_time, department, COUNT(*) AS num_employees
FROM hr_data
GROUP BY over_time, department
ORDER BY department, over_time;

-- 72. Gender Distribution across Job Levels
SELECT gender, job_level, COUNT(*) AS count
FROM hr_data
GROUP BY gender, job_level
ORDER BY job_level, gender;

-- 73. Average Income by Marital Status
SELECT marital_status, AVG(monthly_income) AS avg_income
FROM hr_data
GROUP BY marital_status;

-- 74. Demographic Breakdown (Marital Status & Gender)
SELECT marital_status, gender, COUNT(*) AS count
FROM hr_data
GROUP BY marital_status, gender
ORDER BY marital_status, gender;

-- 75. Education Field Distribution across Departments
SELECT education_field, department, COUNT(*) AS count
FROM hr_data
GROUP BY education_field, department
ORDER BY department, count DESC;

-- 76. Total Payroll (Monthly Income Sum) by Department
SELECT department, SUM(monthly_income) AS total_payroll
FROM hr_data
GROUP BY department
ORDER BY total_payroll DESC;

-- 77. Total Payroll by Job Role
SELECT job_role, SUM(monthly_income) AS total_payroll
FROM hr_data
GROUP BY job_role
ORDER BY total_payroll DESC;

-- 78. Average Time Since Last Promotion by Department
SELECT department, AVG(years_since_last_promotion) AS avg_years_no_promo
FROM hr_data
GROUP BY department;

-- 79. Average Time Since Last Promotion by Job Role
SELECT job_role, AVG(years_since_last_promotion) AS avg_years_no_promo
FROM hr_data
GROUP BY job_role
ORDER BY avg_years_no_promo DESC;

-- 80. Average Time Since Last Promotion for Employees who Left
SELECT AVG(years_since_last_promotion) AS avg_promo_attrition_yes
FROM hr_data
WHERE attrition = 'Yes';

-- 81. Average Time with Current Manager by Department
SELECT department, AVG(years_with_curr_manager) AS avg_years_with_manager
FROM hr_data
GROUP BY department;

-- 82. Average Total Working Experience by Department
SELECT department, AVG(total_working_years) AS avg_total_experience
FROM hr_data
GROUP BY department;

-- 83. Average Total Working Experience by Job Role
SELECT job_role, AVG(total_working_years) AS avg_total_experience
FROM hr_data
GROUP BY job_role
ORDER BY avg_total_experience DESC;

-- 84. Gender Ratio by Department
SELECT department, 
       SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS male_count,
       SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS female_count,
       (SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS female_percentage
FROM hr_data
GROUP BY department;

-- 85. Gender Distribution by Job Role
SELECT job_role, 
       SUM(CASE WHEN gender = 'Male' THEN 1 ELSE 0 END) AS male_count,
       SUM(CASE WHEN gender = 'Female' THEN 1 ELSE 0 END) AS female_count
FROM hr_data
GROUP BY job_role;

-- 86. Specific Age Distribution (Count per exact year of age)
SELECT age, COUNT(*) AS num_employees
FROM hr_data
GROUP BY age
ORDER BY age;

-- 87. Top 10 Most Common Monthly Incomes (Exact values)
SELECT monthly_income, COUNT(*) AS count
FROM hr_data
GROUP BY monthly_income
ORDER BY count DESC
LIMIT 10;

-- 88. Top 10 Most Common Commute Distances
SELECT distance_from_home, COUNT(*) AS count
FROM hr_data
GROUP BY distance_from_home
ORDER BY count DESC
LIMIT 10;

-- 89. Distribution of Total Working Years
SELECT total_working_years, COUNT(*) AS count
FROM hr_data
GROUP BY total_working_years
ORDER BY total_working_years;

-- 90. Distribution of Years at the Company
SELECT years_at_company, COUNT(*) AS count
FROM hr_data
GROUP BY years_at_company
ORDER BY years_at_company;

-- 91. Departments with High Attrition (Filtering grouped results using HAVING)
SELECT department, 
       COUNT(*) AS total_employees,
       SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) AS attrition_yes,
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY department
HAVING COUNT(*) > 50;

-- 92. High-Paying Job Roles with their Attrition Rates
SELECT job_role, 
       COUNT(*) AS total_employees,
       AVG(monthly_income) AS avg_income,
       (SUM(CASE WHEN attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0) / COUNT(*) AS attrition_rate
FROM hr_data
GROUP BY job_role
HAVING AVG(monthly_income) > 5000;

-- 93. Departments with Low Average Job Satisfaction
SELECT department, 
       AVG(job_satisfaction) AS avg_satisfaction
FROM hr_data
GROUP BY department
HAVING AVG(job_satisfaction) < 3.0;

-- 94. Education Fields Earning Above Company Average (Using Subquery in HAVING)
SELECT education_field, 
       AVG(monthly_income) AS avg_income
FROM hr_data
GROUP BY education_field
HAVING AVG(monthly_income) > (SELECT AVG(monthly_income) FROM hr_data);

-- 95. Departments with Total Payroll Exceeding 1 Million
SELECT department, 
       SUM(monthly_income) AS total_payroll
FROM hr_data
GROUP BY department
HAVING SUM(monthly_income) > 1000000;

-- 96. Job Roles with Maximum Income Potential Over 15k
SELECT job_role, 
       MAX(monthly_income) AS max_income
FROM hr_data
GROUP BY job_role
HAVING MAX(monthly_income) > 15000;

-- 97. Average Income Comparison: Under 30 vs. 30 and Over
SELECT 
    CASE 
        WHEN age < 30 THEN 'Under 30'
        ELSE '30 and Over'
    END AS age_category,
    AVG(monthly_income) AS avg_income
FROM hr_data
GROUP BY age_category;

-- 98. Departments with More Than 10 Attritions (Focusing on raw count)
SELECT department, 
       COUNT(*) AS num_employees
FROM hr_data
WHERE attrition = 'Yes'
GROUP BY department
HAVING COUNT(*) > 10;

-- 99. Job Roles with Average Tenure Greater Than 5 Years
SELECT job_role, 
       AVG(years_at_company) AS avg_tenure
FROM hr_data
GROUP BY job_role
HAVING AVG(years_at_company) > 5;

-- 100. Departments with High Overtime Reliance (>20 employees on overtime)
SELECT department, 
       SUM(CASE WHEN over_time = 'Yes' THEN 1 ELSE 0 END) AS overtime_count
FROM hr_data
GROUP BY department
HAVING SUM(CASE WHEN over_time = 'Yes' THEN 1 ELSE 0 END) > 20;