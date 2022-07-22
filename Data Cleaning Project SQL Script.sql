
/*

Data Cleaning with SQL Project


*/


-------------------------------------------------------------------------------------------------------------------------------------------------------



--TASK 1


--Standardize Date Format and Add New Standardized date Field

ALTER TABLE NashvilleHousing 
ADD SaleDateStandardized Date;

UPDATE NashvilleHousing
SET SaleDateStandardized = CONVERT(Date, SaleDate)

SELECT SaleDateStandardized
FROM NashvilleHousing



-----------------------------------------------------------------------------------------------------------------------------------------------------------



--TASK 2 


--Populate Missing Property Address Data

--Context:
-----There are missing Property Addresses in the data (These are displayed as Null values). But the data provides Parcel IDs which are tied to a Property address.
------- i.e. A Parcel ID refers to a property sitauted at a distinct address. 

--Inference:
------If there is a property address for a Parcel ID in one record, then every other record with that same Parcel ID SHOULD have that same property address associated with that Parcel ID. 
------Therefore, for records where Property address is NULL, we can find the property address associated with their Parcel IDs (if present in other records) and then populate the data 
------where Property address is missing. 

--To Show instances/records where PropertyAddress is NULL.

SELECT * 
FROM NashvilleHousing
WHERE PropertyAddress is NULL
ORDER BY ParcelID


----Beacuse Unique IDs refer to records/rows in the data NOT the property, MULTIPLE records with the same ParcelID have different unique IDs.


SELECT * 
FROM NashvilleHousing as a
JOIN NashvilleHousing as b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


----In the resulting Joined table, table 'a' contains Parcel IDs with missing Property Addresses (NULL), and table 'b' contains same parcel IDs as table 'a' but with the property addresses present. 



----To use the property addresses on table 'b' to replace the NULL values in property addresses in table 'a' (where Parcel IDs are the same)

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing as a
JOIN NashvilleHousing as b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null


---To update the Data table with actual PropertyAddress for all NULL values in the PropertyAddress column.

UPDATE a             ---where 'a' is the alias used to refer to the NashvilleHousing Table
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM NashvilleHousing as a
JOIN NashvilleHousing as b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress is null





-----------------------------------------------------------------------------------------------------------------------------



--TASK 3


---Breaking out Property Address into Individual Columns (Address, City)


---Context:
-----The PropertyAddress column in the data table contains an Address and a City separated by a comma (,) and a space. e.g. 1234 NOWHERE DR, MOTOWN 

--To derive a string containing the Address only.

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) as SplitAddress
FROM NashvilleHousing

-- To derive a string containing the City only

SELECT 
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) as SplitCity
FROM NashvilleHousing

--To add new split Address and City Columns into the data table.

ALTER TABLE NashvilleHousing 
Add SplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET SplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) 

ALTER TABLE NashvilleHousing 
Add SplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET SplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) 





---------------------------------------------------------------------------------------------------------------------------------------------------



--TASK 4


---Breaking out Owner Address into Individual Columns (Address, City, State)

---Context:
-----The OwnerAddress column in the data table contains an Address, a City and a State. Each of them separated by a comma (,) and a space. e.g. 1234 NOWHERE DR, MOTOWN, MT (Where MT is State's initials) 


--Using the PARSENAME method instead of the SUBSTRING method

SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM NashvilleHousing

--To add new split Address, City and State Columns into the data table

ALTER TABLE NashvilleHousing 
Add OwnerSplitAddress NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) 

ALTER TABLE NashvilleHousing 
Add OwnerSplitCity NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing 
Add OwnerSplitState NVARCHAR(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)


SELECT *
FROM NashvilleHousing




------------------------------------------------------------------------------------------------------------------------------------------------



--TASK 5


--Change Y and N to Yes and No in "Sold as Vacant" field.

--Context:
--The "SoldAsVacant" field contains DISTINCT values of 'N', 'Yes', 'Y', 'No' where 'N' and 'Y' stands for No and Yes respectively.

--SELECT DISTINCT(SoldAsVacant)
--FROM NashvilleHousing

--SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
--FROM NashvilleHousing
--GROUP BY SoldAsVacant
--ORDER BY 2


SELECT SoldAsVacant, 
	CASE When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM NashvilleHousing
		

--Update the Table with new values for N and Y.

UPDATE NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
		 When SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END 




------------------------------------------------------------------------------------------------------------------------------



--TASK 6


--Remove Duplicates
--Created a CTE as it is not good practice to delete data from a database

WITH RowNumCTE AS (
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY 
					UniqueID
				) row_num

FROM NashvilleHousing
)


--To Delete Duplicate Rows

DELETE
FROM RowNumCTE
WHERE row_num > 1




--------------------------------------------------------------------------------------------------------------------------------------------



--TASK 7


--Delete Unused Colums


ALTER TABLE	NashvilleHousing
DROP COLUMN OwnerAddress,
			TaxDistrict,
			PropertyAddress,
			SaleDate

SELECT * FROM NashvilleHousing