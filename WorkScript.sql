use AroundTheWorldFor80Days;
go

exec DeleteOldTours;
go
----------------------------------------------------------------------------------
create or alter function ActualTours()
returns table
            as
return (select* from Tours where startDate > getutcdate());
go

select* from ActualTours() order by startDate;
go
----------------------------------------------------------------------------------
create or alter procedure ToursByDate
@beginStartDate date,
@endStartDate date
     as
begin
  if @beginStartDate < @endStartDate
  begin
  select* from Tours where startDate between @beginStartDate and @endStartDate;
  end
  else print 'Error';
end
go

exec ToursByDate '2020-01-01','2021-01-01';
go
----------------------------------------------------------------------------------
create or alter procedure ToursByCountry
@country varchar(50)
      as
begin
  if(@country != '')
  begin
  select Tours.* from Tours, TourCitiesSights, CountriesCities
  where CountriesCities.country = @country and
  TourCitiesSights.countryCityId = CountriesCities.countryCityId and
  TourCitiesSights.tourId = Tours.tourId;
  end
  else print 'Error';
end
go

exec ToursByCountry 'Italy';
go
----------------------------------------------------------------------------------
select country from CountriesCities where countryCityId = (select top 1 countryCityId from TourCitiesSights group by countryCityId order by count(countryCityId) desc); 
go
----------------------------------------------------------------------------------
create or alter function TheMostPopularTour()
 returns table
 as
return (select* from Tours where tourId = (select top 1 tourId from PayedTourists group by tourId order by count(tourId) desc));
go

select* from TheMostPopularTour();
go
----------------------------------------------------------------------------------delete old tours and insert into Archive 
create or alter trigger UpdateToursArchive on Tours
after delete as insert into ToursArchive (tourName, price, startDate, endDate, transportMove, maxTourists, workerId) select tourName, price, startDate, endDate, transportMove, maxTourists, workerId from deleted;   
go

create or alter procedure DeleteOldTours
 as
 begin
delete from PayedTourists where tourId in (select tourId from Tours where endDate < getutcdate());
delete from ToursWorkers where tourId in (select tourId from Tours where endDate < getutcdate());
delete from TourCitiesSights where tourId in (select tourId from Tours where endDate < getutcdate());
delete from Tours where endDate < getutcdate();
end
go

select* from Tours;
go

exec DeleteOldTours;
go

select* from ToursArchive;
go
----------------------------------------------------------------------------------
create or alter function TheMostPopularArchiveTour()
 returns table
 as 
return (select* from ToursArchive where maxTourists = (select top 1 maxTourists from ToursArchive group by maxTourists order by max(maxTourists) desc));
go

select* from TheMostPopularArchiveTour();
go
----------------------------------------------------------------------------------
create or alter function TheMostUnPopularTour()
 returns table
 as
return (select* from Tours where tourId = (select top 1 tourId from PayedTourists group by tourId order by count(tourId)));
go

select* from TheMostUnPopularTour();
go
----------------------------------------------------------------------------------
create or alter procedure ToursByTourist
@tourist varchar(100)
        as
begin
  if(@tourist != '')
  select* from Tours where tourId = (select tourId from PayedTourists where touristId = (select touristId from Tourists where fullName = @tourist));
  else print 'Error';
end
go

exec ToursByTourist 'Zayna Collins';
go
----------------------------------------------------------------------------------
create or alter procedure CheckForTouristInTour
@tourist varchar(100)
        as
begin
  if(@tourist != '')
  begin
     if((select endDate from Tours where tourId = (select tourId from PayedTourists where touristId = (select touristId from Tourists where fullName = @tourist))) > getutcdate() and (select startDate from Tours where tourId = (select tourId from PayedTourists where touristId = (select touristId from Tourists where fullName = @tourist))) < getutcdate())
     print @tourist + ' is in the tour';
     else print @tourist + ' is not in the tour';
  end
  else print 'Error';
end
go

exec CheckForTouristInTour 'Kaden Nelson';
go
----------------------------------------------------------------------------------
create or alter procedure FindTourist
@tourist varchar(100)
        as
begin
  if(@tourist != '')
  begin
     if((select endDate from Tours where tourId = (select tourId from PayedTourists where touristId = (select touristId from Tourists where fullName = @tourist))) > getutcdate() and (select startDate from Tours where tourId = (select tourId from PayedTourists where touristId = (select touristId from Tourists where fullName = @tourist))) < getutcdate())
	 begin
	 declare @tName varchar(100) = (select tourName from Tours where tourId = (select tourId from PayedTourists where touristId = (select touristId from Tourists where fullName = @tourist)));
     print @tourist + ' is in the tour: ' + @tName;
	 end
     else 
	 throw 55555, 'Tourist is not in the tour', 1;
	 print @tourist + ' is not in the tour';
  end
  else print 'Error';
end
go

begin try
exec FindTourist 'Raina Butler';
end try
begin catch
	print 'Error';
	print ERROR_NUMBER();
	print ERROR_MESSAGE();
	print ERROR_STATE();
	print ERROR_SEVERITY();
	print ERROR_LINE();
end catch
go
----------------------------------------------------------------------------------
create or alter function TheMostActiveTourist()
returns table
as
  return (select* from Tourists where touristId = (select top 1 touristId from PayedTourists group by touristId order by count(touristId) desc));
go

select * from TheMostActiveTourist();
go
----------------------------------------------------------------------------------
create or alter procedure ToursByTransportMove
@tMove varchar(45)
          as
select * from Tours where transportMove = @tMove;
go

exec ToursByTransportMove 'Plane';
go
----------------------------------------------------------------------------------
create or alter trigger CheckForRepeatTourists on Tourists
for insert as
begin
declare @tName varchar(100) = (select fullName from inserted);
declare @counter int = 1;
while @counter <= ((select count(*) from Tourists) - 1)
if (@tName != (select fullName from Tourists where touristId = @counter))
   set @counter = @counter + 1;
else
   throw 55556, 'This tourist is already existed', 1;
   rollback transaction
end
go

begin try
insert into Tourists values ('Kaden Nelson','325435346','nelson4@gmail.com','1985-05-17');
end try
begin catch
	print 'Error';
	print ERROR_NUMBER();
	print ERROR_MESSAGE();
	print ERROR_STATE();
	print ERROR_SEVERITY();
	print ERROR_LINE();
end catch
go

select* from Tourists;
go
----------------------------------------------------------------------------------
create or alter function TheMostPopularHotel()
returns table 
    as
  return (select* from Hotels where hotelId = (select top 1 hotelId from TouristsHotels group by hotelId order by count(hotelId) desc));
go

select* from TheMostPopularHotel();
go
----------------------------------------------------------------------------------
create or alter trigger CheckForMaxTourists on PayedTourists
for insert as
begin
declare @tourId int = (select tourId from inserted);
if (select maxTourists from Tours where tourId = @tourId) < (select count(touristId) from PayedTourists where tourId = @tourId)
	throw 55557, 'Maximum tourists', 1;
	rollback transaction
end
go
----------------------------------------------------------------------------------
