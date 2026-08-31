-- Stage A.29: Tome of Talents is granted during Random Draft initialization.
-- It must not be convertible into transferable money by repeated character creation.
UPDATE `item_template`
SET `SellPrice` = 0
WHERE `entry` = 25462;
