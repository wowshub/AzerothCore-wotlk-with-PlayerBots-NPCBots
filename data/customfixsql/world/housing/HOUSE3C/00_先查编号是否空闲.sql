-- Run FIRST. All three results must be empty.
SELECT entry, name FROM gameobject_template WHERE entry BETWEEN 9200701 AND 9200716;
SELECT catalog_id, name_zh FROM reborn_housing_catalog WHERE catalog_id BETWEEN 10701 AND 10716;
SELECT catalog_id FROM reborn_housing_recipe WHERE catalog_id BETWEEN 10701 AND 10716;
