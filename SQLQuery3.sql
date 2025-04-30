
  --cleaning data in SQL quries
  select *
  from Nashville_housing

  --standardise date format
  select saledateconverted, convert(date,saledate)
  from Nashville_housing

  Update Nashville_housing
  set saledate = convert(date,saledate)

  Alter table nashville_housing
  add saledateconverted date;

  Update Nashville_housing 
  set saledateconverted = convert(date,Saledate)

  --populate property address data

  select*
  from nashville_housing
 -- where propertyaddress is null
 order by parcelID

  select a.parcelID, a.PropertyAddress, b.parcelID, b.PropertyAddress, ISNULL(a.propertyaddress, b.propertyaddress)
  from nashville_housing a
  join nashville_housing b
  on a.parcelID = b.parcelID
  and a.[UniqueID] <> b.[UniqueID]
  where a.propertyaddress is null

  Update a
  set propertyaddress = ISNULL(a.propertyaddress, b.propertyaddress)
   from nashville_housing a
  join nashville_housing b
  on a.parcelID = b.parcelID
  and a.[UniqueID] <> b.[UniqueID]
  where a.propertyaddress is null

  -- breaking out address into individual columns (addrees, city, state)

  Select propertyaddress
  from Nashville_housing

  SELECT 
  SUBSTRING (PROPERTYADDRESS, 1, CHARINDEX(',',PROPERTYADDRESS)-1) as address
  , SUBSTRING ( PROPERTYADDRESS, CHARINDEX(',', PROPERTYADDRESS)+1,LEN(PROPERTYADDRESS)) as address
  FROM NASHVILLE_HOUSING

  Alter table nashville_housing
  add Propertysplitaddress Nvarchar(255);

  Update Nashville_housing 
  set Propertysplitaddress = substring (propertyaddress, 1, charindex(',', propertyaddress)-1)

  Alter table nashville_housing
  add propertysplitcity Nvarchar (255);

  Update Nashville_housing 
  set Propertysplitcity = SUBSTRING ( PROPERTYADDRESS, CHARINDEX(',', PROPERTYADDRESS)+1,LEN(PROPERTYADDRESS)) 

  select *
  from nashville_housing

  select owneraddress
  from nashville_housing

  select
  parsename(replace(owneraddress,',','.'),3)
    ,parsename(replace(owneraddress,',','.'),2)
	  ,parsename(replace(owneraddress,',','.'),1)
  from Nashville_housing


   Alter table nashville_housing
  add ownersplitaddress Nvarchar (255);

  Update Nashville_housing 
  set ownersplitaddress = parsename(replace(owneraddress,',','.'),3)

   Alter table nashville_housing
  add ownersplitcity Nvarchar (255);

  Update Nashville_housing 
  set ownersplitcity = parsename(replace(owneraddress,',','.'),2)

   Alter table nashville_housing
  add ownersplitstate Nvarchar (255);

  Update Nashville_housing 
  set ownersplitstate = parsename(replace(owneraddress,',','.'),1)

  select*
  from Nashville_housing

  -- change Y and N to Yes and No in 'Sold as Vacant' field

  Select distinct( SoldasVacant),Count(SoldasVacant)
  from Nashville_housing
  Group by SoldasVacant
  order by 2

  Select soldasvacant 
, case when soldasvacant = 'Y' then 'Yes'
when soldasvacant = 'N' then 'No'
else soldasvacant
end
from Nashville_housing

Update Nashville_housing
SET SoldAsVacant = case when soldasvacant = 'Y' then 'Yes'
when soldasvacant = 'N' then 'No'
else soldasvacant
end

--Remove duplicates
WITH ROWNUMCTE as(
Select *,
ROW_NUMBER() over (
partition by parcelid,
propertyaddress,
saleprice,
saledate,
legalreference
ORDER BY  
uniqueid 
) row_num
from Nashville_housing
)
Select*
from ROWNUMCTE
WHERE row_num > 1
order by PropertyAddress


--Delete unused columns if approved

Select*
from Nashville_housing

Alter table nashville_housing
drop Column OwnerAddress, Taxdistrict, propertyaddress;

Alter table nashville_housing
drop column Saledate;
