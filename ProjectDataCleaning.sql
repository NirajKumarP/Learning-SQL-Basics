Use Datacleaning;
-- The PropertyAddress column has a NULL value but the address of that same ParcelID is available in a row above it.
-- We need to update the NULL vaule using the PropertyAddress present in the table for the same ParcelId.

Select a.parcelid, a.propertyaddress, b.parcelID, b.propertyaddress , ifnull(a.PropertyAddress,b.propertyaddress) as UpdatedAddress
FROM NH a 
Join NH b
	on a.ParcelId = b.ParcelID 
    and a.UniqueID <> b.UniqueID
Where a.propertyaddress is not null;

-- Now that we know the NULL values needs to be fixed, lets update the values
Update NH a 
Inner Join NH b
	on a.ParcelId = b.ParcelID 
    and a.UniqueID <> b.UniqueID
SET a.PropertyAddress = ifnull(a.PropertyAddress,b.propertyaddress);

-- Checking the results
SELECT *
FROM NH
WHERE propertyaddress is not null;

-- The values in column "SoldAsVacant" are marked as N,Y,No,Yes. Lets make this all in same format as either No or Yes
SELECT soldasvacant,
Case When soldasvacant = "N" Then "No" 
	 When soldasvacant = "Y" Then "Yes" 
	 ELSE soldasvacant
     END As soldasvacantupdated
FROM NH;

-- Updating the final table
UPDATE NH
SET soldasvacant = Case When soldasvacant = "N" Then "No" 
						When soldasvacant = "Y" Then "Yes" 
						ELSE soldasvacant
						END;
                        
-- Checking the results
SELECT *
FROM NH
WHERE soldasvacant ='N' or soldasvacant = 'Y';

-- The OwnerAddress contains the address followed by City name and State Name all delimited by a ",". 
-- Let's split it into three separate columns.
SELECT substring_index(PropertyAddress,",",1) As PropertyAddressUpdated
, substring_index(PropertyAddress,",",-1) as PropertyCity
FROM NH;

-- Creating two new columns to input these separated values.
ALTER TABLE NH
ADD OwnerCity varchar(250),
ADD OwnerState Varchar(250);

-- The names are input incorrectly to learn how to rename a column. Fixing the column names.
ALTER TABLE NH
Rename column ownercity to PropertyCity,
Rename column ownerstate to PropertyAddressUpdated;

-- Updating the new values in the respective columns
UPDATE NH 
SET PropertyAddressUpdated = substring_index(PropertyAddress,",",1);

UPDATE NH
SET PropertyCity = substring_index(PropertyAddress,",",-1);

-- Checking if the table has been updated
SELECT * 
FROM NH;

-- Let's identify if we have any duplicate datas
WITH CTE_Dup AS 
(
SELECT UniqueID, ParcelID, 
	ROW_NUMBER() Over (
				 PARTITION BY ParcelID, 
							  PropertyAddress,
							  SaleDate,
							  SalePrice,
							  LegalReference,
							  OwnerName
				 Order BY UniqueID 
                 ) as row_num
FROM NH
)
SELECT * 
FROM CTE_Dup
Where row_num > 1;

-- No Duplicates are there in this existing data. 

-- Finally lets just create a view which consists of only the relavant columns which we need to Analyse the data.
CREATE OR REPLACE VIEW NationalHousing AS
SELECT UniqueID,
	   ParcelID,
       LandUse,
       PropertyAddressUpdated,
       PropertyCity,
       OwnerName,
       OwnerAddress,
       SaleDate,
       SalePrice,
       LandValue,
       BuildingValue,
       TotalValue,
       LegalReference,
       SoldAsVacant
FROM NH
WHERE soldAsVacant = "No";

-- Checking the newly Created View
SELECT *
FROM NationalHousing;

