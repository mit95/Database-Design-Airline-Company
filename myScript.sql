USE airlinecompanyschema;

SELECT * FROM customer;
SELECT * FROM address;
SELECT * FROM contactdetailscust;
SELECT * FROM airlineemployee;
SELECT * FROM contactdetailsemp;
SELECT * FROM manufacturerdetails;
SELECT * FROM airplane;
SELECT * FROM route;
SELECT * FROM flightstatus;
SELECT * FROM charges;
SELECT * FROM discounts;
SELECT * FROM bookinginformation;
SELECT * FROM flightschedule;
SELECT * FROM seats;
commit;
DELIMITER $$
CREATE TRIGGER Seat_Insert
	AFTER INSERT
    ON airlinecompanyschema.seats
    FOR EACH ROW
BEGIN
    SET @newseatnum = NEW.flightSchedule_idflightSchedule;
    IF  NEW.seatType = 'E' THEN
		UPDATE airlinecompanyschema.flightschedule SET availableEcoSeats = availableEcoSeats - 1
		WHERE flightSchedule.idflightSchedule = @newseatnum;
    ELSE 
		UPDATE airlinecompanyschema.flightschedule SET availBusiSeats = availBusiSeats - 1
		WHERE flightSchedule.idflightSchedule = @newseatnum;
    END IF;
END;

DELIMITER $$
CREATE TRIGGER Seat_Update
	AFTER UPDATE
    ON airlinecompanyschema.seats
    FOR EACH ROW
BEGIN
	SET @newseatnum = NEW.flightSchedule_idflightSchedule;
    IF NEW.seatType = 'E' THEN
        UPDATE airlinecompanyschema.flightschedule 
        SET    availableEcoSeats = availableEcoSeats - 1,
               availBusiSeats = availBusiSeats +1
		WHERE flightSchedule.idflightSchedule = @newseatnum;
	ELSE
        UPDATE airlinecompanyschema.flightschedule 
        SET    availableEcoSeats = availableEcoSeats + 1, 
			   availBusiSeats = availBusiSeats - 1
		WHERE flightSchedule.idflightSchedule = @newseatnum;
    END IF;
END;
	
DROP TRIGGER Seat_Update;

INSERT INTO seats
VALUES (2,'A40','E',1,1,1,1,1,1);

INSERT INTO seats
VALUES (3,'B10','B',2,2,2,3,1,2);

INSERT INTO seats
VALUES (4,'B10','B',2,2,2,3,1,2);

UPDATE seats
SET seatType = "B"
WHERE idseats = 1;

DELIMITER $
CREATE FUNCTION business_class_cost(flightid int,multiplier double)
RETURNS DOUBLE 
DETERMINISTIC
BEGIN
    DECLARE businessclassprize double;
    SELECT (fareEco*multiplier) INTO businessclassprize FROM flightschedule
    WHERE idflightSchedule = flightid;
    RETURN businessclassprize;
END;
$


set @id=1;
SELECT business_class_cost(1,2) AS Business_Seat_Cost FROM flightschedule where idflightSchedule= @id;

DELIMITER $
CREATE FUNCTION flights_on_schedule()
RETURNS INT 
DETERMINISTIC
BEGIN
    DECLARE scheduledflights int;
    SELECT COUNT(idflightSchedule) INTO scheduledflights FROM flightschedule
    WHERE BookingInformation_Status_idStatus = 1;
    RETURN scheduledflights;
END;
$

SELECT flights_on_schedule() AS TOTAL 
FROM flightschedule WHERE idflightSchedule = 1;

CREATE VIEW CustomerBill AS
SELECT customer.firstName, flightschedule.idflightSchedule, route.departureAirport, route.arrivalAirport, flightschedule.fareEco, discounts.amount AS discountedPercent, charges.amount AS chargedAmount, (flightschedule.fareEco + charges.amount - ((discounts.amount/100)*flightschedule.fareEco)) AS TotalBill
FROM bookinginformation AS B
JOIN flightschedule ON idBookingInformation = flightschedule.BookingInformation_idBookingInformation
JOIN charges ON B.Charges_idCharges = charges.idCharges
JOIN discounts ON B.Discounts_iddissounts = discounts.iddissounts
JOIN customer ON customer.idCustomer = B.Customer_idCustomer
JOIN route ON flightschedule.Route_idRoute = route.idRoute;

SELECT * FROM CustomerBill;

DELIMITER $
CREATE PROCEDURE SearchFlight(IN routeNumber INT)
BEGIN
    SELECT f.idflightSchedule, r.departureAirport, r.arrivalAirport, f.departureDate, f.departureTime, f.arrivalDate, f.arrivalTime, f.fareEco
    FROM flightschedule AS f
    INNER JOIN route AS r ON f.Route_idRoute = r.idRoute
    WHERE idRoute = routeNumber
    ORDER BY fareEco;
END;
$
DROP procedure SearchFlight;
CALL SearchFlight(1);